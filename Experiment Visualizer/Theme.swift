//
//  Theme.swift
//  Experiment Visualizer
//
//  Created by 杨承轩 on 2025/12/6.
//

import SwiftUI

// MARK: - App Colors
extension Color {
    /// 主背景色 #1C1C21
    static let appBackground = Color(red: 0.11, green: 0.11, blue: 0.13)
    
    /// 主按钮色 #6ECBD3
    static let appAccent = Color(red: 110/255, green: 203/255, blue: 211/255)
    
    /// 输入框背景（略浅于主背景）
    static let inputBackground = Color(red: 30/255, green: 42/255, blue: 44/255)
    
    /// 文字颜色
    static let appText = Color.white
    static let appTextSecondary = Color.white.opacity(0.6)
}

// MARK: - Button Styles
struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.appAccent.opacity(configuration.isPressed ? 0.7 : 1.0))
            .foregroundColor(.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

extension ButtonStyle where Self == AccentButtonStyle {
    static var accent: AccentButtonStyle { AccentButtonStyle() }
}


