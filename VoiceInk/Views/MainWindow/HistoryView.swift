// HistoryView.swift
// VoiceInk — 歷史紀錄頁面

import SwiftUI
import SwiftData

/// 歷史紀錄頁面，顯示所有轉錄紀錄
struct HistoryView: View {
    // MARK: - 環境

    @EnvironmentObject var statsManager: StatsManager

    // MARK: - 狀態

    @State private var records: [TranscriptionRecord] = []
    @State private var searchText = ""
    @State private var selectedRecord: TranscriptionRecord?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            HStack {
                Text("歷史紀錄")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Text("\(records.count) 筆紀錄")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 12)

            // 搜尋列
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜尋轉錄文字...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            // 紀錄列表
            if filteredRecords.isEmpty {
                emptyStateView
            } else {
                List(selection: $selectedRecord) {
                    ForEach(filteredRecords) { record in
                        HistoryItemView(record: record)
                            .tag(record)
                            .contextMenu {
                                Button("複製文字") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(record.displayText, forType: .string)
                                }
                                Divider()
                                Button("刪除", role: .destructive) {
                                    statsManager.deleteRecord(record)
                                    loadRecords()
                                }
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
        .onAppear {
            loadRecords()
        }
        // 監聽 statsManager 的變更，自動重新載入紀錄
        .onReceive(statsManager.objectWillChange) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                loadRecords()
            }
        }
    }

    // MARK: - 篩選

    private var filteredRecords: [TranscriptionRecord] {
        if searchText.isEmpty {
            return records
        }
        return records.filter { record in
            record.originalText.localizedCaseInsensitiveContains(searchText) ||
            (record.processedText?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    // MARK: - 空狀態

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text(searchText.isEmpty ? "尚無轉錄紀錄" : "找不到符合的紀錄")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "使用快捷鍵開始錄音，轉錄紀錄將會顯示在這裡" : "請嘗試其他搜尋字詞")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 載入資料

    private func loadRecords() {
        records = statsManager.fetchRecords(limit: 200)
    }
}
