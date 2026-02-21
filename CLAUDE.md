# VoiceInk（聲墨）— CLAUDE.md

## 專案概述

macOS 原生語音輸入應用程式。使用者按下全域快捷鍵（預設 ⌥S，支援自訂包含 Num Clear）開始錄音，說話完畢再按一次，App 會透過 Groq Whisper API 將語音轉為文字，再經由 LLM 潤飾（搭配自訂字典提升辨識準確度）後自動貼上到使用者目前焦點所在的應用程式。

- **GitHub**: https://github.com/DexterCiou/VoiceInk
- **語言**: Swift 5.9，註解全部使用繁體中文
- **最低系統需求**: macOS 14.0（Sonoma）
- **建置工具**: xcodegen（從 `project.yml` 生成 `.xcodeproj`）
- **目前版本**: 1.0.0
- **架構**: arm64（Apple Silicon）

## 核心流程

```
快捷鍵開始錄音 → 說話 → 快捷鍵停止
→ Groq Whisper STT（語音轉文字）
→ 檢查 STT 結果（不到 2 字則跳過，不送 LLM）
→ LLM 文字潤飾（預設 Groq Llama 3.3 70B，temperature 0.1）
  ├── 預設規則永遠生效（英文指令 + 繁中潤飾規則）
  ├── 自訂字典詞彙自動帶入（提升專有名詞辨識）
  └── 使用者額外規則追加（如有設定）
→ 自動貼上到目前焦點的 App（或複製到剪貼簿 + 浮動通知）
```

## 專案架構

```
VoiceInk/
├── project.yml                    # xcodegen 設定（SPM 依賴、build settings、AppIcon）
├── CLAUDE.md
├── .gitignore                     # 排除 *.xcodeproj/、dist/、build/ 等
└── VoiceInk/
    ├── App/
    │   ├── VoiceInkApp.swift      # @main 入口，WindowGroup + SwiftData 容器（含 DictionaryWord）
    │   └── AppDelegate.swift      # @MainActor，初始化核心服務、註冊快捷鍵、Menu Bar 狀態列圖示
    ├── Info.plist                  # xcodegen 自動生成（自訂屬性在 project.yml）
    ├── VoiceInk.entitlements      # xcodegen 自動生成
    │
    ├── Assets.xcassets/           # 圖片資源（Asset Catalog）
    │   ├── Contents.json
    │   ├── AppIcon.appiconset/    # App 圖示（16~1024px 全尺寸），使用 VoiceInk Logo
    │   ├── AppLogo.imageset/      # 首頁顯示用 Logo 圖片
    │   └── MenuBarIcon.imageset/  # Menu Bar 狀態列小圖示（16px + 32px @2x）
    │
    ├── Models/
    │   ├── TranscriptionRecord.swift  # @Model SwiftData，轉錄紀錄
    │   ├── DailyStats.swift           # @Model SwiftData，每日統計（含 totalDuration）
    │   ├── DictionaryWord.swift       # @Model SwiftData，自訂字典詞彙
    │   ├── AppSettings.swift          # UserDefaults 鍵名常數、LLMProvider/STTLanguage enum
    │   └── KeyboardShortcut.swift     # AppKeyboardShortcut，Carbon keyCode + modifiers，支援 Num Clear 顯示
    │
    ├── Services/
    │   ├── AudioRecorder.swift        # AVAudioEngine 錄音，輸出 .m4a
    │   ├── HotKeyManager.swift        # HotKey 套件封裝，全域快捷鍵（支援無修飾鍵的特殊鍵）
    │   ├── GroqWhisperService.swift   # Groq Whisper API（multipart/form-data 上傳）
    │   ├── LLMProvider.swift          # LLM 協議（protocol）
    │   ├── GroqLLMService.swift       # Groq Chat API（Llama 3.3 70B），temperature 0.1
    │   ├── ClaudeService.swift        # Anthropic Claude API
    │   ├── OpenAIService.swift        # OpenAI GPT API，temperature 0.1
    │   ├── TextProcessor.swift        # 核心協調器：錄音 → STT → 空內容檢查 → LLM → 貼上
    │   ├── PasteEngine.swift          # 剪貼簿 + CGEvent 模擬 ⌘V + ToastWindow 浮動通知
    │   └── StatsManager.swift         # SwiftData CRUD，統計查詢（含 totalDuration）
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
    │   │   ├── ContentView.swift          # NavigationSplitView 根佈局，SidebarTab 含字典
    │   │   ├── SidebarView.swift          # 側邊欄 + 底部錄音狀態指示
    │   │   ├── DashboardView.swift        # Logo + 統計卡片（累計時長）+ 圖表 + 錄音按鈕
    │   │   ├── StatsCardView.swift        # 統計卡片元件
    │   │   ├── WeeklyChartView.swift      # Swift Charts 週統計長條圖
    │   │   ├── HistoryView.swift          # 搜尋 + 紀錄列表（自動更新）
    │   │   ├── HistoryItemView.swift      # 單筆紀錄元件
    │   │   ├── DictionaryView.swift       # 自訂字典頁面（三欄格狀排列、搜尋、新增/刪除）
    │   │   ├── SettingsView.swift         # API Key + 額外潤飾規則 + 功能設定
    │   │   ├── ShortcutRecorderView.swift # 快捷鍵錄製元件（NSEvent 監聽，支援特殊鍵）
    │   │   ├── OnboardingView.swift       # 首次啟動引導（權限 + API Key）
    │   │   └── AboutView.swift            # 關於頁面
    │   └── MenuBar/
    │       └── MenuBarView.swift          # 目前未使用（MenuBarExtra 有問題，改用 NSStatusBar）
    │
    └── Resources/
        └── DefaultPrompt.txt          # 預設潤飾規則（英文指令框架 + 8 條潤飾規則，永遠生效）
```

