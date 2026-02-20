// DashboardViewModel.swift
// VoiceInk — 儀表板 ViewModel

import Foundation
import SwiftUI

/// 儀表板 ViewModel（目前儀表板邏輯主要由 StatsManager 處理，
/// 此 ViewModel 提供額外的 UI 層邏輯）
@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - 狀態

    /// 選定的統計時間範圍
    @Published var selectedTimeRange: TimeRange = .week

    /// 時間範圍選項
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "本週"
        case month = "本月"
        case all = "全部"

        var id: String { rawValue }

        /// 取得起始日期
        var startDate: Date {
            let calendar = Calendar.current
            switch self {
            case .week:
                return calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date()))!
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: calendar.startOfDay(for: Date()))!
            case .all:
                return .distantPast
            }
        }
    }

    // MARK: - 格式化輔助

    /// 格式化時長顯示
    func formatDuration(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "\(Int(seconds))s"
        } else if seconds < 3600 {
            return "\(Int(seconds) / 60)m \(Int(seconds) % 60)s"
        } else {
            let hours = Int(seconds) / 3600
            let minutes = (Int(seconds) % 3600) / 60
            return "\(hours)h \(minutes)m"
        }
    }
}
