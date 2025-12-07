# Experiment Visualizer

面向 iOS 与 macOS 的极简教育可视化客户端，使用 SwiftUI + WKWebView 渲染大模型生成的 HTML，可查看历史对话并流式更新内容。配色：背景 `#0F1A1B`，按钮 `#6ECBD3`。

## 功能
- 全屏 WebView 展示可视化 HTML，支持指针拖拽平移
- 侧边栏历史对话列表，支持新建和删除
- 流式生成：OpenRouter SSE 实时追加 HTML
- 生成前显示“正在生成中...”提示
- 设置界面配置 OpenRouter API Key 与默认模型
- 本地 JSON 持久化会话与消息

## 目录结构（核心）
- `Experiment_VisualizerApp.swift`：应用入口
- `ContentView.swift`：主界面（双栏、输入栏、设置入口）
- `WebView.swift`：WKWebView 封装与深色主题包装
- `Stores/ChatStore.swift`：状态与会话管理、持久化、流式处理
- `Services/APIClient.swift`：OpenRouter 调用与 SSE 解析
- `Models/ChatMessage.swift` / `Models/Conversation.swift`：数据模型
- `Views/SettingsView.swift`：API Key 与模型选择界面
- `Theme.swift`：颜色与按钮样式
- `CHANGE_LOG/`：版本更新记录

## 环境要求
- Xcode 16 / Swift 5+
- iOS 18 / macOS 15 目标（已有配置）
- OpenRouter 账户与 API Key

## 配置
1. 启动后点击主视图右上角齿轮，打开设置界面。
2. 填入 `OpenRouter API Key`（从 https://openrouter.ai/keys 获取）。
3. 选择默认模型（示例：`openai/gpt-5-mini`、`openai/gpt-5` 等）。
4. 保存后即可使用。

## 运行
1. 打开项目 `Experiment Visualizer.xcodeproj`
2. 选择目标平台（iOS 模拟器或 macOS）
3. 直接运行（Cmd+R）

## 开发者提示
- API Key 存储于 `UserDefaults`，可在 `SettingsManager` 中调整
- 默认系统提示词位于 `APIClient`，可按需求修改生成风格
- WebView 包装已添加基础样式与拖拽脚本，如需自定义可在 `WebView.swift` 中调整

## 已知改进方向
- 增加停止生成的实际请求取消
- 支持模型列表动态获取
- 优化流式渲染节流与错误提示
- 支持会话重命名与搜索

