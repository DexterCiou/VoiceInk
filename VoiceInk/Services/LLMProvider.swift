// LLMProvider.swift
// VoiceInk — LLM 提供者協議

import Foundation

/// LLM 提供者協議，定義統一的文字處理介面
protocol LLMProvider {
    /// 提供者名稱
    var name: String { get }
    /// 使用的模型名稱
    var modelName: String { get }

    /// 使用 LLM 潤飾文字
    /// - Parameters:
    ///   - text: 待潤飾的原始文字
    ///   - prompt: 系統提示詞
    /// - Returns: 潤飾後的文字
    func process(text: String, prompt: String) async throws -> String
}

// MARK: - LLM 共用錯誤類型

enum LLMError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "未設定 API Key，請在設定中輸入"
        case .invalidResponse:
            return "API 回應格式無效"
        case .apiError(let statusCode, let message):
            return "API 錯誤（\(statusCode)）：\(message)"
        case .emptyResponse:
            return "API 回傳了空的結果"
        }
    }
}
