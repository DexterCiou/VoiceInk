// AppSettings.swift
// VoiceInk — 應用程式設定常數與 UserDefaults 鍵名

import Foundation

/// 應用程式設定相關的常數與預設值
enum AppSettings {
    // MARK: - UserDefaults 鍵名

    /// 是否已完成首次啟動引導
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    /// 目前選用的 LLM 提供者（"groq"、"claude" 或 "openai"）
    static let selectedLLMProvider = "selectedLLMProvider"
    /// 是否啟用自動貼上
    static let enableAutoPaste = "enableAutoPaste"
    /// 是否啟用提示音效
    static let enableSoundEffects = "enableSoundEffects"
    /// 是否開機時自動啟動
    static let launchAtLogin = "launchAtLogin"
    /// STT 語言設定（如 "zh"、"en"、"ja"）
    static let sttLanguage = "sttLanguage"
    /// 自訂潤飾規則
    static let customPrompt = "customPrompt"

    // MARK: - 預設值

    /// 註冊預設設定值
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            hasCompletedOnboarding: false,
            enableAutoPaste: true,
            enableSoundEffects: true,
            launchAtLogin: false,
            selectedLLMProvider: "groq",
            sttLanguage: "zh"
        ])
    }

    // MARK: - LLM 提供者

    /// LLM 提供者選項
    enum LLMProvider: String, CaseIterable, Identifiable {
        case groq = "groq"
        case claude = "claude"
        case openai = "openai"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .groq: return "Groq（預設）"
            case .claude: return "Claude (Anthropic)"
            case .openai: return "OpenAI GPT"
            }
        }
    }

    // MARK: - 支援語言

    /// STT 支援的語言選項
    enum STTLanguage: String, CaseIterable, Identifiable {
        case auto = "auto"
        case chinese = "zh"
        case english = "en"
        case japanese = "ja"
        case korean = "ko"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .auto: return "自動偵測"
            case .chinese: return "中文"
            case .english: return "English"
            case .japanese: return "日本語"
            case .korean: return "한국어"
            }
        }
    }
}
