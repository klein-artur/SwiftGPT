import Foundation

/// A connector to the OpenAI API Chat completion.
public struct GPTConnector {
    private let apiKey: String
    private let numberOfChoices: Int
    private let connector: OpenAIApiConnector
    
    public enum ConnectorError: Error {
        case noFunctionHandling
    }

    /// Creates a new connector to the OpenAI API Chat completion.
    /// - Parameters:
    ///  - apiKey: The API key to use for the requests.
    ///  - numberOfChoices: The number of choices to return. Defaults to 1.
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
    
    /// Chat with the OpenAI API Chat completion.
    /// - Parameters:
    ///  - context: The context to start the chat with which is just a chat by itself.
    ///  - onChoiceSelect: A closure to select the one of the choices that the api returns. This is only used when a function call or another action
    ///     is received that is not the final chat answer. The chat answer will return all choices as chat variants.
    ///     The default implementation will always select the first choice.
    ///  - onFunctionCall: A closure to handle function calls. The default implementation will throw an error. So if your context offers functions and the
    ///           the model decides to use one, better have this implemented to answer to the function call. The model might get angry and take over the world.
    ///           Don't say I didn't warn you!
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
            .send(chatData: context.chatData, numberOfChoices: self.numberOfChoices)
        
        return result.choices.map { $0.message.message }
    }
}

public extension Chat {
    
    /// Creates a new chat with the given message added.
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