## 技術決策與原因

| 決策 | 原因 |
|------|------|
| **xcodegen** 生成 xcodeproj | CLI 環境建立專案比手動建 Xcode 專案更適合，新增檔案後 `xcodegen generate` 即可 |
| **SwiftData** 而非 Core Data | macOS 14+ 原生支援，API 更簡潔，與 SwiftUI 整合更好 |
| **Swift Charts** | macOS 14+ 原生，不需第三方圖表套件 |
| **Groq 作為預設 LLM** | 與 Whisper STT 共用同一組 API Key，使用者不需額外設定 |
| **LLM 潤飾永遠啟用** | 使用者認為 AI 潤飾是核心功能，不應有開關；改為可自訂「額外規則」 |
| **預設規則永遠存在 + 額外規則追加** | 避免使用者不小心覆蓋基本規則（繁中、去贅詞等），額外規則只做補充 |
| **預設 prompt 用英文撰寫** | Llama 3.3 70B 對英文指令的遵從度遠高於中文，用英文寫角色定義和禁止事項能有效防止 LLM 自行添加對話性回覆（如「好的，以下是…」） |
| **temperature 0.1** | 文字轉換任務需要高確定性，低 temperature 讓 LLM 更嚴格遵守指令，減少偷懶直接放行簡體中文或自行發揮 |
| **STT 空內容檢查** | 空錄音或無意義錄音會讓 Whisper 回傳空字串，直接送 LLM 會導致 LLM 自己編造回覆（如「請輸入文字」），因此 STT 結果不到 2 字時直接跳過 LLM |
| **user message 只傳原始文字** | 曾嘗試在 user message 加指令性前綴「請將以下語音轉錄文字潤飾為繁體中文：」，反而讓 LLM 用對話模式回覆，改回只傳純文字效果更好 |
| **字典詞彙嵌入 system prompt** | 將自訂詞彙以【自訂字典】標籤附加到 prompt，LLM 能直接參照替換，不需額外 API 呼叫 |
| **CGEvent + cgSessionEventTap** | 比 cghidEventTap 更可靠的鍵盤事件注入方式 |
| **combinedSessionState** | CGEventSource 使用 combinedSessionState 而非 hidSystemState，避免事件衝突 |
| **NSStatusBar 而非 MenuBarExtra** | MenuBarExtra 圖示不顯示（SwiftUI Scene 問題），改用 NSStatusBar API 直接建立狀態列圖示 |
| **WindowGroup + NSStatusBar 並存** | 主視窗使用 WindowGroup，Menu Bar 圖示用 NSStatusBar 獨立實作，兩者互不干擾 |
| **NSEvent.addLocalMonitorForEvents** | 取代 SwiftUI `onKeyPress` 錄製快捷鍵，能捕捉所有按鍵包含 Num Clear 等特殊鍵 |
| **standaloneAllowedKeys 白名單** | Num Clear 等特殊鍵可單獨作為快捷鍵（不需修飾鍵），一般字母鍵仍需修飾鍵避免打字誤觸 |
| **Combine 轉發巢狀 ObservableObject** | SwiftUI 不會自動偵測巢狀 ObservableObject 的 @Published 變更，需手動轉發 |
| **繁體中文（台灣用語）** | 使用者明確要求，已寫入預設潤飾規則 |
| **Ad-hoc 簽署打包** | 無付費 Apple Developer 帳號，使用 `CODE_SIGN_IDENTITY="-"` ad-hoc 簽署 + .dmg 打包分發 |
| **applicationShouldTerminateAfterLastWindowClosed = false** | ToastWindow 可能是 App 最後一個可見視窗，關閉後 macOS 預設會終止 App，必須回傳 false 保持背景運行 |
| **isReleasedWhenClosed = false**（ToastWindow） | NSWindow 預設 `isReleasedWhenClosed = true`，`close()` 時會額外 release 一次；在 Swift ARC 下造成 over-release 閃退（動畫 completionHandler 仍持有 self 參考時 window 已被釋放） |
| **orderFront 而非 makeKeyAndOrderFront**（ToastWindow） | Toast 通知不需要成為 key window，borderless window 的 `canBecomeKey` 回傳 false 會導致 `makeKeyWindow` 警告 |

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
- STT 結果空內容檢查：`trimmedText.count >= 2` 才送 LLM，避免空錄音導致 LLM 自行編造回覆
- `loadPrompt()` 組裝邏輯：
  1. **預設規則**（DefaultPrompt.txt）— 永遠存在
  2. **【自訂字典】**（從 SwiftData 讀取 DictionaryWord）— 有詞彙時才附加
  3. **【額外規則】**（UserDefaults customPrompt）— 有填寫時才附加
