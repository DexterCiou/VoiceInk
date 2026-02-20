// StatsManager.swift
// VoiceInk — 使用統計管理器

import Foundation
import SwiftData
import SwiftUI

/// 統計管理器，負責紀錄與查詢使用統計
@MainActor
class StatsManager: ObservableObject {
    // MARK: - 狀態

    /// 今日轉錄次數
    @Published var todayCount: Int = 0
    /// 今日總時長
    @Published var todayDuration: TimeInterval = 0
    /// 今日總字元數
    @Published var todayCharacters: Int = 0
    /// 總轉錄次數
    @Published var totalCount: Int = 0
    /// 累計總時長
    @Published var totalDuration: TimeInterval = 0

    // MARK: - 私有屬性

    private var modelContext: ModelContext?

    // MARK: - 設定

    /// 設定 SwiftData ModelContext（由 View 層注入）
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        refreshStats()
    }

    // MARK: - 公開方法

    /// 紀錄一次轉錄結果
    func recordTranscription(
        originalText: String,
        processedText: String?,
        language: String,
        duration: TimeInterval,
        sttModel: String,
        llmModel: String?
    ) async {
        guard let context = modelContext else {
            AppLogger.warning("ModelContext 尚未設定，無法儲存統計")
            return
        }

        // 建立轉錄紀錄
        let record = TranscriptionRecord(
            originalText: originalText,
            processedText: processedText,
            language: language,
            duration: duration,
            sttModel: sttModel,
            llmModel: llmModel
        )
        context.insert(record)

        // 更新每日統計
        let today = Calendar.current.startOfDay(for: Date())
        let dailyStats = fetchOrCreateDailyStats(for: today, in: context)
        dailyStats.transcriptionCount += 1
        dailyStats.totalDuration += duration
        dailyStats.characterCount += (processedText ?? originalText).count

        // 儲存
        do {
            try context.save()
            AppLogger.info("已儲存轉錄紀錄與統計")
        } catch {
            AppLogger.error("儲存統計失敗", error: error)
        }

        // 更新發布的狀態
        refreshStats()
    }

    /// 取得最近 7 天的每日統計
    func weeklyStats() -> [DailyStats] {
        guard let context = modelContext else { return [] }

        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: Date()))!

        let descriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate { $0.date >= sevenDaysAgo },
            sortBy: [SortDescriptor(\.date)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// 取得所有轉錄紀錄（依時間倒序）
    func fetchRecords(limit: Int = 50) -> [TranscriptionRecord] {
        guard let context = modelContext else { return [] }

        var descriptor = FetchDescriptor<TranscriptionRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return (try? context.fetch(descriptor)) ?? []
    }

    /// 刪除指定的轉錄紀錄
    func deleteRecord(_ record: TranscriptionRecord) {
        guard let context = modelContext else { return }
        context.delete(record)
        try? context.save()
        refreshStats()
    }

    /// 重新整理統計數據
    func refreshStats() {
        guard let context = modelContext else { return }

        // 今日統計
        let today = Calendar.current.startOfDay(for: Date())
        let todayDescriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate { $0.date == today }
        )

        if let todayStats = try? context.fetch(todayDescriptor).first {
            todayCount = todayStats.transcriptionCount
            todayDuration = todayStats.totalDuration
            todayCharacters = todayStats.characterCount
        } else {
            todayCount = 0
            todayDuration = 0
            todayCharacters = 0
        }

        // 總計
        let allDescriptor = FetchDescriptor<TranscriptionRecord>()
        totalCount = (try? context.fetchCount(allDescriptor)) ?? 0

        // 累計總時長（加總所有 DailyStats）
        let allStatsDescriptor = FetchDescriptor<DailyStats>()
        if let allStats = try? context.fetch(allStatsDescriptor) {
            totalDuration = allStats.reduce(0) { $0 + $1.totalDuration }
        } else {
            totalDuration = 0
        }
    }

    // MARK: - 私有方法

    /// 取得或建立指定日期的統計紀錄
    private func fetchOrCreateDailyStats(for date: Date, in context: ModelContext) -> DailyStats {
        let descriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate { $0.date == date }
        )

        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        let newStats = DailyStats(date: date)
        context.insert(newStats)
        return newStats
    }
}
