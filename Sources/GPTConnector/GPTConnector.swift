import Foundation

public enum GPTConnectorError: Error {
    case noFunctionHandling
    case apiKeyMissing
}

public protocol GPTConnector {
    
    var apiKey: String? { get set }
    
    /// Chat with the OpenAI API Chat completion.
    /// - Parameters:
    ///  - context: The context to start the chat with which is just a chat by itself.
    ///  - onChoiceSelect: A closure to select the one of the choices that the api returns. This is only used when a function call or another action
    ///     is received that is not the final chat answer. The chat answer will return all choices as chat variants.
    ///     The default implementation will always select the first choice.
    ///  - onFunctionCall: A closure to handle function calls. The default implementation will throw an error. So if your context offers functions and the
    ///           the model decides to use one, better have this implemented to answer to the function call. The model might get angry and take over the world.
    ///           Don't say I didn't warn you!
    func chat(
        context: Chat,
        onChoiceSelect: @escaping (([Message], Chat) -> Message),
        onFunctionCall: @escaping ((String, String) async throws -> String)
    ) async throws -> [Chat]
}

public extension GPTConnector {
    func chat(
        context: Chat
    ) async throws -> [Chat] {
        return try await self.chat(context: context, onChoiceSelect: { (choices, _) in choices[0] }, onFunctionCall: { (_, _) in throw GPTConnectorError.noFunctionHandling })
    }
    
    func chat(
        context: Chat,
        onChoiceSelect: @escaping (([Message], Chat) -> Message)
    ) async throws -> [Chat] {
        return try await self.chat(context: context, onChoiceSelect: onChoiceSelect, onFunctionCall: { (_, _) in throw GPTConnectorError.noFunctionHandling })
    }
    
    func chat(
        context: Chat,
        onFunctionCall: @escaping ((String, String) async throws -> String)
    ) async throws -> [Chat] {
        return try await self.chat(context: context, onChoiceSelect: { (choices, _) in choices[0] }, onFunctionCall: onFunctionCall)
    }
}

public enum GPTConnectorFactory {
    
    /// Creates a new connector to the OpenAI API Chat completion.
    /// - Parameters:
    ///  - apiKey: The API key to use for the requests. It's an optional, but you have to sat it before the first chat call.
    ///  - numberOfChoices: The number of choices to return. Defaults to 1.
    public static func create(apiKey: String? = nil, numberOfChoices: Int = 1) -> any GPTConnector {
        DefaultGPTConnector(apiKey: apiKey, numberOfChoices: numberOfChoices)
    }
}

/// A connector to the OpenAI API Chat completion.
class DefaultGPTConnector: GPTConnector {
    public var apiKey: String? {
        didSet {
            connector.apiKey = apiKey
        }
    }
    private let numberOfChoices: Int
    private let connector: OpenAIApiConnector
    
    init(apiKey: String? = nil, numberOfChoices: Int = 1) {
        self.apiKey = apiKey
        self.numberOfChoices = numberOfChoices
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 300.0
        sessionConfig.timeoutIntervalForResource = 600.0
        
        self.connector = OpenAIApiConnector(apiKey: apiKey, session: .init(configuration: sessionConfig))
    }
    
    init(apiKey: String? = nil, numberOfChoices: Int = 1, connector: OpenAIApiConnector) {
        self.apiKey = apiKey
        self.numberOfChoices = numberOfChoices
        self.connector = connector
    }
    
    public func chat(
        context: Chat,
        onChoiceSelect: @escaping (([Message], Chat) -> Message) = { (choices, _) in choices[0] },
        onFunctionCall: @escaping ((String, String) async throws -> String) = { (_, _) in throw GPTConnectorError.noFunctionHandling }
    ) async throws -> [Chat] {
        
        guard apiKey != nil else {
            throw GPTConnectorError.apiKeyMissing
        }
        
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
