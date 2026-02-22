// VoiceInkApp.swift
// VoiceInk — macOS 語音輸入應用程式入口

import SwiftUI
import SwiftData

/// App 主入口，負責設定 Menu Bar、主視窗與 SwiftData 容器
@main
struct VoiceInkApp: App {
    // MARK: - AppDelegate

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - SwiftData 容器

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TranscriptionRecord.self,
            DailyStats.self,
            DictionaryWord.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("無法建立 SwiftData 容器：\(error)")
        }
    }()

    // MARK: - 狀態

    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    // MARK: - Body

    var body: some Scene {
        // 主視窗
        WindowGroup("VoiceInk — 聲墨") {
            ContentView(showOnboarding: $showOnboarding)
                .environmentObject(appDelegate.hotKeyManager)
                .environmentObject(appDelegate.textProcessor)
                .environmentObject(appDelegate.statsManager)
                .environmentObject(appDelegate.settingsViewModel)
                .task {
                    // 每次啟動檢查權限，若缺少任一權限則強制顯示引導流程
                    let hasMic = await PermissionChecker.checkMicrophonePermission()
                    let hasAccessibility = PermissionChecker.checkAccessibilityPermission()
                    if !hasMic || !hasAccessibility {
                        // 重設 onboarding 狀態，讓使用者重新授權
                        UserDefaults.standard.set(false, forKey: AppSettings.hasCompletedOnboarding)
                        showOnboarding = true
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 900, height: 600)
        .windowResizability(.contentSize)
    }
}
