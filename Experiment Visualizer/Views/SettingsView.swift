//
//  SettingsView.swift
//  Experiment Visualizer
//
//  Created by AI Assistant on 2025/12/6.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @State private var selectedModel: String = APIConfig.defaultModel
    @State private var showAPIKey: Bool = false
    @State private var isSaved: Bool = false
    
    private let availableModels = [
        "openai/gpt-5-mini",
        "openai/gpt-5",
        "anthropic/claude-haiku-4.5",
        "google/gemini-3-pro-preview"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // API Key 配置
                Section {
                    HStack {
                        if showAPIKey {
                            TextField("sk-or-v1-...", text: $apiKey)
                                .textFieldStyle(.plain)
                                .font(.system(.body, design: .monospaced))
                        } else {
                            SecureField("sk-or-v1-...", text: $apiKey)
                                .textFieldStyle(.plain)
                        }
                        
                        Button {
                            showAPIKey.toggle()
                        } label: {
                            Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                .foregroundColor(.appTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("OpenRouter API Key")
                } footer: {
                    Text("从 [openrouter.ai/keys](https://openrouter.ai/keys) 获取 API Key")
                }
                
                // 模型选择
                Section {
                    Picker("模型", selection: $selectedModel) {
                        ForEach(availableModels, id: \.self) { model in
                            Text(model.split(separator: "/").last ?? Substring(model))
                                .tag(model)
                        }
                    }
                } header: {
                    Text("默认模型")
                }
                
                // 保存状态
                if isSaved {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("已保存")
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("设置")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveSettings()
                    }
                    .foregroundColor(.appAccent)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.appTextSecondary)
                }
            }
            .onAppear {
                loadSettings()
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 300)
        #endif
    }
    
    private func loadSettings() {
        apiKey = SettingsManager.shared.apiKey
        selectedModel = SettingsManager.shared.selectedModel
    }
    
    private func saveSettings() {
        SettingsManager.shared.apiKey = apiKey
        SettingsManager.shared.selectedModel = selectedModel
        
        withAnimation {
            isSaved = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// MARK: - 设置管理器
final class SettingsManager {
    static let shared = SettingsManager()
    
    private let apiKeyKey = "openrouter_api_key"
    private let modelKey = "selected_model"
    
    private init() {}
    
    var apiKey: String {
        get {
            UserDefaults.standard.string(forKey: apiKeyKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: apiKeyKey)
        }
    }
    
    var selectedModel: String {
        get {
            UserDefaults.standard.string(forKey: modelKey) ?? APIConfig.defaultModel
        }
        set {
            UserDefaults.standard.set(newValue, forKey: modelKey)
        }
    }
}

#Preview {
    SettingsView()
}

