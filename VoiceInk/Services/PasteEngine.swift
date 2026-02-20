// PasteEngine.swift
// VoiceInk — 自動貼上引擎

import AppKit
import Carbon.HIToolbox

/// 自動貼上引擎，將文字寫入剪貼簿，並在使用者目前的焦點位置貼上
class PasteEngine {
    // MARK: - 公開方法

    /// 將文字複製到剪貼簿，並嘗試在目前焦點位置自動貼上
    /// - Parameter text: 要貼上的文字
    func pasteText(_ text: String) {
        // 步驟 1：一律先寫入剪貼簿
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        AppLogger.debug("已寫入剪貼簿")

        // 步驟 2：檢查輔助使用權限
        guard AXIsProcessTrusted() else {
            AppLogger.warning("輔助使用權限未開啟，無法自動貼上，僅複製到剪貼簿")
            DispatchQueue.main.async {
                self.showCopiedToast(characterCount: text.count, hint: "請開啟輔助使用權限以啟用自動貼上")
            }
            return
        }

        // 步驟 3：檢查前台應用程式
        let frontmost = NSWorkspace.shared.frontmostApplication
        let myBundleID = Bundle.main.bundleIdentifier
        let isVoiceInk = frontmost?.bundleIdentifier == myBundleID

        AppLogger.debug("前台應用：\(frontmost?.localizedName ?? "無")，是否為 VoiceInk：\(isVoiceInk)")

        if isVoiceInk {
            // 焦點在 VoiceInk 自身 → 只顯示通知
            DispatchQueue.main.async {
                self.showCopiedToast(characterCount: text.count, hint: nil)
            }
            return
        }

        // 步驟 4：直接模擬 ⌘V 貼上
        // 使用背景執行緒加延遲，確保事件能送到前台 App
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.15) {
            self.simulateCommandV()
            AppLogger.info("已自動貼上到「\(frontmost?.localizedName ?? "未知")」（\(text.count) 字）")
        }
    }

    // MARK: - 浮動通知

    /// 顯示「已複製」浮動通知視窗
    private func showCopiedToast(characterCount: Int, hint: String?) {
        let message = hint ?? "已複製到剪貼簿（\(characterCount) 字），按 ⌘V 貼上"
        let toast = ToastWindow(message: message)
        toast.show()
    }

    // MARK: - 私有方法

    /// 模擬按下 ⌘V（Command + V）快捷鍵
    private func simulateCommandV() {
        let source = CGEventSource(stateID: .combinedSessionState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false) else {
            AppLogger.error("無法建立鍵盤事件")
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgSessionEventTap)
        keyUp.post(tap: .cgSessionEventTap)

        AppLogger.debug("已送出 ⌘V 事件")
    }
}

// MARK: - 浮動通知視窗

class ToastWindow: NSWindow {
    private var dismissTimer: Timer?

    init(message: String) {
        let padding: CGFloat = 16
        let font = NSFont.systemFont(ofSize: 14, weight: .medium)
        let textSize = (message as NSString).size(withAttributes: [.font: font])
        let windowWidth = textSize.width + padding * 2 + 32
        let windowHeight: CGFloat = 44

        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let originX = screenFrame.midX - windowWidth / 2
        let originY = screenFrame.minY + 80

        let frame = NSRect(x: originX, y: originY, width: windowWidth, height: windowHeight)

        super.init(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.hasShadow = true
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .transient]

        let contentView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
        contentView.material = .hudWindow
        contentView.state = .active
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = windowHeight / 2

        let imageView = NSImageView(frame: NSRect(x: padding, y: 10, width: 22, height: 22))
        if let checkmarkImage = NSImage(systemSymbolName: "doc.on.clipboard.fill", accessibilityDescription: nil) {
            imageView.image = checkmarkImage
            imageView.contentTintColor = .systemGreen
        }
        contentView.addSubview(imageView)

        let label = NSTextField(labelWithString: message)
        label.font = font
        label.textColor = .labelColor
        label.frame = NSRect(x: padding + 28, y: 12, width: textSize.width + 4, height: 20)
        contentView.addSubview(label)

        self.contentView = contentView
    }

    func show() {
        self.alphaValue = 0
        self.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            self.animator().alphaValue = 1
        }

        dismissTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            guard let self else { return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.5
                self.animator().alphaValue = 0
            }, completionHandler: {
                self.close()
            })
        }
    }
}
