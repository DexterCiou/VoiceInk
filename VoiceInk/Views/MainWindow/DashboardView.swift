// DashboardView.swift
// VoiceInk — 儀表板頁面

import SwiftUI

/// 儀表板主頁面，顯示使用統計與圖表
struct DashboardView: View {
    // MARK: - 環境

    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var textProcessor: TextProcessor

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 標題與 Logo
                HStack(spacing: 12) {
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("VoiceInk 聲墨")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("語音輸入使用概況")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()

                    // 錄音按鈕
                    recordButton
                }

                // 統計卡片
                HStack(spacing: 16) {
                    StatsCardView(
                        title: "今日轉錄",
                        value: "\(statsManager.todayCount)",
                        unit: "次",
                        icon: "mic.fill",
                        color: .blue
                    )
                    StatsCardView(
                        title: "今日時長",
                        value: formatDuration(statsManager.todayDuration),
                        unit: "",
                        icon: "clock.fill",
                        color: .orange
                    )
                    StatsCardView(
                        title: "今日字數",
                        value: "\(statsManager.todayCharacters)",
                        unit: "字",
                        icon: "character.cursor.ibeam",
                        color: .green
                    )
                    StatsCardView(
                        title: "累計時長",
                        value: formatTotalDuration(statsManager.totalDuration),
                        unit: "",
                        icon: "timer.fill",
                        color: .purple
                    )
                }

                // 週統計圖表
                WeeklyChartView()

                // 最近一次轉錄結果
                if !textProcessor.lastTranscription.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("最近轉錄")
                            .font(.headline)
                        Text(textProcessor.lastTranscription)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(24)
        }
        .onAppear {
            statsManager.refreshStats()
        }
    }

    // MARK: - 元件

    /// 手動錄音按鈕
    private var recordButton: some View {
        Button {
            Task {
                await textProcessor.toggleRecording()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: textProcessor.state == .recording ? "stop.fill" : "mic.fill")
                Text(textProcessor.state == .recording ? "停止" : "開始錄音")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .tint(textProcessor.state == .recording ? .red : .accentColor)
        .disabled(textProcessor.state == .transcribing || textProcessor.state == .processing)
    }

    /// 格式化時長（今日）
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if minutes > 0 {
            return "\(minutes)m \(secs)s"
        }
        return "\(secs)s"
    }

    /// 格式化累計時長（支援小時/分鐘/秒）
    private func formatTotalDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(secs)s"
        }
        return "\(secs)s"
    }
}
