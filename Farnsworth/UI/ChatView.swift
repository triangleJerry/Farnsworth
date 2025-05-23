//
//  ChatView.swift
//  Farnsworth
//
//  Created by 장은석 on 5/23/25.
//

import SwiftUI
import LLM

class Model: LLM {
    
    convenience init() {
        
        let url = Bundle.main.url(forResource: "llama-3.2-1b-instruct-q4_k_m", withExtension: "gguf")!
        let systemPrompt = "You are a helpful AI assistant."
        self.init(from: url, template: .chatML(systemPrompt))!
    }
}

struct ChatView: View {
    
    @ObservedObject var llm: Model
    @State private var multiLineText = ""
    
    init(_ llm: Model) {
        
        self.llm = llm
    }
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            // Chat messages area
            ScrollViewReader { proxy in
                Text("llmchat")
                    .font(.largeTitle)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                ScrollView {
                    VStack {
                        // to be replaced later on
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
                        proxy.scrollTo("bottomID"
                                       , anchor: .bottom)
                    }
                }
                .onAppear {
                    // Scroll to bottom when view appears
                    proxy.scrollTo("bottomID"
                                   , anchor: .bottom)
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
        .task { }
    }
    
    private func sendMessage() {
        Task {
            await llm.respond(to: multiLineText)
        }
    }
    
    private func clearMessages() {
        // to be implemented
    }
}

#Preview {
    ChatView(Model())
}
