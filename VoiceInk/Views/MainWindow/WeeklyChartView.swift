// WeeklyChartView.swift
// VoiceInk — 週統計圖表

import SwiftUI
import Charts

/// 週統計圖表，使用 Swift Charts 顯示最近 7 天的使用量
struct WeeklyChartView: View {
    // MARK: - 環境

    @EnvironmentObject var statsManager: StatsManager

    // MARK: - 狀態

    @State private var chartData: [ChartDataPoint] = []

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本週統計")
                .font(.headline)

            Chart(chartData) { point in
                BarMark(
                    x: .value("日期", point.label),
                    y: .value("次數", point.count)
                )
                .foregroundStyle(.blue.gradient)
                .cornerRadius(4)
            }
            .chartYAxisLabel("轉錄次數")
            .frame(height: 200)
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .onAppear {
            loadChartData()
        }
    }

    // MARK: - 資料載入

    private func loadChartData() {
        let weeklyStats = statsManager.weeklyStats()
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E" // 星期幾的簡寫

        // 建立最近 7 天的資料（含無資料的日期）
        var data: [ChartDataPoint] = []
        for dayOffset in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: calendar.startOfDay(for: Date()))!
            let label = dateFormatter.string(from: date)
            let count = weeklyStats.first { calendar.isDate($0.date, inSameDayAs: date) }?.transcriptionCount ?? 0
            data.append(ChartDataPoint(label: label, count: count))
        }

        chartData = data
    }
}

/// 圖表資料點
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
}
