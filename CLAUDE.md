# VoiceInk（聲墨）— CLAUDE.md

## 專案概述

macOS 原生語音輸入應用程式。使用者按下全域快捷鍵（⌥S）開始錄音，說話完畢再按一次，App 會透過 Groq Whisper API 將語音轉為文字，再經由 LLM 潤飾後自動貼上到使用者目前焦點所在的應用程式。

- **GitHub**: https://github.com/DexterCiou/VoiceInk
- **語言**: Swift 5.9，註解全部使用繁體中文
- **最低系統需求**: macOS 14.0（Sonoma）
- **建置工具**: xcodegen（從 `project.yml` 生成 `.xcodeproj`）

## 核心流程

```
⌥S 開始錄音 → 說話 → ⌥S 停止
→ Groq Whisper STT（語音轉文字）
→ LLM 文字潤飾（預設 Groq Llama 3.3 70B）
→ 自動貼上到目前焦點的 App（或複製到剪貼簿 + 浮動通知）
```

## 專案架構

```
VoiceInk/
├── project.yml                    # xcodegen 設定（SPM 依賴、build settings）
├── CLAUDE.md
├── .gitignore
└── VoiceInk/
    ├── App/
    │   ├── VoiceInkApp.swift      # @main 入口，WindowGroup + SwiftData 容器
    │   └── AppDelegate.swift      # @MainActor，初始化核心服務、註冊快捷鍵
    ├── Info.plist                  # xcodegen 自動生成（自訂屬性在 project.yml）
    ├── VoiceInk.entitlements      # xcodegen 自動生成
    │
    ├── Models/
    │   ├── TranscriptionRecord.swift  # @Model SwiftData，轉錄紀錄
    │   ├── DailyStats.swift           # @Model SwiftData，每日統計
    │   ├── AppSettings.swift          # UserDefaults 鍵名常數、LLMProvider/STTLanguage enum
    │   └── KeyboardShortcut.swift     # AppKeyboardShortcut，Carbon keyCode + modifiers
    │
    ├── Services/
    │   ├── AudioRecorder.swift        # AVAudioEngine 錄音，輸出 .m4a
    │   ├── HotKeyManager.swift        # HotKey 套件封裝，全域快捷鍵
    │   ├── GroqWhisperService.swift   # Groq Whisper API（multipart/form-data 上傳）
    │   ├── LLMProvider.swift          # LLM 協議（protocol）
    │   ├── GroqLLMService.swift       # Groq Chat API（Llama 3.3 70B），與 Whisper 共用 API Key
    │   ├── ClaudeService.swift        # Anthropic Claude API
    │   ├── OpenAIService.swift        # OpenAI GPT API
    │   ├── TextProcessor.swift        # 核心協調器：錄音 → STT → LLM → 貼上
    │   ├── PasteEngine.swift          # 剪貼簿 + CGEvent 模擬 ⌘V + ToastWindow 浮動通知
    │   └── StatsManager.swift         # SwiftData CRUD，統計查詢
    │
    ├── Utilities/
    │   ├── KeychainHelper.swift       # KeychainAccess 套件封裝
    │   ├── Logger.swift               # os.log 統一日誌（AppLogger）
    │   ├── PermissionChecker.swift    # 麥克風 + 輔助使用權限檢查/請求
    │   └── SoundPlayer.swift          # NSSound 系統音效（Tink/Pop/Glass/Basso）
    │
    ├── ViewModels/
    │   ├── DashboardViewModel.swift   # 時間範圍篩選、格式化
    │   ├── HistoryViewModel.swift     # 搜尋、排序、匯出
    │   └── SettingsViewModel.swift    # API Key 載入/儲存、@AppStorage 綁定
    │
    ├── Views/
    │   ├── MainWindow/
    │   │   ├── ContentView.swift          # NavigationSplitView 根佈局
    │   │   ├── SidebarView.swift          # 側邊欄 + 底部錄音狀態指示
    │   │   ├── DashboardView.swift        # 統計卡片 + 圖表 + 錄音按鈕
    │   │   ├── StatsCardView.swift        # 統計卡片元件
    │   │   ├── WeeklyChartView.swift      # Swift Charts 週統計長條圖
    │   │   ├── HistoryView.swift          # 搜尋 + 紀錄列表（自動更新）
    │   │   ├── HistoryItemView.swift      # 單筆紀錄元件
    │   │   ├── SettingsView.swift         # API Key + 潤飾規則 + 功能設定
    │   │   ├── ShortcutRecorderView.swift # 快捷鍵錄製元件（onKeyPress）
    │   │   ├── OnboardingView.swift       # 首次啟動引導（權限 + API Key）
    │   │   └── AboutView.swift            # 關於頁面
    │   └── MenuBar/
    │       └── MenuBarView.swift          # 目前未使用（MenuBarExtra 有問題，見下方）
    │
    └── Resources/
        └── DefaultPrompt.txt          # 預設潤飾規則（繁體中文、修正錯別字等）
```