- 需要 `ModelContext` 來讀取字典，透過 `setModelContext()` 由 ContentView 注入

### 預設潤飾規則（DefaultPrompt.txt）
永遠作為 system message 傳給 LLM。**使用英文撰寫指令框架**（角色定義、禁止事項），**潤飾規則用中英混合**。

結構分三段：
1. **角色定義**：「You are a text-to-text converter, not a chatbot」— 明確告訴 LLM 不是聊天機器人
2. **CRITICAL RULES（嚴格禁止）**：禁止加入「好的」、「以下是」等開頭語，禁止對話性回覆，禁止任何說明文字
3. **Polishing rules（潤飾規則，共 8 條）**：
   1. 一律繁體中文（台灣用語），禁止簡體
   2. 修正語音辨識錯誤與錯別字
   3. 適當加入標點符號
   4. 保持原始語意不變
   5. 保留英文專有名詞不翻譯
   6. 移除口語贅詞（嗯、啊、喔、欸、那個、就是說、對、然後）
   7. 移除重複語句（保留最完整的一句）
   8. 字典詞彙優先替換（發音相近、拼寫相似時替換為字典正確寫法）

**重要經驗**：
- prompt 用中文寫時，Llama 3.3 70B 容易忽略「直接輸出」的指令，改用英文後遵從度大幅提升
- user message 不要加指令性前綴（如「請將以下文字潤飾」），只傳原始文字，否則 LLM 會以對話模式回覆
- temperature 必須設 0.1（不是 0.3），越低 LLM 越嚴格遵守格式指令

### LLM 服務共通設定
- **GroqLLMService**：Llama 3.3 70B，temperature 0.1，user message 只傳原始文字
- **ClaudeService**：claude-sonnet-4-20250514，user message 只傳原始文字
- **OpenAIService**：gpt-4o-mini，temperature 0.1，user message 只傳原始文字
- 三個服務的 `process(text:prompt:)` 都是 system=prompt、user=text（純文字，無前綴）

