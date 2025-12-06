//
//  Conversation.swift
//  Experiment Visualizer
//
//  Created by AI Assistant on 2025/12/6.
//

import Foundation

struct Conversation: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    var createdAt: Date
    var updatedAt: Date
    
    /// 最新的 HTML 内容（用于 WebView 渲染）
    var latestHTML: String {
        messages.last(where: { $0.contentType == .html })?.content ?? ""
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        messages: [ChatMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id
    }
}