## 技術決策與原因

| 決策 | 原因 |
|------|------|
| **xcodegen** 生成 xcodeproj | CLI 環境建立專案比手動建 Xcode 專案更適合，新增檔案後 `xcodegen generate` 即可 |
| **SwiftData** 而非 Core Data | macOS 14+ 原生支援，API 更簡潔，與 SwiftUI 整合更好 |
| **Swift Charts** | macOS 14+ 原生，不需第三方圖表套件 |
| **Groq 作為預設 LLM** | 與 Whisper STT 共用同一組 API Key，使用者不需額外設定 |
| **LLM 潤飾永遠啟用** | 使用者認為 AI 潤飾是核心功能，不應有開關；改為可自訂「潤飾規則」 |
| **CGEvent + cgSessionEventTap** | 比 cghidEventTap 更可靠的鍵盤事件注入方式 |
| **combinedSessionState** | CGEventSource 使用 combinedSessionState 而非 hidSystemState，避免事件衝突 |
| **WindowGroup** 而非 MenuBarExtra | MenuBarExtra 在開發測試中圖示不顯示（原因未明），暫時改為一般視窗 |
| **Combine 轉發巢狀 ObservableObject** | SwiftUI 不會自動偵測巢狀 ObservableObject 的 @Published 變更，需手動轉發 |
| **繁體中文（台灣用語）** | 使用者明確要求，已寫入預設潤飾規則 |

## SPM 依賴

