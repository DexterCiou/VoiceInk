// GroqWhisperService.swift
// VoiceInk — Groq Whisper STT 語音轉文字服務

import Foundation

/// Groq Whisper API 語音轉文字服務
class GroqWhisperService {
    // MARK: - 常數

    /// Groq API 端點
    private let apiURL = URL(string: "https://api.groq.com/openai/v1/audio/transcriptions")!
    /// 使用的 Whisper 模型
    private let model = "whisper-large-v3"

    // MARK: - 公開方法

    /// 將音訊檔案轉錄為文字
    /// - Parameters:
    ///   - audioURL: 音訊檔案路徑
    ///   - language: 語言代碼（如 "zh"、"en"），傳 nil 則自動偵測
    /// - Returns: 轉錄結果
    func transcribe(audioURL: URL, language: String? = nil) async throws -> TranscriptionResult {
        // 從 Keychain 取得 API Key
        guard let apiKey = try KeychainHelper.load(for: .groqAPIKey), !apiKey.isEmpty else {
            throw GroqWhisperError.missingAPIKey
        }

        // 讀取音訊檔案
        let audioData = try Data(contentsOf: audioURL)
        guard !audioData.isEmpty else {
            throw GroqWhisperError.emptyAudioFile
        }

        // 建立 multipart/form-data 請求
        let boundary = UUID().uuidString
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        // 組裝 multipart body
        var body = Data()

        // 添加模型欄位
        body.appendMultipartField(name: "model", value: model, boundary: boundary)

        // 添加語言欄位（若有指定）
        if let language, language != "auto" {
            body.appendMultipartField(name: "language", value: language, boundary: boundary)
        }

        // 添加回應格式
        body.appendMultipartField(name: "response_format", value: "verbose_json", boundary: boundary)

        // 添加音訊檔案
        body.appendMultipartFile(
            name: "file",
            fileName: audioURL.lastPathComponent,
            mimeType: "audio/m4a",
            data: audioData,
            boundary: boundary
        )

        // 結束邊界
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        // 發送請求
        let (data, response) = try await URLSession.shared.data(for: request)

        // 檢查 HTTP 狀態碼
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GroqWhisperError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "未知錯誤"
            AppLogger.error("Groq API 錯誤（\(httpResponse.statusCode)）：\(errorBody)")
            throw GroqWhisperError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        // 解析回應
        let decoder = JSONDecoder()
        let groqResponse = try decoder.decode(GroqWhisperResponse.self, from: data)

        AppLogger.info("轉錄完成，偵測語言：\(groqResponse.language ?? "未知")")

        return TranscriptionResult(
            text: groqResponse.text,
            language: groqResponse.language ?? "unknown",
            duration: groqResponse.duration ?? 0,
            model: model
        )
    }
}

// MARK: - 回應模型

/// Groq Whisper API 回應
private struct GroqWhisperResponse: Codable {
    let text: String
    let language: String?
    let duration: Double?
}

/// 轉錄結果
struct TranscriptionResult {
    let text: String
    let language: String
    let duration: Double
    let model: String
}

// MARK: - 錯誤類型

enum GroqWhisperError: LocalizedError {
    case missingAPIKey
    case emptyAudioFile
    case invalidResponse
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "未設定 Groq API Key，請在設定中輸入您的 API Key"
        case .emptyAudioFile:
            return "音訊檔案為空，請重新錄音"
        case .invalidResponse:
            return "API 回應格式無效"
        case .apiError(let statusCode, let message):
            return "Groq API 錯誤（\(statusCode)）：\(message)"
        }
    }
}

// MARK: - Data 擴充（Multipart 組裝輔助）

extension Data {
    /// 添加 multipart 文字欄位
    mutating func appendMultipartField(name: String, value: String, boundary: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append("\(value)\r\n".data(using: .utf8)!)
    }

    /// 添加 multipart 檔案欄位
    mutating func appendMultipartFile(name: String, fileName: String, mimeType: String, data: Data, boundary: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        append(data)
        append("\r\n".data(using: .utf8)!)
    }
}
