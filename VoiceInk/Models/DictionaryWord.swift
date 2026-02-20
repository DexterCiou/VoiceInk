// DictionaryWord.swift
// VoiceInk — 自訂字典詞彙資料模型

import Foundation
import SwiftData

/// 使用者自訂的字典詞彙，用於協助 LLM 正確辨識特殊用語
@Model
final class DictionaryWord {
    /// 詞彙內容
    var word: String
    /// 建立時間
    var createdAt: Date

    init(word: String) {
        self.word = word
        self.createdAt = Date()
    }
}
