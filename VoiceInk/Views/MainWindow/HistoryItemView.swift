// HistoryItemView.swift
// VoiceInk — 歷史紀錄單筆項目元件

import SwiftUI

/// 歷史紀錄列表中的單筆項目
struct HistoryItemView: View {
    let record: TranscriptionRecord

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 文字內容
            Text(record.displayText)
                .font(.body)
                .lineLimit(3)

            // 中繼資訊
            HStack(spacing: 12) {
                // 時間
                Label(formattedDate, systemImage: "clock")
                // 時長
                Label(formattedDuration, systemImage: "waveform")
                // 語言
                Label(record.language, systemImage: "globe")
                // 是否經過 LLM 潤飾
                if record.processedText != nil {
                    Label("已潤飾", systemImage: "sparkles")
                        .foregroundStyle(.blue)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - 格式化

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh-TW")
        return formatter.string(from: record.createdAt)
    }

    private var formattedDuration: String {
        String(format: "%.1fs", record.duration)
    }
}
