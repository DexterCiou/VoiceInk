// HotKeyManager.swift
// VoiceInk — 全域快捷鍵管理服務

import AppKit
import Foundation
import HotKey
import Carbon.HIToolbox

/// 全域快捷鍵管理器，使用 HotKey 套件註冊系統層級快捷鍵
@MainActor
class HotKeyManager: ObservableObject {
    // MARK: - 狀態

    /// 目前設定的快捷鍵
    @Published var currentShortcut: AppKeyboardShortcut

    // MARK: - 私有屬性

    private var hotKey: HotKey?
    private var callback: (() -> Void)?

    // MARK: - 初始化

    init() {
        self.currentShortcut = AppKeyboardShortcut.load()
    }

    // MARK: - 公開方法

    /// 註冊全域快捷鍵
    /// - Parameter handler: 快捷鍵觸發時的回呼
    func register(handler: @escaping () -> Void) {
        self.callback = handler
        setupHotKey()
        AppLogger.info("已註冊全域快捷鍵：\(currentShortcut.displayString)")
    }

    /// 取消註冊全域快捷鍵
    func unregister() {
        hotKey = nil
        callback = nil
        AppLogger.info("已取消全域快捷鍵註冊")
    }

    /// 更新快捷鍵設定
    /// - Parameter shortcut: 新的快捷鍵
    func updateShortcut(_ shortcut: AppKeyboardShortcut) {
        currentShortcut = shortcut
        shortcut.save()
        setupHotKey()
        AppLogger.info("已更新快捷鍵為：\(shortcut.displayString)")
    }

    // MARK: - 私有方法

    /// 設定 HotKey 實例
    private func setupHotKey() {
        // 先移除舊的
        hotKey = nil

        // 將 Carbon key code 轉換為 HotKey 的 Key 類型
        guard let key = Key(carbonKeyCode: currentShortcut.keyCode) else {
            AppLogger.error("無法轉換鍵碼 \(currentShortcut.keyCode) 為 HotKey Key")
            return
        }

        // 將 Carbon modifiers 轉換為 NSEvent.ModifierFlags
        var modifiers: NSEvent.ModifierFlags = []
        if currentShortcut.modifiers & UInt32(optionKey) != 0 {
            modifiers.insert(.option)
        }
        if currentShortcut.modifiers & UInt32(cmdKey) != 0 {
            modifiers.insert(.command)
        }
        if currentShortcut.modifiers & UInt32(controlKey) != 0 {
            modifiers.insert(.control)
        }
        if currentShortcut.modifiers & UInt32(shiftKey) != 0 {
            modifiers.insert(.shift)
        }

        // 建立 HotKey
        let newHotKey = HotKey(key: key, modifiers: modifiers)
        newHotKey.keyDownHandler = { [weak self] in
            self?.callback?()
        }

        self.hotKey = newHotKey
    }
}
