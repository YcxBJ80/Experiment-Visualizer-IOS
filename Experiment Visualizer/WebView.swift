//
//  WebView.swift
//  Experiment Visualizer
//
//  Created by 杨承轩 on 2025/12/6.
//

import SwiftUI
import WebKit

#if os(iOS)
typealias PlatformViewRepresentable = UIViewRepresentable
#elseif os(macOS)
typealias PlatformViewRepresentable = NSViewRepresentable
#endif

struct WebView: PlatformViewRepresentable {
    let htmlContent: String
    
    #if os(iOS)
    func makeUIView(context: Context) -> WKWebView {
        let webView = createWebView()
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        loadHTML(in: webView)
    }
    #elseif os(macOS)
    func makeNSView(context: Context) -> WKWebView {
        let webView = createWebView()
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        loadHTML(in: webView)
    }
    #endif
    
    private func createWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        #if os(iOS)
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        #elseif os(macOS)
        webView.setValue(false, forKey: "drawsBackground")
        #endif
        return webView
    }
    
    private func loadHTML(in webView: WKWebView) {
        // 包装 HTML，设置深色背景与基础样式
        let wrappedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { box-sizing: border-box; }
                html, body {
                    margin: 0;
                    padding: 16px;
                    background-color: #1C1C21;
                    color: #FFFFFF;
                    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
                    font-size: 16px;
                    line-height: 1.6;
                    min-height: 100vh;
                }
                a { color: #6ECBD3; }
                pre, code {
                    background-color: #1C1C21;
                    border-radius: 6px;
                    padding: 2px 6px;
                    font-family: 'SF Mono', Menlo, monospace;
                }
                pre {
                    padding: 12px;
                    overflow-x: auto;
                }
            </style>
        </head>
        <body>
        \(htmlContent)
        </body>
        </html>
        """
        webView.loadHTMLString(wrappedHTML, baseURL: nil)
    }
}


