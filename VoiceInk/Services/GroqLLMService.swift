// GroqLLMService.swift
// VoiceInk — Groq LLM 文字潤飾服務（使用與 Whisper 相同的 API Key）

import Foundation

/// Groq LLM 服務，使用 Groq 的 Chat Completion API 進行文字潤飾
class GroqLLMService: LLMProvider {
    // MARK: - LLMProvider

    let name = "Groq"
    let modelName = "llama-3.3-70b-versatile"

    // MARK: - 常數

    private let apiURL = URL(string: "https://api.groq.com/openai/v1/chat/completions")!

    // MARK: - 公開方法

    func process(text: String, prompt: String) async throws -> String {
        // 使用與 Whisper 相同的 Groq API Key
        guard let apiKey = try KeychainHelper.load(for: .groqAPIKey), !apiKey.isEmpty else {
            throw LLMError.missingAPIKey
        }

        // 建立請求
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        // 組裝請求 body
        let requestBody = GroqChatRequest(
            model: modelName,
            messages: [
                GroqChatMessage(role: "system", content: prompt),
                GroqChatMessage(role: "user", content: text)
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
            AppLogger.error("Groq LLM API 錯誤（\(httpResponse.statusCode)）：\(errorBody)")
            throw LLMError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        // 解析回應（與 OpenAI 格式相同）
        let groqResponse = try JSONDecoder().decode(GroqChatResponse.self, from: data)

        guard let resultText = groqResponse.choices.first?.message.content, !resultText.isEmpty else {
            throw LLMError.emptyResponse
        }

        AppLogger.info("Groq LLM 潤飾完成，輸入 \(text.count) 字 → 輸出 \(resultText.count) 字")
        return resultText
    }
}

// MARK: - 請求/回應模型

private struct GroqChatRequest: Codable {
    let model: String
    let messages: [GroqChatMessage]
    let max_tokens: Int
    let temperature: Double
}

private struct GroqChatMessage: Codable {
    let role: String
    let content: String
}

private struct GroqChatResponse: Codable {
    let choices: [GroqChatChoice]
}

private struct GroqChatChoice: Codable {
    let message: GroqChatChoiceMessage
}

private struct GroqChatChoiceMessage: Codable {
    let content: String?
}
