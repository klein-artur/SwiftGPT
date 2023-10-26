import Foundation

public struct GPTConnector {
    private let apiKey: String
    private let numberOfChoices: Int
    private let connector: OpenAIApiConnector
    
    public enum ConnectorError: Error {
        case noFunctionHandling
    }

    public init(apiKey: String, numberOfChoices: Int = 1) {
        self.apiKey = apiKey
        self.numberOfChoices = numberOfChoices
        self.connector = OpenAIApiConnector(apiKey: apiKey, session: .shared)
    }
    
    init(apiKey: String, numberOfChoices: Int = 1, connector: OpenAIApiConnector) {
        self.apiKey = apiKey
        self.numberOfChoices = numberOfChoices
        self.connector = connector
    }
    
    public func chat(
        context: Chat,
        onChoiceSelect: @escaping (([Message], Chat) -> Message) = { (choices, _) in choices[0] },
        onFunctionCall: @escaping ((String, String) async throws -> String) = { (_, _) in throw ConnectorError.noFunctionHandling }
    ) async throws -> [Chat] {
        
        var context = context
        
        var toReturn: [Chat]? = nil
        
        while toReturn == nil {
            let result = try await execute(context: context)
            
            if result.map({ $0.functionCall != nil }).contains(true) {
                
                let choosenMessage = onChoiceSelect(result, context)
                
                if let functionCall = choosenMessage.functionCall {
                    
                    context = context.byAddingMessage(choosenMessage)
                    
                    let functionResult = try await onFunctionCall(functionCall.name, functionCall.arguments)
                    let functionMessage: Message = .function(name: functionCall.name, result: functionResult)
                    
                    context = context.byAddingMessage(functionMessage)
                    
                } else {
                    toReturn = result.map { message in
                        context.byAddingMessage(message)
                    }
                }
            } else {
                toReturn = result.map { message in
                    context.byAddingMessage(message)
                }
            }
            
        }
        
        return toReturn!
    }
    
    private func execute(
        context: Chat
    ) async throws -> [Message] {
        
        let result = try await connector
            .send(chatData: context.chatData)
        
        return result.choices.map { $0.message.message }
    }
}

private extension Chat {
    func byAddingMessage(_ message: Message) -> Chat {
        var messages = self.messages
        messages.append(message)
        
        return .init(
            model: self.model,
            messages: messages,
            temperature: self.temperature,
            functions: self.functions,
            functionCall: self.functionCall
        )
    }
}

private extension AsyncThrowingStream {
    var last: Element? {
        get async throws {
            var lastItem: Element? = nil
            do {
                for try await item in self {
                    lastItem = item
                }
            } catch {
                throw error
            }
            return lastItem
        }
    }
}
