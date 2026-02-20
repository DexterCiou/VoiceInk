// OpenAIService.swift
// VoiceInk — OpenAI GPT LLM 服務

import Foundation

/// OpenAI GPT API 服務
class OpenAIService: LLMProvider {
    // MARK: - LLMProvider

    let name = "OpenAI"
    let modelName = "gpt-4o-mini"

    // MARK: - 常數

    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!

    // MARK: - 公開方法

    func process(text: String, prompt: String) async throws -> String {
        // 從 Keychain 取得 API Key
        guard let apiKey = try KeychainHelper.load(for: .openAIAPIKey), !apiKey.isEmpty else {
            throw LLMError.missingAPIKey
        }

        // 建立請求
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        // 組裝請求 body
        let requestBody = OpenAIRequest(
            model: modelName,
            messages: [
                OpenAIMessage(role: "system", content: prompt),
                OpenAIMessage(role: "user", content: text)
            ],
            max_tokens: 4096,
            temperature: 0.3
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
            AppLogger.error("OpenAI API 錯誤（\(httpResponse.statusCode)）：\(errorBody)")
            throw LLMError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        // 解析回應
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let resultText = openAIResponse.choices.first?.message.content, !resultText.isEmpty else {
            throw LLMError.emptyResponse
        }

        AppLogger.info("OpenAI 潤飾完成，輸入 \(text.count) 字 → 輸出 \(resultText.count) 字")
        return resultText
    }
}

// MARK: - 請求/回應模型

private struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let max_tokens: Int
    let temperature: Double
}

private struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

private struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

private struct OpenAIChoice: Codable {
    let message: OpenAIChoiceMessage
}

private struct OpenAIChoiceMessage: Codable {
    let content: String?
}
