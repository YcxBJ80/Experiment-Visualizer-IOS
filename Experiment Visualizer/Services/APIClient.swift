//
//  APIClient.swift
//  Experiment Visualizer
//
//  Created by AI Assistant on 2025/12/6.
//

import Foundation

// MARK: - 配置
enum APIConfig {
    /// 从设置管理器读取 API Key
    static var openRouterAPIKey: String {
        SettingsManager.shared.apiKey
    }
    
    /// 从设置管理器读取选择的模型
    static var selectedModel: String {
        SettingsManager.shared.selectedModel
    }
    
    static let openRouterBaseURL = "https://openrouter.ai/api/v1"
    static let defaultModel = "openai/gpt-5-mini"
}

// MARK: - API 错误
enum APIError: Error, LocalizedError {
    case invalidURL
    case noAPIKey
    case requestFailed(Error)
    case invalidResponse
    case streamingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的 URL"
        case .noAPIKey: return "缺少 API Key，请在设置中配置"
        case .requestFailed(let error): return "请求失败: \(error.localizedDescription)"
        case .invalidResponse: return "无效的响应"
        case .streamingError(let msg): return "流式错误: \(msg)"
        }
    }
}

// MARK: - OpenRouter 请求/响应模型
struct OpenRouterRequest: Codable {
    let model: String
    let messages: [OpenRouterMessage]
    let stream: Bool
    
    struct OpenRouterMessage: Codable {
        let role: String
        let content: String
    }
}

struct OpenRouterStreamChunk: Codable {
    let choices: [Choice]?
    
    struct Choice: Codable {
        let delta: Delta?
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case delta
            case finishReason = "finish_reason"
        }
    }
    
    struct Delta: Codable {
        let content: String?
    }
}

// MARK: - API Client
actor APIClient {
    static let shared = APIClient()
    
    private init() {}
    
    /// 系统提示词：生成可视化 HTML
    private let systemPrompt = """
    你是一个教育可视化助手。用户会输入一个知识点，你需要生成一段可交互的 HTML/CSS/JavaScript 代码来可视化这个知识点。
    
    要求：
    1. 直接输出 HTML 代码，不要用 markdown 代码块包裹（不要出现 ```html 或 ``` 这样的代码块包裹）
    2. 代码应该是完整的、可直接运行的
    3. 使用深色主题（背景 #1C1C21，文字白色，强调色 #6ECBD3）
    4. 包含动画或交互效果来帮助理解
    5. 代码简洁，注重可视化效果
    6. 对于知识点中可调整的参数，需要提供一个可调整的滑块
    
    UI格式要求：
    1. 左侧75%左右的区域用于可视化实验
    2. 右侧25%左右的区域用于调整参数，提供知识点讲解和背景知识
    """
    
    /// 流式调用 OpenRouter，返回 AsyncThrowingStream
    func streamChat(
        prompt: String,
        model: String = APIConfig.selectedModel
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try await performStreamRequest(
                        prompt: prompt,
                        model: model,
                        continuation: continuation
                    )
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func performStreamRequest(
        prompt: String,
        model: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        guard !APIConfig.openRouterAPIKey.isEmpty else {
            throw APIError.noAPIKey
        }
        
        guard let url = URL(string: "\(APIConfig.openRouterBaseURL)/chat/completions") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIConfig.openRouterAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Experiment Visualizer iOS/macOS", forHTTPHeaderField: "HTTP-Referer")
        
        let body = OpenRouterRequest(
            model: model,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: prompt)
            ],
            stream: true
        )
        request.httpBody = try JSONEncoder().encode(body)
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        // 解析 SSE 流
        for try await line in bytes.lines {
            // SSE 格式: "data: {...}"
            guard line.hasPrefix("data: ") else { continue }
            
            let jsonString = String(line.dropFirst(6))
            
            // 流结束标记
            if jsonString == "[DONE]" {
                break
            }
            
            // 解析 JSON
            guard let data = jsonString.data(using: .utf8),
                  let chunk = try? JSONDecoder().decode(OpenRouterStreamChunk.self, from: data),
                  let content = chunk.choices?.first?.delta?.content else {
                continue
            }
            
            continuation.yield(content)
        }
        
        continuation.finish()
    }
}

