// OnboardingView.swift
// VoiceInk — 首次啟動引導流程

import SwiftUI

/// 首次啟動引導流程，引導使用者完成必要設定
struct OnboardingView: View {
    // MARK: - 狀態

    @Binding var isPresented: Bool
    @State private var currentStep: OnboardingStep = .welcome
    @State private var groqAPIKey = ""
    @State private var hasMicPermission = false
    @State private var hasAccessibilityPermission = false
    @State private var errorMessage: String?

    // MARK: - 步驟定義

    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case permissions = 1
        case apiKey = 2
        case complete = 3
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 步驟指示器
            stepIndicator
                .padding(.top, 24)

            Spacer()

            // 步驟內容
            stepContent
                .frame(maxWidth: 500)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            Spacer()

            // 導航按鈕
            navigationButtons
                .padding(.bottom, 24)
        }
        .frame(width: 600, height: 450)
        .interactiveDismissDisabled()
    }

    // MARK: - 步驟指示器

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                Circle()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }

    // MARK: - 步驟內容

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .welcome:
            welcomeStep
        case .permissions:
            permissionsStep
        case .apiKey:
            apiKeyStep
        case .complete:
            completeStep
        }
    }

    // MARK: - 歡迎步驟

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.badge.waveform")
                .font(.system(size: 64))
                .foregroundStyle(.blue.gradient)

            Text("歡迎使用 VoiceInk")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("聲墨 — 將語音轉化為文字的魔法")
                .font(.title3)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                featureRow(icon: "mic.fill", text: "按下快捷鍵即可開始語音輸入")
                featureRow(icon: "waveform", text: "Groq Whisper 高速語音辨識")
                featureRow(icon: "sparkles", text: "AI 智慧文字潤飾（可選）")
                featureRow(icon: "doc.on.clipboard", text: "自動貼上到任何應用程式")
            }
            .padding(.top, 8)
        }
    }

    // MARK: - 權限步驟

    private var permissionsStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("授予必要權限")
                .font(.title)
                .fontWeight(.bold)

            Text("VoiceInk 需要以下權限才能正常運作")
                .foregroundStyle(.secondary)

            VStack(spacing: 16) {
                // 麥克風權限
                permissionRow(
                    icon: "mic.fill",
                    title: "麥克風",
                    description: "用於錄製語音",
                    isGranted: hasMicPermission
                ) {
                    Task {
                        hasMicPermission = await PermissionChecker.requestMicrophonePermission()
                    }
                }

                // 輔助使用權限
                permissionRow(
                    icon: "hand.raised.fill",
                    title: "輔助使用",
                    description: "用於全域快捷鍵與自動貼上",
                    isGranted: hasAccessibilityPermission
                ) {
                    PermissionChecker.requestAccessibilityPermission()
                    // 稍後重新檢查
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        hasAccessibilityPermission = PermissionChecker.checkAccessibilityPermission()
                    }
                }
            }
        }
        .onAppear {
            Task {
                hasMicPermission = await PermissionChecker.checkMicrophonePermission()
                hasAccessibilityPermission = PermissionChecker.checkAccessibilityPermission()
            }
        }
        // 定時輪詢輔助使用權限狀態（使用者可能在系統設定中手動開啟）
        .onReceive(Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()) { _ in
            hasAccessibilityPermission = PermissionChecker.checkAccessibilityPermission()
        }
    }

    // MARK: - API Key 步驟

    private var apiKeyStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("設定 Groq API Key")
                .font(.title)
                .fontWeight(.bold)

            Text("VoiceInk 使用 Groq 的 Whisper API 進行語音辨識，請輸入您的 API Key")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                Text("Groq API Key")
                    .font(.subheadline)
                    .fontWeight(.medium)
                SecureField("gsk_...", text: $groqAPIKey)
                    .textFieldStyle(.roundedBorder)

                Link("前往 Groq Console 取得 API Key", destination: URL(string: "https://console.groq.com/keys")!)
                    .font(.caption)
            }
            .frame(maxWidth: 400)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - 完成步驟

    private var completeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("設定完成！")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("現在您可以使用 ⌥S 開始語音輸入了")
                .font(.title3)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("使用方式：")
                    .fontWeight(.medium)
                Text("1. 按下 ⌥S 開始錄音")
                Text("2. 說話完畢後再按一次 ⌥S")
                Text("3. 文字將自動貼上到目前的應用程式")
            }
            .font(.body)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - 導航按鈕

    private var navigationButtons: some View {
        HStack {
            if currentStep != .welcome {
                Button("上一步") {
                    withAnimation {
                        currentStep = OnboardingStep(rawValue: currentStep.rawValue - 1) ?? .welcome
                    }
                }
            }

            Spacer()

            if currentStep == .complete {
                Button("開始使用") {
                    UserDefaults.standard.set(true, forKey: AppSettings.hasCompletedOnboarding)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("下一步") {
                    handleNextStep()
                }
                .buttonStyle(.borderedProminent)
                .disabled(currentStep == .apiKey && groqAPIKey.isEmpty)
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - 邏輯

    private func handleNextStep() {
        if currentStep == .apiKey {
            // 儲存 API Key
            do {
                try KeychainHelper.save(groqAPIKey, for: .groqAPIKey)
                errorMessage = nil
            } catch {
                errorMessage = "儲存失敗：\(error.localizedDescription)"
                return
            }
        }

        withAnimation {
            currentStep = OnboardingStep(rawValue: currentStep.rawValue + 1) ?? .complete
        }
    }

    // MARK: - 輔助元件

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(text)
                .font(.body)
        }
    }

    private func permissionRow(
        icon: String,
        title: String,
        description: String,
        isGranted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(isGranted ? .green : .orange)
                .frame(width: 24)

            VStack(alignment: .leading) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("授權") { action() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
