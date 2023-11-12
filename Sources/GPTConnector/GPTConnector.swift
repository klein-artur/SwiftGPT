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
    ///  - onMessagesReceived: A closure that will be called when messages are received to build up the new chat object. Multiple choices are represented by multiple messages.
    ///         You need to select a message by returning it. If the returned chat contains a function call the next callback will be called
    ///         The default implementation will always select the first choice.
    ///  - onFunctionCall: A closure to handle function calls. The default implementation will throw an error. So if your context offers functions and the
    ///           the model decides to use one, better have this implemented to answer to the function call. The model might get angry and take over the world.
    ///           Don't say I didn't warn you!
    /// - Returns: The updated chat object.
    @available(*, deprecated, message: "Use the new chat interface with tools calls")
    func chat(
        context: Chat,
        onMessagesReceived: @escaping (([Message], Chat) -> Message),
        onFunctionCall: @escaping ((String, String) async throws -> String)
    ) async throws -> Chat
    
    /// Chat with the OpenAI API Chat completion.
    /// - Parameters:
    ///  - context: The context to start the chat with which is just a chat by itself.
    ///  - onMessagesReceived: A closure that will be called when messages are received to build up the new chat object. Multiple choices are represented by multiple messages.
    ///         You need to select a message by returning it. If the returned chat contains a function call the next callback will be called
    ///         The default implementation will always select the first choice.
    ///  - onToolCall: A closure to handle tool calls. The default implementation will throw an error. So if your context offers tools and the
    ///           the model decides to use one, better have this implemented to answer to the tools call. The model might get angry and take over the world.
    ///           Don't say I didn't warn you!
    /// - Returns: The updated chat object.
    func chat(
        context: Chat,
        onMessagesReceived: @escaping (([Message], Chat) -> Message),
        onToolCall: @escaping ((ToolCall) async throws -> String)
    ) async throws -> Chat
}

public extension GPTConnector {
    func chat(
        context: Chat
    ) async throws -> Chat {
        return try await self.chat(context: context, onMessagesReceived: { (choices, _) in choices[0] }, onToolCall: { (_) in throw GPTConnectorError.noFunctionHandling })
    }
    
    func chat(
        context: Chat,
        onMessagesReceived: @escaping (([Message], Chat) -> Message)
    ) async throws -> Chat {
        return try await self.chat(context: context, onMessagesReceived: onMessagesReceived, onToolCall: { (_) in throw GPTConnectorError.noFunctionHandling })
    }
    
    @available(*, deprecated, message: "Use the new tool calls api.")
    func chat(
        context: Chat,
        onFunctionCall: @escaping ((String, String) async throws -> String)
    ) async throws -> Chat {
        return try await self.chat(context: context, onMessagesReceived: { (choices, _) in choices[0] }, onFunctionCall: onFunctionCall)
    }
    
    func chat(
        context: Chat,
        onToolCall: @escaping ((ToolCall) async throws -> String)
    ) async throws -> Chat {
        return try await self.chat(context: context, onMessagesReceived: { (choices, _) in choices[0] }, onToolCall: onToolCall)
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
        onMessagesReceived: @escaping (([Message], Chat) -> Message),
        onToolCall: @escaping ((ToolCall) async throws -> String)
    ) async throws -> Chat {
        guard apiKey != nil else {
            throw GPTConnectorError.apiKeyMissing
        }
        
        var context = context
        
        var toReturn: Chat? = nil
        
        while toReturn == nil {
            let result = try await execute(context: context)
            
            let choosenMessage = onMessagesReceived(result, context)
            
            if choosenMessage.toolCalls.isEmpty {
                toReturn = context.byAddingMessage(choosenMessage)
            } else {
                context = context.byAddingMessage(choosenMessage)
                
                for call in choosenMessage.toolCalls {
                    let toolResult = try await onToolCall(call)
                    let toolMessage: Message = .tool(toolCallId: call.id, result: toolResult)
                    
                    context = context.byAddingMessage(toolMessage)
                }
            }
        }
        
        return toReturn!
    }
    
    public func chat(
        context: Chat,
        onMessagesReceived: @escaping (([Message], Chat) -> Message) = { (choices, _) in choices[0] },
        onFunctionCall: @escaping ((String, String) async throws -> String) = { (_, _) in throw GPTConnectorError.noFunctionHandling }
    ) async throws -> Chat {
        
        guard apiKey != nil else {
            throw GPTConnectorError.apiKeyMissing
        }
        
        var context = context
        
        var toReturn: Chat? = nil
        
        while toReturn == nil {
            let result = try await execute(context: context)
            
            let choosenMessage = onMessagesReceived(result, context)
            
            if let functionCall = choosenMessage.functionCall {
                
                context = context.byAddingMessage(choosenMessage)
                
                let functionResult = try await onFunctionCall(functionCall.name, functionCall.arguments)
                let functionMessage: Message = .function(name: functionCall.name, result: functionResult)
                
                context = context.byAddingMessage(functionMessage)
                
            } else {
                toReturn = context.byAddingMessage(choosenMessage)
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
