// AboutView.swift
// VoiceInk — 關於頁面

import SwiftUI

/// 關於頁面，顯示應用程式資訊
struct AboutView: View {
    // MARK: - 常數

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    // MARK: - Body

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App 圖示與名稱
            VStack(spacing: 16) {
                Image(systemName: "mic.badge.waveform")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue.gradient)

                VStack(spacing: 4) {
                    Text("VoiceInk")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("聲墨")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                Text("版本 \(appVersion)（Build \(buildNumber)）")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // 說明
            VStack(spacing: 8) {
                Text("macOS 原生語音輸入應用程式")
                    .font(.headline)

                Text("使用 Groq Whisper 進行語音辨識，搭配 LLM 進行智慧文字潤飾，讓語音輸入更加自然流暢。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            // 技術資訊
            VStack(spacing: 6) {
                infoRow("系統需求", value: "macOS 14.0 (Sonoma) 或更新版本")
                infoRow("開發框架", value: "SwiftUI + SwiftData")
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .frame(maxWidth: 400)

            // 快捷鍵提示
            HStack(spacing: 4) {
                Text("預設快捷鍵：")
                    .foregroundStyle(.secondary)
                Text("⌥S")
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                Text("（可在設定中自訂）")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }

    // MARK: - 輔助元件

    private func infoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
}
