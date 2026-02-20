// DailyStats.swift
// VoiceInk — 每日統計資料模型

import Foundation
import SwiftData

/// 每日使用統計，用於儀表板圖表顯示
@Model
final class DailyStats {
    /// 唯一識別碼
    var id: UUID
    /// 統計日期（只取日期部分，不含時間）
    var date: Date
    /// 當日轉錄次數
    var transcriptionCount: Int
    /// 當日總錄音時長（秒）
    var totalDuration: TimeInterval
    /// 當日總字元數
    var characterCount: Int

    init(
        date: Date = Calendar.current.startOfDay(for: Date()),
        transcriptionCount: Int = 0,
        totalDuration: TimeInterval = 0,
        characterCount: Int = 0
    ) {
        self.id = UUID()
        self.date = date
        self.transcriptionCount = transcriptionCount
        self.totalDuration = totalDuration
        self.characterCount = characterCount
    }
}
