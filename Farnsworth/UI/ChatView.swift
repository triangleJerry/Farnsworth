//
//  ChatView.swift
//  Farnsworth
//
//  Created by 장은석 on 5/23/25.
//

import SwiftUI
import RegexBuilder

struct ChatView: View {
    
    @State var llm = LLMEvaluator()
    @State private var multiLineText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Status bar with progress indicator
            VStack(spacing: 0) {
                // Progress bar
                if isModelDownloading() {
                    // Red progress bar when downloading
                    ProgressView(value: getDownloadProgress(), total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: .red))
                        .frame(height: 4)
                } else if isModelLoaded() {
                    // Green bar when model is loaded
                    Rectangle()
                        .fill(Color.green)
                        .frame(height: 4)
                } else {
                    // Empty space when neither downloading nor loaded
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 4)
                }
            }
            
            // Chat messages area
            ScrollViewReader { proxy in
                Text("mlxchat")
                    .font(.largeTitle)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                ScrollView {
                    VStack {
                        Text(.init(llm.output))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        // Invisible view at the bottom for scrolling
                        Color.clear
                            .frame(height: 1)
                            .id("bottomID")
                    }
                }
                .onChange(of: llm.output) {
                    withAnimation {
                        proxy.scrollTo("bottomID", anchor: .bottom)
                    }
                }
                .onAppear {
                    // Scroll to bottom when view appears
                    proxy.scrollTo("bottomID", anchor: .bottom)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            
            Divider()
            
            // Input area
            HStack(alignment: .bottom) {
                // Text editor
                ZStack(alignment: .leading) {
                    TextEditor(text: $multiLineText)
                        .padding(4)
                        .cornerRadius(10)
                        .frame(minHeight: 40, maxHeight: 120)
                }
                
                // Send button
                VStack(spacing: 8) {
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.blue)
                    }
                    
                    // Clear button
                    Button(action: clearMessages) {
                        Image(systemName: "trash.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
        }
    }
    
    private func sendMessage() {
        Task {
            await llm.generate(prompt: multiLineText)
        }
    }
    
    private func clearMessages() {
        
    }
    
    // Helper function to check if model is currently downloading
    private func isModelDownloading() -> Bool {
        return llm.modelInfo.contains("Downloading")
    }
    
    // Helper function to check if model is loaded
    private func isModelLoaded() -> Bool {
        return llm.modelInfo.contains("Loaded")
    }
    
    // Helper function to extract download progress percentage
    private func getDownloadProgress() -> Double {
        let regex = Regex {
            "Downloading"
            ZeroOrMore(.any, .reluctant)
            ": "
            Capture {
                OneOrMore(.digit)
            }
            "%"
        }
        
        if let match = llm.modelInfo.firstMatch(of: regex) {
            if let percentage = Double(match.1) {
                return percentage
            }
        }
        return 0
    }
}

#Preview {
    ChatView()
}