| 套件 | 用途 |
|------|------|
| [HotKey](https://github.com/soffes/HotKey) ^0.2.1 | 全域快捷鍵註冊 |
| [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) ^4.2.2 | API Key 安全儲存 |
| [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin-Modern) ^1.1.0 | 開機自動啟動 |

## 重要設計細節

### TextProcessor（核心協調器）
- `@MainActor class`，管理 `ProcessingState` 狀態機：idle → recording → transcribing → processing → completed → idle
- 使用 Combine `assign(to:)` 將 `audioRecorder.$currentDuration` 轉發為自身的 `$recordingDuration`
- 3 秒後自動從 `.completed` 回到 `.idle`

### PasteEngine（自動貼上）
- 非 @MainActor（CGEvent 不需要）
- 貼上前檢查 `AXIsProcessTrusted()` 輔助使用權限
- 前台 App 不是 VoiceInk → 模擬 ⌘V 自動貼上
- 前台 App 是 VoiceInk 或無目標 → 顯示 ToastWindow 浮動通知「已複製到剪貼簿」
- ToastWindow：NSWindow borderless，NSVisualEffectView hudWindow 材質，2 秒後淡出

### AppDelegate
- `@MainActor class`（解決 nonisolated context 初始化 @MainActor 物件的編譯錯誤）
- 擁有 `hotKeyManager`、`statsManager`、`settingsViewModel`、`textProcessor`
- 透過 `@NSApplicationDelegateAdaptor` 注入 SwiftUI App

### Keychain
- 開發期間每次 Xcode 重編會產生新 binary，macOS 會彈出 Keychain 存取確認（正式簽名後不會）
- 儲存 3 組 Key：`groq_api_key`（必填）、`claude_api_key`、`openai_api_key`

## 已知問題與解決方案

| 問題 | 原因 | 解決方案 |
|------|------|----------|
| MenuBarExtra 圖示不顯示 | 原因未明，可能與 Xcode 26.2 或 SwiftUI Scene 衝突有關 | **暫時改用 WindowGroup**，MenuBarView.swift 保留但未使用，待日後排查 |
| 每次 Xcode 重編後輔助使用權限被撤銷 | macOS 以 binary 簽名判斷身份，debug build 每次簽名不同 | 開發期間需手動重新開啟；正式 code sign 後不會發生 |
| 每次 Xcode 重編後 Keychain 存取需確認密碼 | 同上，binary 簽名變更 | 點「永遠允許」；正式簽名後不會發生 |
| Groq Whisper 輸出簡體中文 | Whisper 模型預設行為 | 在 LLM 潤飾規則中強制「一律使用繁體中文（台灣用語）」 |
| 巢狀 ObservableObject 不更新 UI | SwiftUI 只觀察直接的 @Published，不會深入巢狀物件 | 用 Combine `assign(to:)` 將 audioRecorder.currentDuration 轉發到 textProcessor.recordingDuration |
| `@MainActor` 初始化錯誤 | AppDelegate 的 stored property 在 nonisolated context 初始化 @MainActor 物件 | 在 AppDelegate class 上加 `@MainActor` |
| HotKeyManager 缺少 `import AppKit` | `NSEvent.ModifierFlags` 需要 AppKit | 加入 `import AppKit` |
| xcodegen 覆寫 Info.plist/entitlements | xcodegen 會重新生成這些檔案 | 自訂屬性改放在 project.yml 的 `info.properties` 和 `entitlements.properties` |

## 建置方式

```bash
# 安裝前置工具（已完成）
brew install xcodegen

# 生成 Xcode 專案（每次新增/刪除檔案後都要執行）
cd "/Users/dexterciou/Documents/claude code/VoiceInk"
xcodegen generate

# 開啟 Xcode 編譯
open VoiceInk.xcodeproj
# ⌘R 執行
```

**注意**：新增 Swift 檔案後必須執行 `xcodegen generate` 重新生成專案，否則 Xcode 找不到新檔案。

## 待辦事項

### 高優先
- [ ] **修復 MenuBarExtra**：排查為何 Menu Bar 圖示不顯示，恢復為 LSUIElement menu bar app
- [ ] **錯誤處理改善**：STT/LLM 失敗時在 UI 上顯示具體錯誤訊息，而非只在 console log
- [ ] **歷史紀錄修復**：確認每次轉錄都正確寫入 SwiftData（目前偶爾漏存）

### 中優先
- [ ] **自動貼上強化**：偵測前台 App 是否有可輸入的文字欄位（AXUIElement API）
- [ ] **串流顯示**：LLM 潤飾時即時顯示處理進度
- [ ] **多語言切換 UI**：在錄音前可快速切換 STT 語言
- [ ] **錄音視覺回饋**：在螢幕上顯示錄音中的浮動指示器

### 低優先
- [ ] **正式 Code Sign + Notarize**：解決 Keychain/輔助使用權限問題
- [ ] **自動更新機制**：Sparkle 框架
- [ ] **匯出歷史紀錄**：CSV/TXT 匯出功能
- [ ] **多組潤飾規則**：預設多種 Prompt 範本讓使用者切換
- [ ] **音訊品質設定**：讓使用者調整錄音品質/取樣率
