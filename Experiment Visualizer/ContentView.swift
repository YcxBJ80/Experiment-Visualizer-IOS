//
//  ContentView.swift
//  Experiment Visualizer
//
//  Created by 杨承轩 on 2025/12/6.
//

import SwiftUI

struct ContentView: View {
    @State private var store = ChatStore()
    @State private var inputText = ""
    @State private var showSettings = false
    
    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            mainContent
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
    
    // MARK: - 侧边栏
    private var sidebar: some View {
        List(selection: Binding(
            get: { store.selectedConversationID },
            set: { if let id = $0 { store.selectConversation(id) } }
        )) {
            ForEach(store.conversations) { conv in
                Text(conv.title)
                    .foregroundColor(.appText)
                    .lineLimit(1)
                    .tag(conv.id)
            }
            .onDelete { indexSet in
                for idx in indexSet {
                    store.deleteConversation(store.conversations[idx].id)
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("历史")
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    _ = store.createNewConversation(title: "新对话")
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.appAccent)
                }
            }
        }
    }
    
    // MARK: - 主内容区
    private var mainContent: some View {
        ZStack {
            WebView(htmlContent: store.currentHTML)
                .ignoresSafeArea()
            
            if store.isLoading && store.currentHTML.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("正在生成中...")
                    .font(.headline)
                    .foregroundColor(.appTextSecondary)
                    .padding()
            }
            
            VStack {
                Spacer()
                
                // 错误提示
                if let error = store.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                inputBar
            }
        }
        .background(Color.appBackground)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(.appTextSecondary)
                }
            }
        }
    }
    
    // MARK: - 输入栏
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("输入知识点...", text: $inputText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.inputBackground)
                .foregroundColor(.appText)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .onSubmit {
                    sendMessage()
                }
            
            Button {
                sendMessage()
            } label: {
                Image(systemName: store.isLoading ? "stop.fill" : "arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(Color.appAccent)
                    .foregroundColor(.appBackground)
                    .clipShape(Circle())
            }
            .disabled(inputText.isEmpty && !store.isLoading)
            .opacity(inputText.isEmpty && !store.isLoading ? 0.5 : 1.0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - 发送消息
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let prompt = inputText
        inputText = ""
        store.sendMessage(prompt)
    }
}

#Preview {
    ContentView()
}
