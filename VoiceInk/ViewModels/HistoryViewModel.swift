// HistoryViewModel.swift
// VoiceInk — 歷史紀錄 ViewModel

import Foundation
import SwiftUI

/// 歷史紀錄 ViewModel
@MainActor
class HistoryViewModel: ObservableObject {
    // MARK: - 狀態

    /// 搜尋文字
    @Published var searchText = ""
    /// 排序方式
    @Published var sortOrder: SortOrder = .newest

    /// 排序選項
    enum SortOrder: String, CaseIterable, Identifiable {
        case newest = "最新優先"
        case oldest = "最舊優先"
        case longest = "最長優先"

        var id: String { rawValue }
    }

    // MARK: - 篩選與排序

    /// 對紀錄進行篩選與排序
    func filterAndSort(_ records: [TranscriptionRecord]) -> [TranscriptionRecord] {
        var filtered = records

        // 搜尋篩選
        if !searchText.isEmpty {
            filtered = filtered.filter { record in
                record.originalText.localizedCaseInsensitiveContains(searchText) ||
                (record.processedText?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // 排序
        switch sortOrder {
        case .newest:
            filtered.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            filtered.sort { $0.createdAt < $1.createdAt }
        case .longest:
            filtered.sort { $0.duration > $1.duration }
        }

        return filtered
    }

    // MARK: - 匯出

    /// 將紀錄匯出為文字
    func exportAsText(_ records: [TranscriptionRecord]) -> String {
        records.map { record in
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let date = dateFormatter.string(from: record.createdAt)
            return "[\(date)] \(record.displayText)"
        }.joined(separator: "\n\n")
    }
}
