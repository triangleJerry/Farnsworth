//
//  LLMEvaluator.swift
//  Farnsworth
//
//  Created by 장은석 on 5/25/25.
//

import SwiftUI
import MLX
import MLXLMCommon
import MLXLLM
import MLXRandom

@Observable
@MainActor
class LLMEvaluator {

    var running = false
    var output = ""
    var modelInfo = ""
    let modelConfiguration = LLMRegistry.llama3_2_1B_4bit
    let generateParameters = GenerateParameters(temperature: 0.6)
    let maxTokens = 240
    let displayEveryNTokens = 4

    enum LoadState {
        case idle
        case loaded(ModelContainer)
    }

    var loadState = LoadState.idle

    func load() async throws -> ModelContainer {
        switch loadState {
        case .idle:

            let modelContainer = try await LLMModelFactory.shared.loadContainer(
                configuration: modelConfiguration
            ) {
                [modelConfiguration] progress in
                Task { @MainActor in
                    self.modelInfo =
                        "Downloading \(modelConfiguration.name): \(Int(progress.fractionCompleted * 100))%"
                }
            }
            let numParams = await modelContainer.perform { context in
                context.model.numParameters()
            }

            self.modelInfo =
                "Loaded \(modelConfiguration.id).  Weights: \(numParams / (1024*1024))M"
            loadState = .loaded(modelContainer)
            return modelContainer

        case .loaded(let modelContainer):
            return modelContainer
        }
    }

    func generate(prompt: String) async {
        guard !running else { return }

        running = true
        self.output = ""

        do {
            let modelContainer = try await load()
            MLXRandom.seed(UInt64(Date.timeIntervalSinceReferenceDate * 1000))
            let result = try await modelContainer.perform { context in
                let input = try await context.processor.prepare(
                    input: .init(
                        messages: [
                            ["role": "system", "content": "You are a helpful assistant."],
                            ["role": "user", "content": prompt],
                        ]))
                return try MLXLMCommon.generate(
                    input: input, parameters: generateParameters, context: context
                ) { tokens in
                    // Show the text in the view as it generates
                    if tokens.count % displayEveryNTokens == 0 {
                        let text = context.tokenizer.decode(tokens: tokens)
                        Task { @MainActor in
                            self.output = text
                        }
                    }
                    if tokens.count >= maxTokens {
                        return .stop
                    } else {
                        return .more
                    }
                }
            }

            if result.output != self.output {
                self.output = result.output
            }

        } catch {
            output = "Failed: \(error)"
        }

        running = false
    }
}
