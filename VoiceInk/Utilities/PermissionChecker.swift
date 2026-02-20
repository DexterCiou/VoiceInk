// PermissionChecker.swift
// VoiceInk — 系統權限檢查工具

import AVFoundation
import ApplicationServices
import AppKit

/// 系統權限檢查工具
enum PermissionChecker {
    // MARK: - 麥克風權限

    /// 檢查麥克風權限狀態
    /// - Returns: 是否已授權
    @MainActor
    static func checkMicrophonePermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    /// 請求麥克風權限
    @MainActor
    static func requestMicrophonePermission() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .audio)
    }

    // MARK: - 輔助使用權限

    /// 檢查輔助使用（Accessibility）權限
    /// - Returns: 是否已授權
    static func checkAccessibilityPermission() -> Bool {
        AXIsProcessTrusted()
    }

    /// 請求輔助使用權限（會跳出系統偏好設定）
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    // MARK: - 開啟系統設定

    /// 開啟系統偏好設定的隱私與安全性頁面
    static func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
            NSWorkspace.shared.open(url)
        }
    }

    /// 開啟系統偏好設定的輔助使用頁面
    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