### 字典功能（DictionaryWord + DictionaryView）
- `DictionaryWord`：SwiftData @Model，儲存 `word`（詞彙）和 `createdAt`（建立時間）
- `DictionaryView`：三欄格狀排列、支援搜尋、新增（Sheet 彈窗）、刪除、重複檢查
- 字典詞彙在 `TextProcessor.loadPrompt()` 中以「【自訂字典】詞彙1、詞彙2、...」格式附加到 prompt
- 側邊欄入口：`SidebarTab.dictionary`，圖示 `character.book.closed.fill`

### 快捷鍵系統
- `ShortcutRecorderView`：使用 `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` 捕捉按鍵
- `standaloneAllowedKeys`：白名單定義可單獨使用的特殊鍵（目前包含 `kVK_ANSI_KeypadClear`）
- 一般按鍵需至少一個修飾鍵（Option / Command / Control / Shift）
- 按 Escape 取消錄製
- `onDisappear` 時自動移除 NSEvent 監聽器

### Menu Bar 狀態列圖示
- 在 `AppDelegate.setupStatusBarIcon()` 中用 `NSStatusBar.system.statusItem()` 建立
- 圖示使用 Asset Catalog 中的 `MenuBarIcon`（18x18pt）
- 點擊圖示會 `NSApp.activate()` 並顯示主視窗
- **不是** MenuBarExtra（SwiftUI Scene），是獨立的 NSStatusBar 實作

### App Icon
- 使用 VoiceInk Logo 生成 16~1024px 全尺寸圖示
- 存放在 `Assets.xcassets/AppIcon.appiconset/`
- `project.yml` 中設定 `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`

### PasteEngine（自動貼上）
- 非 @MainActor（CGEvent 不需要）
- 貼上前檢查 `AXIsProcessTrusted()` 輔助使用權限
- 前台 App 不是 VoiceInk → 模擬 ⌘V 自動貼上
- 前台 App 是 VoiceInk 或無目標 → 顯示 ToastWindow 浮動通知「已複製到剪貼簿」
- ToastWindow：NSWindow borderless，NSVisualEffectView hudWindow 材質，2 秒後淡出
- **ToastWindow 關鍵設定**（防閃退）：
  - `isReleasedWhenClosed = false`：防止 `close()` 額外 release 與 ARC 衝突
  - `orderFront(nil)` 而非 `makeKeyAndOrderFront`：Toast 不需成為 key window
  - dismissTimer 使用 `[weak self]` 避免循環參考

### AppDelegate
- `@MainActor class`（解決 nonisolated context 初始化 @MainActor 物件的編譯錯誤）
- 擁有 `hotKeyManager`、`statsManager`、`settingsViewModel`、`textProcessor`、`statusItem`
- 透過 `@NSApplicationDelegateAdaptor` 注入 SwiftUI App
- `applicationDidFinishLaunching` 中初始化：快捷鍵註冊、Menu Bar 圖示、權限檢查
- `applicationShouldTerminateAfterLastWindowClosed` 回傳 `false`：防止 ToastWindow 關閉後 App 自動退出（此 App 依賴 Menu Bar 常駐背景運行）

### Keychain
- 開發期間每次 Xcode 重編會產生新 binary，macOS 會彈出 Keychain 存取確認（正式簽名後不會）
- 儲存 3 組 Key：`groq_api_key`（必填）、`claude_api_key`、`openai_api_key`

### 統計功能
- `StatsManager`：`totalDuration` 加總所有 DailyStats 的 `totalDuration`
- 儀表板顯示 4 張統計卡片：今日轉錄、今日時長、今日字數、**累計時長**
- 累計時長格式化：支援 h/m/s（如 `2h 15m`、`45s`）

## 已知問題與解決方案

