//
//  ChatMessage.swift
//  Experiment Visualizer
//
//  Created by 杨承轩 on 2025/12/6.
//

import Foundation

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

enum ContentType: String, Codable {
    case text
    case html
}

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let conversationId: UUID
    let role: MessageRole
    let contentType: ContentType
    var content: String  // 文本或 HTML 字符串（流式时会追加）
    let timestamp: Date
    var isStreaming: Bool  // 是否正在流式接收
    
    init(
        id: UUID = UUID(),
        conversationId: UUID,
        role: MessageRole,
        contentType: ContentType = .text,
        content: String,
        timestamp: Date = Date(),
        isStreaming: Bool = false
    ) {
        self.id = id
        self.conversationId = conversationId
        self.role = role
        self.contentType = contentType
        self.content = content
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}
