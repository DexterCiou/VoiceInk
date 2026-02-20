// SettingsView.swift
// VoiceInk — 設定頁面

import SwiftUI
import LaunchAtLogin

/// 設定頁面，管理 API Key、快捷鍵、潤飾規則等設定
struct SettingsView: View {
    // MARK: - 環境

    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @EnvironmentObject var hotKeyManager: HotKeyManager

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 標題
                HStack {
                    Text("設定")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }

                // API Key 設定區
                apiKeysSection

                // 文字潤飾規則
                polishingRulesSection

                // 功能設定區
                featureSection

                // 快捷鍵設定
                shortcutSection

                // 一般設定
                generalSection
            }
            .padding(24)
        }
    }

    // MARK: - API Key 區塊

    private var apiKeysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("API Key 設定", icon: "key.fill")

            // Groq API Key（必填）
            apiKeyField(
                title: "Groq API Key（語音辨識 + 預設潤飾）",
                placeholder: "gsk_...",
                text: $settingsViewModel.groqAPIKey,
                isRequired: true
            )

            // Claude API Key
            apiKeyField(
                title: "Claude API Key（選用，切換潤飾引擎時需要）",
                placeholder: "sk-ant-...",
                text: $settingsViewModel.claudeAPIKey,
                isRequired: false
            )

            // OpenAI API Key
            apiKeyField(
                title: "OpenAI API Key（選用，切換潤飾引擎時需要）",
                placeholder: "sk-...",
                text: $settingsViewModel.openAIAPIKey,
                isRequired: false
            )

            // 儲存按鈕
            HStack {
                Spacer()
                Button("儲存 API Key") {
                    settingsViewModel.saveAPIKeys()
                }
                .buttonStyle(.borderedProminent)
            }

            if let message = settingsViewModel.saveMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(settingsViewModel.saveMessageIsError ? .red : .green)
            }
        }
        .settingsCard()
    }

    // MARK: - 文字潤飾規則區塊

    private var polishingRulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("額外潤飾規則", icon: "text.bubble.fill")

            Text("系統已內建基本潤飾規則（繁體中文、修正錯字、移除贅詞、去除重複語句等）。在此可追加額外的規則，例如特定的語氣、格式或輸出風格。")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $settingsViewModel.customPrompt)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 150)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack {
                Button("清除額外規則") {
                    settingsViewModel.resetPrompt()
                }

                Spacer()

                // 潤飾引擎選擇
                Picker("潤飾引擎", selection: $settingsViewModel.selectedLLMProvider) {
                    ForEach(AppSettings.LLMProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 300)
            }
        }
        .settingsCard()
    }

    // MARK: - 功能設定區塊

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("功能設定", icon: "slider.horizontal.3")

            // 自動貼上開關
            Toggle("啟用自動貼上", isOn: $settingsViewModel.enableAutoPaste)
            Text("轉錄完成後自動將文字貼上到目前的活躍應用程式")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            // STT 語言設定
            Picker("語音辨識語言", selection: $settingsViewModel.sttLanguage) {
                ForEach(AppSettings.STTLanguage.allCases) { lang in
                    Text(lang.displayName).tag(lang.rawValue)
                }
            }
            .pickerStyle(.menu)
        }
        .settingsCard()
    }

    // MARK: - 快捷鍵區塊

    private var shortcutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("快捷鍵", icon: "keyboard.fill")

            HStack {
                Text("觸發錄音快捷鍵")
                Spacer()
                ShortcutRecorderView(shortcut: $settingsViewModel.currentShortcut) { newShortcut in
                    hotKeyManager.updateShortcut(newShortcut)
                }
            }

            Text("按一次開始錄音，再按一次停止並處理")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .settingsCard()
    }

    // MARK: - 一般設定區塊

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("一般", icon: "gearshape.fill")

            LaunchAtLogin.Toggle("開機時自動啟動")

            Toggle("啟用提示音效", isOn: $settingsViewModel.enableSoundEffects)
        }
        .settingsCard()
    }

    // MARK: - 輔助元件

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
    }

    private func apiKeyField(title: String, placeholder: String, text: Binding<String>, isRequired: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                if isRequired {
                    Text("必填")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            SecureField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

// MARK: - 設定卡片樣式修飾器

extension View {
    func settingsCard() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