| 問題 | 原因 | 解決方案 |
|------|------|----------|
| MenuBarExtra 圖示不顯示 | 原因未明，可能與 Xcode 26.2 或 SwiftUI Scene 衝突有關 | **改用 NSStatusBar API**，在 AppDelegate 中直接建立狀態列圖示 |
| 每次 Xcode 重編後輔助使用權限被撤銷 | macOS 以 binary 簽名判斷身份，debug build 每次簽名不同 | 開發期間需手動重新開啟（路徑：`~/Library/Developer/Xcode/DerivedData/VoiceInk-xxx/Build/Products/Debug/VoiceInk.app`）；正式 code sign 後不會發生 |
| 每次 Xcode 重編後 Keychain 存取需確認密碼 | 同上，binary 簽名變更 | 點「永遠允許」；正式簽名後不會發生 |
| Groq Whisper 輸出簡體中文 | Whisper 模型預設行為 | 在 LLM 預設潤飾規則強制「Convert ALL output to 繁體中文 — NEVER output 簡體中文」 |
| LLM 輸出對話性回覆（「好的，以下是…」） | 中文 system prompt 對 Llama 3.3 70B 的約束力不足，LLM 把自己當聊天機器人 | **改用英文寫 system prompt**（角色定義 + CRITICAL RULES 禁止事項），user message 只傳原始文字不加指令前綴 |
| LLM 仍輸出簡體中文 | temperature 0.3 太高，LLM 遵從指令的確定性不夠 | **降低 temperature 到 0.1**（Groq + OpenAI 都改了） |
| 空錄音導致 LLM 自行編造回覆 | 沒講話就停止 → Whisper 回傳空字串 → LLM 沒內容可潤飾就自己編 | **加入 STT 空內容檢查**：結果不到 2 字直接跳過，不送 LLM |
| user message 加指令前綴導致 LLM 對話式回覆 | 「請將以下語音轉錄文字潤飾為繁體中文：」讓 LLM 以為使用者在對話 | **撤回指令前綴**，user message 只傳純原始文字 |
| macOS Gatekeeper 判定為惡意軟體 | .dmg 下載後被加上 quarantine 屬性，無 notarization | 接收方執行 `xattr -cr /Applications/VoiceInk.app` 移除隔離標記 |
| 巢狀 ObservableObject 不更新 UI | SwiftUI 只觀察直接的 @Published，不會深入巢狀物件 | 用 Combine `assign(to:)` 將 audioRecorder.currentDuration 轉發到 textProcessor.recordingDuration |
| `@MainActor` 初始化錯誤 | AppDelegate 的 stored property 在 nonisolated context 初始化 @MainActor 物件 | 在 AppDelegate class 上加 `@MainActor` |
| HotKeyManager 缺少 `import AppKit` | `NSEvent.ModifierFlags` 需要 AppKit | 加入 `import AppKit` |
| xcodegen 覆寫 Info.plist/entitlements | xcodegen 會重新生成這些檔案 | 自訂屬性改放在 project.yml 的 `info.properties` 和 `entitlements.properties` |
| SwiftUI onKeyPress 無法捕捉特殊鍵 | `onKeyPress` 只能接收字母/數字等標準按鍵 | 改用 `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` 直接取得 raw keyCode |
| Fn 鍵無法作為全域快捷鍵 | Fn/🌐 是硬體層級修飾鍵，macOS 攔截用於系統功能（聽寫、emoji），Carbon API 不支援 | 不支援 Fn 單獨觸發，改用 Num Clear 等 standaloneAllowedKeys 白名單內的特殊鍵 |
| 無 Apple Developer 帳號無法 notarize | 年費 $99 USD | 使用 ad-hoc 簽署，接收方需 `xattr -cr` 或右鍵 → 打開繞過 Gatekeeper |
| **ToastWindow 關閉後 App 閃退**（已修復） | 兩個原因疊加：(1) ToastWindow 是最後一個可見視窗，`close()` 後 macOS 認為沒有視窗而終止 App；(2) NSWindow 預設 `isReleasedWhenClosed = true`，`close()` 額外 release 與 ARC 自動 release 衝突導致 over-release | **(1)** AppDelegate 加入 `applicationShouldTerminateAfterLastWindowClosed` 回傳 `false`；**(2)** ToastWindow init 設定 `isReleasedWhenClosed = false`；**(3)** `makeKeyAndOrderFront` 改為 `orderFront`（一併修復 `canBecomeKeyWindow` 警告） |
| **`-[NSWindow makeKeyWindow]` 警告**（已修復） | ToastWindow 使用 `.borderless` styleMask，`canBecomeKey` 回傳 false，但 `makeKeyAndOrderFront` 仍嘗試 makeKey | 改用 `orderFront(nil)`，Toast 通知不需要成為 key window |

## 建置方式

