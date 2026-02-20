// Logger.swift
// VoiceInk — 統一日誌工具

import Foundation
import os.log

/// 應用程式統一日誌管理器
enum AppLogger {
    // MARK: - 私有屬性

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.voiceink.VoiceInk",
        category: "VoiceInk"
    )

    // MARK: - 日誌等級方法

    /// 一般資訊日誌
    static func info(_ message: String) {
        logger.info("ℹ️ \(message, privacy: .public)")
    }

    /// 偵錯日誌
    static func debug(_ message: String) {
        logger.debug("🔍 \(message, privacy: .public)")
    }

    /// 警告日誌
    static func warning(_ message: String) {
        logger.warning("⚠️ \(message, privacy: .public)")
    }

    /// 錯誤日誌
    static func error(_ message: String) {
        logger.error("❌ \(message, privacy: .public)")
    }

    /// 錯誤日誌（附帶 Error 物件）
    static func error(_ message: String, error: Error) {
        logger.error("❌ \(message, privacy: .public): \(error.localizedDescription, privacy: .public)")
    }
}
