// KeychainHelper.swift
// VoiceInk — Keychain 存取工具，封裝 KeychainAccess 套件

import Foundation
import KeychainAccess

/// Keychain 存取工具，用於安全儲存 API Key
enum KeychainHelper {
    // MARK: - 常數

    private static let keychain = Keychain(service: "com.voiceink.VoiceInk")

    /// Keychain 中各 API Key 的鍵名
    enum Key: String {
        case groqAPIKey = "groq_api_key"
        case claudeAPIKey = "claude_api_key"
        case openAIAPIKey = "openai_api_key"
    }

    // MARK: - 公開方法

    /// 儲存 API Key 到 Keychain
    /// - Parameters:
    ///   - value: API Key 字串
    ///   - key: 鍵名
    static func save(_ value: String, for key: Key) throws {
        try keychain.set(value, key: key.rawValue)
        AppLogger.info("已儲存 \(key.rawValue) 到 Keychain")
    }

    /// 從 Keychain 讀取 API Key
    /// - Parameter key: 鍵名
    /// - Returns: API Key 字串，若不存在則回傳 nil
    static func load(for key: Key) throws -> String? {
        let value = try keychain.get(key.rawValue)
        return value
    }

    /// 從 Keychain 刪除 API Key
    /// - Parameter key: 鍵名
    static func delete(for key: Key) throws {
        try keychain.remove(key.rawValue)
        AppLogger.info("已從 Keychain 刪除 \(key.rawValue)")
    }

    /// 檢查 Keychain 中是否存在指定的 API Key
    /// - Parameter key: 鍵名
    /// - Returns: 是否存在
    static func exists(for key: Key) -> Bool {
        do {
            let value = try keychain.get(key.rawValue)
            return value != nil && !value!.isEmpty
        } catch {
            return false
        }
    }
}
