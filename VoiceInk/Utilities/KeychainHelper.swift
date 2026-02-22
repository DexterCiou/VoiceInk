// KeychainHelper.swift
// VoiceInk — API Key 安全儲存工具，使用加密檔案避免 Keychain ACL 密碼彈窗

import Foundation
import CryptoKit

/// Keychain 存取工具（實際使用 AES-GCM 加密檔案，介面保持不變）
/// 完全不使用 macOS Keychain，避免 ad-hoc 簽署時每次重裝都彈出密碼視窗
enum KeychainHelper {
    // MARK: - 常數

    /// 加密金鑰種子（結合 App 識別碼）
    private static let keySeed = "com.voiceink.VoiceInk.secure.storage.v1"

    /// API Key 的鍵名
    enum Key: String {
        case groqAPIKey = "groq_api_key"
        case claudeAPIKey = "claude_api_key"
        case openAIAPIKey = "openai_api_key"
    }

    // MARK: - 私有方法

    /// 取得儲存目錄（~/Library/Application Support/VoiceInk/）
    private static func storageDirectory() throws -> URL {
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = appSupport.appendingPathComponent("VoiceInk", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// 取得指定 Key 的檔案路徑
    private static func fileURL(for key: Key) throws -> URL {
        try storageDirectory().appendingPathComponent("\(key.rawValue).enc")
    }

    /// 產生 AES-GCM 對稱金鑰（從固定種子衍生）
    private static var encryptionKey: SymmetricKey {
        let hash = SHA256.hash(data: Data(keySeed.utf8))
        return SymmetricKey(data: hash)
    }

    // MARK: - 公開方法

    /// 儲存 API Key（AES-GCM 加密後寫入檔案）
    static func save(_ value: String, for key: Key) throws {
        let data = Data(value.utf8)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        guard let combined = sealedBox.combined else {
            throw CocoaError(.fileWriteUnknown)
        }
        let url = try fileURL(for: key)
        try combined.write(to: url)
        AppLogger.info("已儲存 \(key.rawValue)")
    }

    /// 從加密檔案讀取 API Key
    static func load(for key: Key) throws -> String? {
        let url = try fileURL(for: key)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        let combined = try Data(contentsOf: url)
        let sealedBox = try AES.GCM.SealedBox(combined: combined)
        let decrypted = try AES.GCM.open(sealedBox, using: encryptionKey)
        return String(data: decrypted, encoding: .utf8)
    }

    /// 刪除 API Key 檔案
    static func delete(for key: Key) throws {
        let url = try fileURL(for: key)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        AppLogger.info("已刪除 \(key.rawValue)")
    }

    /// 檢查指定的 API Key 是否存在
    static func exists(for key: Key) -> Bool {
        do {
            let value = try load(for: key)
            return value != nil && !value!.isEmpty
        } catch {
            return false
        }
    }
}
