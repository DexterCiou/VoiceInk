// TranscriptionRecord.swift
// VoiceInk — 轉錄紀錄資料模型

import Foundation
import SwiftData

/// 語音轉錄紀錄，儲存每次轉錄的完整資訊
@Model
final class TranscriptionRecord {
    /// 唯一識別碼
    var id: UUID
    /// 原始 STT 轉錄文字
    var originalText: String
    /// LLM 潤飾後的文字（若未啟用潤飾則為 nil）
    var processedText: String?
    /// 偵測到的語言代碼（如 "zh-TW"、"en"）
    var language: String
    /// 錄音時長（秒）
    var duration: TimeInterval
    /// 建立時間
    var createdAt: Date
    /// 使用的 STT 模型名稱
    var sttModel: String
    /// 使用的 LLM 模型名稱（若有使用）
    var llmModel: String?

    /// 取得最終顯示文字（優先使用潤飾後的文字）
    var displayText: String {
        processedText ?? originalText
    }

    init(
        originalText: String,
        processedText: String? = nil,
        language: String = "zh-TW",
        duration: TimeInterval = 0,
        sttModel: String = "whisper-large-v3",
        llmModel: String? = nil
    ) {
        self.id = UUID()
        self.originalText = originalText
        self.processedText = processedText
        self.language = language
        self.duration = duration
        self.createdAt = Date()
        self.sttModel = sttModel
        self.llmModel = llmModel
    }
}