```bash
# 安裝前置工具（已完成）
brew install xcodegen

# xcodegen 路徑（如果 shell 找不到）
/opt/homebrew/bin/xcodegen generate

# 生成 Xcode 專案（每次新增/刪除檔案後都要執行）
cd "/Users/dexterciou/Documents/claude code/VoiceInk"
xcodegen generate

# 開啟 Xcode 編譯測試
open VoiceInk.xcodeproj
# ⌘R 執行
```

**注意**：新增 Swift 檔案後必須執行 `xcodegen generate` 重新生成專案，否則 Xcode 找不到新檔案。

## 打包分發（Ad-hoc，無需 Developer 帳號）

```bash
cd "/Users/dexterciou/Documents/claude code/VoiceInk"

# 1. 生成專案
/opt/homebrew/bin/xcodegen generate

# 2. Release 建置（ad-hoc 簽署）
xcodebuild -project VoiceInk.xcodeproj -scheme VoiceInk -configuration Release \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=YES CODE_SIGNING_ALLOWED=YES \
  ENABLE_HARDENED_RUNTIME=YES

# 3. 打包 .dmg
rm -rf dist/dmg-staging && mkdir -p dist/dmg-staging
cp -R "build/Build/Products/Release/VoiceInk.app" dist/dmg-staging/
ln -sf /Applications dist/dmg-staging/Applications
hdiutil create -volname "VoiceInk" -srcfolder dist/dmg-staging -ov -format UDZO "dist/VoiceInk-1.0.0.dmg"
```

產出 .dmg 位置：`dist/VoiceInk-1.0.0.dmg`（目前僅 arm64 Apple Silicon）

接收方安裝步驟：
1. 雙擊 .dmg → 拖 VoiceInk.app 到 Applications
2. 終端機執行 `xattr -cr /Applications/VoiceInk.app`（移除 Gatekeeper 隔離標記）
3. 雙擊開啟 VoiceInk
4. 授權麥克風（系統自動彈出）+ 輔助使用（手動到系統設定加入）
5. 到 VoiceInk 設定頁面輸入自己的 Groq API Key

## 側邊欄頁面結構

| Tab | 頁面 | 說明 |
|-----|------|------|
| `dashboard` | DashboardView | Logo + 統計卡片（今日轉錄/時長/字數、累計時長）+ 週圖表 + 錄音按鈕 |
| `history` | HistoryView | 轉錄歷史紀錄搜尋與瀏覽 |
| `dictionary` | DictionaryView | 自訂字典管理（新增/刪除/搜尋特殊詞彙） |
| `settings` | SettingsView | API Key、額外潤飾規則、潤飾引擎、自動貼上、語言、快捷鍵、一般設定 |
| `about` | AboutView | 關於頁面 |

## 待辦事項

### 高優先
- [ ] **錯誤處理改善**：STT/LLM 失敗時在 UI 上顯示具體錯誤訊息，而非只在 console log
- [ ] **歷史紀錄修復**：確認每次轉錄都正確寫入 SwiftData（目前偶爾漏存）
- [x] **ToastWindow 閃退與警告修復**：已修復 `close()` 後 App 閃退（`applicationShouldTerminateAfterLastWindowClosed` + `isReleasedWhenClosed`）及 `makeKeyWindow` 警告（改用 `orderFront`）

### 中優先
- [ ] **自動貼上強化**：偵測前台 App 是否有可輸入的文字欄位（AXUIElement API）
- [ ] **串流顯示**：LLM 潤飾時即時顯示處理進度
- [ ] **多語言切換 UI**：在錄音前可快速切換 STT 語言
- [ ] **錄音視覺回饋**：在螢幕上顯示錄音中的浮動指示器
- [ ] **字典功能強化**：支援批次匯入/匯出、詞彙分類標籤

### 低優先
- [ ] **正式 Code Sign + Notarize**：取得 Apple Developer 帳號，解決 Keychain/輔助使用權限/Gatekeeper 問題
- [ ] **Universal Binary**：同時支援 arm64 + x86_64（目前僅 arm64）
- [ ] **自動更新機制**：Sparkle 框架
- [ ] **匯出歷史紀錄**：CSV/TXT 匯出功能
- [ ] **音訊品質設定**：讓使用者調整錄音品質/取樣率
