// SidebarView.swift
// VoiceInk — 側邊欄導航

import SwiftUI

/// 側邊欄導航視圖
struct SidebarView: View {
    // MARK: - 狀態

    @Binding var selectedTab: SidebarTab
    @EnvironmentObject var textProcessor: TextProcessor

    // MARK: - Body

    var body: some View {
        List(SidebarTab.allCases, selection: $selectedTab) { tab in
            Label(tab.rawValue, systemImage: tab.icon)
                .tag(tab)
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180)
        .safeAreaInset(edge: .bottom) {
            recordingStatusView
                .padding()
        }
    }

    // MARK: - 錄音狀態指示

    @ViewBuilder
    private var recordingStatusView: some View {
        switch textProcessor.state {
        case .idle:
            statusLabel("就緒", color: .secondary, icon: "mic.fill")
        case .recording:
            statusLabel(
                "錄音中 \(String(format: "%.1f", textProcessor.recordingDuration))s",
                color: .red,
                icon: "mic.fill"
            )
        case .transcribing:
            statusLabel("轉錄中...", color: .orange, icon: "waveform")
        case .processing:
            statusLabel("潤飾中...", color: .blue, icon: "sparkles")
        case .completed:
            statusLabel("完成", color: .green, icon: "checkmark.circle.fill")
        case .error(let message):
            statusLabel(message, color: .red, icon: "exclamationmark.triangle.fill")
        }
    }

    /// 狀態標籤元件
    private func statusLabel(_ text: String, color: Color, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundStyle(color)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
