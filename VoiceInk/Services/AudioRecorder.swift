// AudioRecorder.swift
// VoiceInk — 音訊錄製服務

import AVFoundation
import Foundation

/// 音訊錄製服務，使用 AVAudioEngine 錄製麥克風音訊
@MainActor
class AudioRecorder: ObservableObject {
    // MARK: - 狀態

    /// 是否正在錄音
    @Published private(set) var isRecording = false
    /// 目前錄音時長（秒）
    @Published private(set) var currentDuration: TimeInterval = 0

    // MARK: - 私有屬性

    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    private var recordingStartTime: Date?
    private var durationTimer: Timer?

    /// 錄音檔暫存目錄
    private var tempDirectory: URL {
        FileManager.default.temporaryDirectory
    }

    // MARK: - 公開方法

    /// 開始錄音
    /// - Returns: 錄音檔路徑
    func startRecording() throws -> URL {
        guard !isRecording else {
            throw AudioRecorderError.alreadyRecording
        }

        // 建立暫存錄音檔路徑
        let fileName = "voiceink_\(UUID().uuidString).m4a"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        self.recordingURL = fileURL

        // 設定 AVAudioEngine
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // 確認取樣率有效
        guard recordingFormat.sampleRate > 0 else {
            throw AudioRecorderError.invalidAudioFormat
        }

        // 建立音訊檔案（使用 AAC 格式，較小的檔案大小適合上傳）
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: recordingFormat.sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let audioFile = try AVAudioFile(
            forWriting: fileURL,
            settings: settings
        )
        self.audioFile = audioFile

        // 安裝 Tap 擷取音訊資料
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak audioFile] buffer, _ in
            try? audioFile?.write(from: buffer)
        }

        // 啟動引擎
        engine.prepare()
        try engine.start()
        self.audioEngine = engine

        // 更新狀態
        isRecording = true
        recordingStartTime = Date()
        currentDuration = 0

        // 啟動計時器更新錄音時長
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let startTime = self.recordingStartTime else { return }
                self.currentDuration = Date().timeIntervalSince(startTime)
            }
        }

        SoundPlayer.play(.startRecording)
        AppLogger.info("開始錄音：\(fileURL.lastPathComponent)")

        return fileURL
    }

    /// 停止錄音
    /// - Returns: 錄音檔路徑與錄音時長
    func stopRecording() -> (url: URL, duration: TimeInterval)? {
        guard isRecording, let url = recordingURL else { return nil }

        // 停止引擎與 Tap
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioFile = nil

        // 計算時長
        let duration = currentDuration

        // 停止計時器
        durationTimer?.invalidate()
        durationTimer = nil

        // 更新狀態
        isRecording = false
        currentDuration = 0
        recordingStartTime = nil

        SoundPlayer.play(.stopRecording)
        AppLogger.info("停止錄音，時長：\(String(format: "%.1f", duration)) 秒")

        return (url: url, duration: duration)
    }

    /// 清理暫存錄音檔
    func cleanupTempFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
        AppLogger.debug("已清理暫存錄音檔：\(url.lastPathComponent)")
    }
}

// MARK: - 錯誤類型

enum AudioRecorderError: LocalizedError {
    case alreadyRecording
    case invalidAudioFormat
    case noPermission

    var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "正在錄音中，請先停止目前的錄音"
        case .invalidAudioFormat:
            return "無效的音訊格式，請檢查麥克風設定"
        case .noPermission:
            return "未取得麥克風權限，請在系統設定中允許 VoiceInk 使用麥克風"
        }
    }
}
