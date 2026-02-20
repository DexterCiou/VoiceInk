// ShortcutRecorderView.swift
// VoiceInk — 快捷鍵錄製元件

import SwiftUI
import Carbon.HIToolbox

/// 快捷鍵錄製元件，讓使用者按下想要的快捷鍵組合
struct ShortcutRecorderView: View {
    // MARK: - 狀態

    @Binding var shortcut: AppKeyboardShortcut
    var onChanged: ((AppKeyboardShortcut) -> Void)?

    @State private var isRecording = false
    @FocusState private var isFocused: Bool

    // MARK: - Body

    var body: some View {
        Button {
            isRecording.toggle()
            isFocused = isRecording
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
        .focusable()
        .focused($isFocused)
        .onKeyPress { keyPress in
            guard isRecording else { return .ignored }

            // 轉換 KeyPress 為 AppKeyboardShortcut
            let keyCode = keyCodeFromKeyEquivalent(keyPress.key)
            guard keyCode != UInt32.max else { return .ignored }

            var modifiers: UInt32 = 0
            if keyPress.modifiers.contains(.option) { modifiers |= UInt32(optionKey) }
            if keyPress.modifiers.contains(.command) { modifiers |= UInt32(cmdKey) }
            if keyPress.modifiers.contains(.control) { modifiers |= UInt32(controlKey) }
            if keyPress.modifiers.contains(.shift) { modifiers |= UInt32(shiftKey) }

            // 至少需要一個修飾鍵
            guard modifiers != 0 else { return .ignored }

            let newShortcut = AppKeyboardShortcut(keyCode: keyCode, modifiers: modifiers)
            shortcut = newShortcut
            isRecording = false
            isFocused = false
            onChanged?(newShortcut)

            return .handled
        }
    }

    // MARK: - 鍵碼轉換

    private func keyCodeFromKeyEquivalent(_ key: KeyEquivalent) -> UInt32 {
        let char = String(key.character).lowercased()
        let mapping: [String: Int] = [
            "a": kVK_ANSI_A, "b": kVK_ANSI_B, "c": kVK_ANSI_C, "d": kVK_ANSI_D,
            "e": kVK_ANSI_E, "f": kVK_ANSI_F, "g": kVK_ANSI_G, "h": kVK_ANSI_H,
            "i": kVK_ANSI_I, "j": kVK_ANSI_J, "k": kVK_ANSI_K, "l": kVK_ANSI_L,
            "m": kVK_ANSI_M, "n": kVK_ANSI_N, "o": kVK_ANSI_O, "p": kVK_ANSI_P,
            "q": kVK_ANSI_Q, "r": kVK_ANSI_R, "s": kVK_ANSI_S, "t": kVK_ANSI_T,
            "u": kVK_ANSI_U, "v": kVK_ANSI_V, "w": kVK_ANSI_W, "x": kVK_ANSI_X,
            "y": kVK_ANSI_Y, "z": kVK_ANSI_Z
        ]
        if let code = mapping[char] {
            return UInt32(code)
        }
        return UInt32.max
    }
}
