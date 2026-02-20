// MenuBarView.swift
// VoiceInk — Menu Bar 下拉選單

import SwiftUI

/// Menu Bar 下拉選單視圖（使用原生選單樣式）
struct MenuBarView: View {
    // MARK: - 環境

    @EnvironmentObject var hotKeyManager: HotKeyManager
    @EnvironmentObject var textProcessor: TextProcessor
    @Environment(\.openWindow) private var openWindow

    // MARK: - Body

    var body: some View {
        // 狀態顯示
        Button(statusText) {}
            .disabled(true)

        Divider()

        // 錄音控制
        Button(textProcessor.state == .recording ? "停止錄音" : "開始錄音（\(hotKeyManager.currentShortcut.displayString)）") {
            Task {
                await textProcessor.toggleRecording()
            }
        }
        .disabled(textProcessor.state == .transcribing || textProcessor.state == .processing)

        Divider()

        // 開啟主視窗
        Button("開啟主視窗") {
            openWindow(id: "main-window")
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut("o")

        // 複製最近轉錄
        if !textProcessor.lastTranscription.isEmpty {
            Button("複製最近轉錄") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(textProcessor.lastTranscription, forType: .string)
            }
            .keyboardShortcut("c")
        }

        Divider()

        // 結束應用程式
        Button("結束 VoiceInk") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    // MARK: - 狀態文字

    private var statusText: String {
        switch textProcessor.state {
        case .idle:
            return "就緒"
        case .recording:
            return "錄音中..."
        case .transcribing:
            return "語音轉錄中..."
        case .processing:
            return "文字潤飾中..."
        case .completed(let text):
            return "完成（\(text.count) 字）"
        case .error(let message):
            return "錯誤：\(message)"
        }
    }
}
