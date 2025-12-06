//
//  ChatStore.swift
//  Experiment Visualizer
//
//  Created by AI Assistant on 2025/12/6.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class ChatStore {
    // MARK: - 状态
    var conversations: [Conversation] = []
    var selectedConversationID: UUID?
    var currentHTML: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    
    // 流式内容缓冲
    private var streamBuffer: String = ""
    private var currentStreamTask: Task<Void, Never>?
    
    // MARK: - 计算属性
    var selectedConversation: Conversation? {
        conversations.first { $0.id == selectedConversationID }
    }
    
    // MARK: - 初始化
    init() {
        loadFromDisk()
        
        // 如果没有会话，创建欢迎会话
        if conversations.isEmpty {
            let welcomeConv = Conversation(
                title: "欢迎",
                messages: []
            )
            conversations.append(welcomeConv)
            selectedConversationID = welcomeConv.id
            currentHTML = Self.welcomeHTML
        } else {
            selectedConversationID = conversations.first?.id
            currentHTML = selectedConversation?.latestHTML ?? Self.welcomeHTML
        }
    }
    
    // MARK: - 会话操作
    func selectConversation(_ id: UUID) {
        selectedConversationID = id
        if let conv = selectedConversation {
            currentHTML = conv.latestHTML.isEmpty ? Self.welcomeHTML : conv.latestHTML
        }
    }
    
    func createNewConversation(title: String) -> Conversation {
        let conv = Conversation(title: title)
        conversations.insert(conv, at: 0)
        selectedConversationID = conv.id
        saveToDisk()
        return conv
    }
    
    func deleteConversation(_ id: UUID) {
        conversations.removeAll { $0.id == id }
        if selectedConversationID == id {
            selectedConversationID = conversations.first?.id
            currentHTML = selectedConversation?.latestHTML ?? Self.welcomeHTML
        }
        saveToDisk()
    }
    
    // MARK: - 发送消息（流式）
    func sendMessage(_ prompt: String) {
        guard !prompt.isEmpty else { return }
        
        // 取消之前的流式任务
        currentStreamTask?.cancel()
        errorMessage = nil
        
        // 创建或使用当前会话
        var conv: Conversation
        if let existing = selectedConversation, existing.title == "欢迎" && existing.messages.isEmpty {
            // 更新欢迎会话标题
            if let idx = conversations.firstIndex(where: { $0.id == existing.id }) {
                conversations[idx].title = prompt
                conv = conversations[idx]
            } else {
                conv = createNewConversation(title: prompt)
            }
        } else if selectedConversation != nil {
            conv = selectedConversation!
        } else {
            conv = createNewConversation(title: prompt)
        }
        
        // 添加用户消息
        let userMessage = ChatMessage(
            conversationId: conv.id,
            role: .user,
            contentType: .text,
            content: prompt
        )
        appendMessage(userMessage, to: conv.id)
        
        // 创建助手消息占位
        let assistantMessage = ChatMessage(
            conversationId: conv.id,
            role: .assistant,
            contentType: .html,
            content: "",
            isStreaming: true
        )
        appendMessage(assistantMessage, to: conv.id)
        
        isLoading = true
        streamBuffer = ""
        currentHTML = ""
        
        // 开始流式请求
        currentStreamTask = Task {
            do {
                let stream = await APIClient.shared.streamChat(prompt: prompt)
                
                for try await chunk in stream {
                    guard !Task.isCancelled else { break }
                    
                    streamBuffer += chunk
                    currentHTML = streamBuffer
                    
                    // 更新消息内容
                    updateLastAssistantMessage(in: conv.id, content: streamBuffer, isStreaming: true)
                }
                
                // 流式完成
                updateLastAssistantMessage(in: conv.id, content: streamBuffer, isStreaming: false)
                isLoading = false
                saveToDisk()
                
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                    // 显示错误 HTML
                    currentHTML = """
                    <div style="display: flex; flex-direction: column; justify-content: center; align-items: center; min-height: 80vh; text-align: center;">
                        <h2 style="color: #ff6b6b;">请求失败</h2>
                        <p style="color: rgba(255,255,255,0.6);">\(error.localizedDescription)</p>
                    </div>
                    """
                    updateLastAssistantMessage(in: conv.id, content: currentHTML, isStreaming: false)
                }
                isLoading = false
            }
        }
    }
    
    // MARK: - 辅助方法
    private func appendMessage(_ message: ChatMessage, to conversationID: UUID) {
        guard let idx = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
        conversations[idx].messages.append(message)
        conversations[idx].updatedAt = Date()
    }
    
    private func updateLastAssistantMessage(in conversationID: UUID, content: String, isStreaming: Bool) {
        guard let convIdx = conversations.firstIndex(where: { $0.id == conversationID }),
              let msgIdx = conversations[convIdx].messages.lastIndex(where: { $0.role == .assistant }) else { return }
        
        conversations[convIdx].messages[msgIdx].content = content
        conversations[convIdx].messages[msgIdx].isStreaming = isStreaming
        conversations[convIdx].updatedAt = Date()
    }
    
    // MARK: - 持久化（简单文件存储）
    private var storageURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("conversations.json")
    }
    
    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(conversations)
            try data.write(to: storageURL)
        } catch {
            print("保存失败: \(error)")
        }
    }
    
    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: storageURL)
            conversations = try JSONDecoder().decode([Conversation].self, from: data)
        } catch {
            print("加载失败: \(error)")
        }
    }
    
    // MARK: - 欢迎 HTML
    static let welcomeHTML = """
    <div style="display: flex; flex-direction: column; justify-content: center; align-items: center; min-height: 80vh; text-align: center;">
        <h1 style="font-size: 28px; font-weight: 600; margin-bottom: 16px;">Experiment Visualizer</h1>
        <p style="color: rgba(255,255,255,0.6); font-size: 16px;">输入知识点，AI 将生成可视化内容</p>
    </div>
    """
}

