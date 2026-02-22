// ClaudeService.swift
// VoiceInk — Anthropic Claude LLM 服務

import Foundation

/// Anthropic Claude API 服務
class ClaudeService: LLMProvider {
    // MARK: - LLMProvider

    let name = "Claude"
    let modelName = "claude-sonnet-4-20250514"

    // MARK: - 常數

    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let apiVersion = "2023-06-01"

    // MARK: - 公開方法

    func process(text: String, prompt: String) async throws -> String {
        // 從 Keychain 取得 API Key
        guard let apiKey = try KeychainHelper.load(for: .claudeAPIKey), !apiKey.isEmpty else {
            throw LLMError.missingAPIKey
        }

        // 建立請求
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        // 組裝請求 body
        let requestBody = ClaudeRequest(
            model: modelName,
            max_tokens: 4096,
            system: prompt,
            messages: [
                ClaudeMessage(role: "user", content: "<transcription>\(text)</transcription>")
            ]
        )

        request.httpBody = try JSONEncoder().encode(requestBody)

        // 發送請求
        let (data, response) = try await URLSession.shared.data(for: request)

        // 檢查 HTTP 狀態碼
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "未知錯誤"
            AppLogger.error("Claude API 錯誤（\(httpResponse.statusCode)）：\(errorBody)")
            throw LLMError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        // 解析回應
        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let resultText = claudeResponse.content.first?.text, !resultText.isEmpty else {
            throw LLMError.emptyResponse
        }

        AppLogger.info("Claude 潤飾完成，輸入 \(text.count) 字 → 輸出 \(resultText.count) 字")
        return resultText
    }
}

// MARK: - 請求/回應模型

private struct ClaudeRequest: Codable {
    let model: String
    let max_tokens: Int
    let system: String
    let messages: [ClaudeMessage]
}

private struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

private struct ClaudeResponse: Codable {
    let content: [ClaudeContentBlock]
}

private struct ClaudeContentBlock: Codable {
    let type: String
    let text: String?
}
