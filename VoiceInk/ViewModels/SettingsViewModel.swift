// SettingsViewModel.swift
// VoiceInk — 設定 ViewModel

import Foundation
import SwiftUI

/// 設定 ViewModel，管理設定頁面的狀態與邏輯
@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - API Key 欄位（暫存，尚未儲存到 Keychain）

    @Published var groqAPIKey: String = ""
    @Published var claudeAPIKey: String = ""
    @Published var openAIAPIKey: String = ""

    // MARK: - 功能設定（綁定 UserDefaults）

    @AppStorage(AppSettings.selectedLLMProvider) var selectedLLMProvider = "groq"
    @AppStorage(AppSettings.enableAutoPaste) var enableAutoPaste = true
    @AppStorage(AppSettings.enableSoundEffects) var enableSoundEffects = true
    @AppStorage(AppSettings.sttLanguage) var sttLanguage = "zh"
    @AppStorage(AppSettings.customPrompt) var customPrompt = ""

    // MARK: - 快捷鍵

    @Published var currentShortcut: AppKeyboardShortcut

    // MARK: - UI 狀態

    @Published var saveMessage: String?
    @Published var saveMessageIsError = false

    // MARK: - 初始化

    init() {
        self.currentShortcut = AppKeyboardShortcut.load()
        loadAPIKeys()
    }

    // MARK: - API Key 操作

    /// 從 Keychain 載入已儲存的 API Key（以遮罩方式顯示）
    func loadAPIKeys() {
        // 載入時僅顯示是否已設定，不顯示完整 Key
        groqAPIKey = (try? KeychainHelper.load(for: .groqAPIKey)) ?? ""
        claudeAPIKey = (try? KeychainHelper.load(for: .claudeAPIKey)) ?? ""
        openAIAPIKey = (try? KeychainHelper.load(for: .openAIAPIKey)) ?? ""
    }

    /// 儲存 API Key 到 Keychain
    func saveAPIKeys() {
        do {
            if !groqAPIKey.isEmpty {
                try KeychainHelper.save(groqAPIKey, for: .groqAPIKey)
            }
            if !claudeAPIKey.isEmpty {
                try KeychainHelper.save(claudeAPIKey, for: .claudeAPIKey)
            }
            if !openAIAPIKey.isEmpty {
                try KeychainHelper.save(openAIAPIKey, for: .openAIAPIKey)
            }

            saveMessage = "API Key 已成功儲存"
            saveMessageIsError = false
            AppLogger.info("API Key 儲存成功")
        } catch {
            saveMessage = "儲存失敗：\(error.localizedDescription)"
            saveMessageIsError = true
            AppLogger.error("API Key 儲存失敗", error: error)
        }

        // 3 秒後清除訊息
        Task {
            try? await Task.sleep(for: .seconds(3))
            saveMessage = nil
        }
    }

    /// 檢查 Groq API Key 是否已設定
    var isGroqAPIKeySet: Bool {
        KeychainHelper.exists(for: .groqAPIKey)
    }

    /// 檢查是否至少設定了一組 LLM API Key
    var isLLMAPIKeySet: Bool {
        KeychainHelper.exists(for: .claudeAPIKey) || KeychainHelper.exists(for: .openAIAPIKey)
    }

    // MARK: - Prompt 操作

    /// 重設 Prompt 為預設值
    func resetPrompt() {
        customPrompt = ""
        AppLogger.info("已重設潤飾 Prompt 為預設值")
    }
}
