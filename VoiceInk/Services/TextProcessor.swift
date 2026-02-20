// TextProcessor.swift
// VoiceInk — 文字處理器，整合 STT + LLM 完整流程

import Combine
import Foundation
import SwiftData
import SwiftUI

/// 處理狀態
enum ProcessingState: Equatable {
    /// 閒置中
    case idle
    /// 錄音中
    case recording
    /// 轉錄中（STT）
    case transcribing
    /// 潤飾中（LLM）
    case processing
    /// 完成
    case completed(String)
    /// 錯誤
    case error(String)

    static func == (lhs: ProcessingState, rhs: ProcessingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.recording, .recording),
             (.transcribing, .transcribing), (.processing, .processing):
            return true
        case (.completed(let a), .completed(let b)):
            return a == b
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

/// 文字處理器，協調錄音 → STT → LLM → 自動貼上的完整流程
@MainActor
class TextProcessor: ObservableObject {
    // MARK: - 狀態

    /// 目前處理狀態
    @Published var state: ProcessingState = .idle
    /// 最後一次的轉錄文字
    @Published var lastTranscription: String = ""
    /// 目前錄音時長（從 audioRecorder 轉發，讓 SwiftUI 能偵測變更）
    @Published var recordingDuration: TimeInterval = 0

    // MARK: - 服務

    let audioRecorder = AudioRecorder()
    private let whisperService = GroqWhisperService()
    private let groqLLMService = GroqLLMService()
    private let claudeService = ClaudeService()
    private let openAIService = OpenAIService()
    private let pasteEngine = PasteEngine()
    private let statsManager: StatsManager

    // MARK: - 私有屬性

    private var currentRecordingURL: URL?
    private var cancellables = Set<AnyCancellable>()
    private var modelContext: ModelContext?

    /// 設定 SwiftData ModelContext（由 View 層注入）
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - 初始化

    init(statsManager: StatsManager) {
        self.statsManager = statsManager
        // 註冊預設設定值
        AppSettings.registerDefaults()

        // 轉發 audioRecorder 的時長變更，解決巢狀 ObservableObject 問題
        audioRecorder.$currentDuration
            .receive(on: RunLoop.main)
            .assign(to: &$recordingDuration)
    }

    // MARK: - 公開方法

    /// 切換錄音狀態（按一次開始錄音，再按一次停止並處理）
    func toggleRecording() async {
        switch state {
        case .recording:
            await stopAndProcess()
        case .idle, .completed, .error:
            startRecording()
        default:
            // 正在處理中，忽略
            AppLogger.warning("目前正在處理中，忽略快捷鍵")
        }
    }

    // MARK: - 私有方法

    /// 開始錄音
    private func startRecording() {
        do {
            let url = try audioRecorder.startRecording()
            currentRecordingURL = url
            state = .recording
            AppLogger.info("開始錄音流程")
        } catch {
            state = .error(error.localizedDescription)
            SoundPlayer.play(.error)
            AppLogger.error("開始錄音失敗", error: error)
        }
    }

    /// 停止錄音並執行完整處理流程
    private func stopAndProcess() async {
        // 停止錄音
        guard let result = audioRecorder.stopRecording() else {
            state = .error("停止錄音失敗")
            SoundPlayer.play(.error)
            return
        }

        let audioURL = result.url
        let duration = result.duration

        defer {
            // 清理暫存檔案
            audioRecorder.cleanupTempFile(at: audioURL)
        }

        // 檢查錄音時長（太短的錄音可能沒有內容）
        guard duration >= 0.5 else {
            state = .idle
            AppLogger.warning("錄音時間過短（\(String(format: "%.1f", duration)) 秒），已忽略")
            return
        }

        // 步驟 1：STT 轉錄
        state = .transcribing
        let sttLanguage = UserDefaults.standard.string(forKey: AppSettings.sttLanguage) ?? "zh"

        let transcriptionResult: TranscriptionResult
        do {
            transcriptionResult = try await whisperService.transcribe(
                audioURL: audioURL,
                language: sttLanguage == "auto" ? nil : sttLanguage
            )
        } catch {
            state = .error("語音轉錄失敗：\(error.localizedDescription)")
            SoundPlayer.play(.error)
            AppLogger.error("STT 轉錄失敗", error: error)
            return
        }

        var finalText = transcriptionResult.text
        var llmModel: String? = nil

        // 檢查 STT 結果是否有實質內容（過濾空錄音、無意義文字）
        let trimmedText = transcriptionResult.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText.count >= 2 else {
            state = .idle
            AppLogger.warning("STT 結果過短或為空（\(trimmedText.count) 字），已忽略")
            return
        }

        // 步驟 2：LLM 文字潤飾（永遠執行）
        state = .processing
        let prompt = loadPrompt()
        let provider = currentLLMProvider()

        do {
            finalText = try await provider.process(text: transcriptionResult.text, prompt: prompt)
            llmModel = provider.modelName
        } catch {
            // LLM 失敗時仍使用原始 STT 結果
            AppLogger.warning("LLM 潤飾失敗，使用原始轉錄文字：\(error.localizedDescription)")
        }

        // 步驟 3：自動貼上
        let enableAutoPaste = UserDefaults.standard.bool(forKey: AppSettings.enableAutoPaste)
        if enableAutoPaste {
            pasteEngine.pasteText(finalText)
        }

        // 步驟 4：更新統計與紀錄
        lastTranscription = finalText
        state = .completed(finalText)
        SoundPlayer.play(.transcriptionComplete)

        // 儲存統計（透過 StatsManager）
        await statsManager.recordTranscription(
            originalText: transcriptionResult.text,
            processedText: finalText,
            language: transcriptionResult.language,
            duration: duration,
            sttModel: transcriptionResult.model,
            llmModel: llmModel
        )

        AppLogger.info("處理完成：\(finalText.prefix(50))...")

        // 3 秒後重設狀態
        try? await Task.sleep(for: .seconds(3))
        if case .completed = state {
            state = .idle
        }
    }

    /// 載入潤飾 Prompt（預設規則永遠存在 + 字典 + 使用者額外規則）
    private func loadPrompt() -> String {
        // 預設規則（永遠存在）
        var prompt: String
        if let url = Bundle.main.url(forResource: "DefaultPrompt", withExtension: "txt"),
           let content = try? String(contentsOf: url, encoding: .utf8) {
            prompt = content
        } else {
            prompt = "請將以下語音轉錄文字潤飾為繁體中文（台灣用語），修正錯別字並調整語句通順度，直接輸出結果。"
        }

        // 附加字典詞彙
        let dictionaryWords = loadDictionaryWords()
        if !dictionaryWords.isEmpty {
            let wordList = dictionaryWords.joined(separator: "、")
            prompt += "\n\n【自訂字典】\(wordList)"
        }

        // 附加使用者額外規則
        if let customPrompt = UserDefaults.standard.string(forKey: AppSettings.customPrompt),
           !customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            prompt += "\n\n【額外規則】\(customPrompt)"
        }

        return prompt
    }

    /// 從 SwiftData 載入字典詞彙
    private func loadDictionaryWords() -> [String] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<DictionaryWord>()
        return (try? context.fetch(descriptor))?.map(\.word) ?? []
    }

    /// 取得目前選用的 LLM 提供者
    private func currentLLMProvider() -> LLMProvider {
        let providerString = UserDefaults.standard.string(forKey: AppSettings.selectedLLMProvider) ?? "groq"
        switch providerString {
        case "claude":
            return claudeService
        case "openai":
            return openAIService
        default:
            return groqLLMService
        }
    }
}
