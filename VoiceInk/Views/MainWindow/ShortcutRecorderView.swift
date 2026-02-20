// ShortcutRecorderView.swift
// VoiceInk — 快捷鍵錄製元件

import SwiftUI
import AppKit
import Carbon.HIToolbox

/// 快捷鍵錄製元件，讓使用者按下想要的快捷鍵組合
/// 使用 NSEvent 監聽以支援特殊按鍵（如 Num Clear）
struct ShortcutRecorderView: View {
    // MARK: - 狀態

    @Binding var shortcut: AppKeyboardShortcut
    var onChanged: ((AppKeyboardShortcut) -> Void)?

    @State private var isRecording = false
    @State private var eventMonitor: Any?

    /// 允許單獨使用（不需修飾鍵）的特殊按鍵
    private static let standaloneAllowedKeys: Set<UInt32> = [
        UInt32(kVK_ANSI_KeypadClear)  // 數字鍵盤 Clear 鍵
    ]

    // MARK: - Body

    var body: some View {
        Button {
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        } label: {
            HStack(spacing: 6) {
                if isRecording {
                    Image(systemName: "record.circle")
                        .foregroundStyle(.red)
                    Text("請按下快捷鍵...")
                        .foregroundStyle(.secondary)
                } else {
                    Text(shortcut.displayString)
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isRecording ? Color.red.opacity(0.1) : Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .onDisappear {
            // 確保離開頁面時移除監聽
            stopRecording()
        }
    }

    // MARK: - 錄製控制

    /// 開始錄製快捷鍵，安裝 NSEvent 監聽器
    private func startRecording() {
        isRecording = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyEvent(event)
            return nil  // 消耗事件，不往下傳遞
        }
    }

    /// 停止錄製，移除 NSEvent 監聽器
    private func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    /// 處理按鍵事件
    private func handleKeyEvent(_ event: NSEvent) {
        let keyCode = UInt32(event.keyCode)

        // Escape 鍵取消錄製
        if keyCode == UInt32(kVK_Escape) {
            stopRecording()
            return
        }

        // 解析修飾鍵
        var modifiers: UInt32 = 0
        if event.modifierFlags.contains(.option) { modifiers |= UInt32(optionKey) }
        if event.modifierFlags.contains(.command) { modifiers |= UInt32(cmdKey) }
        if event.modifierFlags.contains(.control) { modifiers |= UInt32(controlKey) }
        if event.modifierFlags.contains(.shift) { modifiers |= UInt32(shiftKey) }

        // 一般按鍵需要至少一個修飾鍵，特殊按鍵可單獨使用
        let isStandaloneAllowed = Self.standaloneAllowedKeys.contains(keyCode)
        guard modifiers != 0 || isStandaloneAllowed else { return }

        let newShortcut = AppKeyboardShortcut(keyCode: keyCode, modifiers: modifiers)
        shortcut = newShortcut
        stopRecording()
        onChanged?(newShortcut)
    }
}
