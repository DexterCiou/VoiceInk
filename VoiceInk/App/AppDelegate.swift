// AppDelegate.swift
// VoiceInk — 應用程式委派，負責初始化核心服務

import AppKit
import SwiftUI

/// 應用程式委派，管理核心服務的生命週期
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    // MARK: - 核心服務

    let hotKeyManager = HotKeyManager()
    let statsManager = StatsManager()
    let settingsViewModel = SettingsViewModel()
    private(set) lazy var textProcessor = TextProcessor(
        statsManager: statsManager
    )

    // MARK: - Menu Bar 狀態列圖示

    private var statusItem: NSStatusItem?

    // MARK: - 生命週期

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLogger.info("VoiceInk 啟動完成")

        // 註冊全域快捷鍵
        hotKeyManager.register { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                await self.textProcessor.toggleRecording()
            }
        }

        // 設定 Menu Bar 狀態列圖示
        setupStatusBarIcon()

        // 檢查權限狀態
        Task {
            let micPermission = await PermissionChecker.checkMicrophonePermission()
            let accessibilityPermission = PermissionChecker.checkAccessibilityPermission()
            AppLogger.info("麥克風權限：\(micPermission)，輔助使用權限：\(accessibilityPermission)")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager.unregister()
        AppLogger.info("VoiceInk 結束")
    }

    /// 設定 Menu Bar 狀態列圖示
    private func setupStatusBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            if let image = NSImage(named: "MenuBarIcon") {
                image.size = NSSize(width: 18, height: 18)
                button.image = image
            }
            button.action = #selector(statusBarIconClicked)
            button.target = self
        }
    }

    /// 點擊 Menu Bar 圖示時顯示主視窗
    @objc private func statusBarIconClicked() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.isVisible }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            // 如果沒有可見的視窗，嘗試開啟新視窗
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    /// 當使用者點擊 Dock 圖示（如果可見）時重新開啟主視窗
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            NSApp.activate(ignoringOtherApps: true)
        }
        return true
    }
}
