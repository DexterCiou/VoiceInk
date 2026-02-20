// ContentView.swift
// VoiceInk — 主視窗根佈局

import SwiftUI
import SwiftData

/// 主視窗根佈局，使用 NavigationSplitView 實作側邊欄導航
struct ContentView: View {
    // MARK: - 環境

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var statsManager: StatsManager
    @EnvironmentObject var textProcessor: TextProcessor

    // MARK: - 狀態

    @Binding var showOnboarding: Bool
    @State private var selectedTab: SidebarTab = .dashboard

    // MARK: - Body

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 800, minHeight: 550)
        .onAppear {
            statsManager.setModelContext(modelContext)
            textProcessor.setModelContext(modelContext)
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
    }

    // MARK: - 詳細頁面

    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView()
        case .history:
            HistoryView()
        case .dictionary:
            DictionaryView()
        case .settings:
            SettingsView()
        case .about:
            AboutView()
        }
    }
}

/// 側邊欄標籤頁定義
enum SidebarTab: String, CaseIterable, Identifiable {
    case dashboard = "儀表板"
    case history = "歷史紀錄"
    case dictionary = "字典"
    case settings = "設定"
    case about = "關於"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .history: return "clock.fill"
        case .dictionary: return "character.book.closed.fill"
        case .settings: return "gearshape.fill"
        case .about: return "info.circle.fill"
        }
    }
}
