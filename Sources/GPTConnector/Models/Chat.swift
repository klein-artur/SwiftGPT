//
//  Chat.swift
//  
//
//  Created by Artur Hellmann on 26.10.23.
//

import Foundation

public class Chat: BaseModel {
    
    @available(*, deprecated, message: "Use ToolChoice instead.")
    public enum FunctionCallInstruction {
        case none
        case auto
        case forced(name: String)
    }
    
    public enum ToolChoice {
        case none
        case auto
        case forced(name: String)
    }
    
    /// The model to use for the chat. Default is GPT4
    public var model: String
    
    /// The messages of this chat.
    public var messages: [Message]
    
    /// The temperature of the chat. Default is 0.7
    public var temperature: Float
    
    /// The functions that will be provided to the model.
    @available(*, deprecated, message: "Use the new tools field")
    public var functions: [Function]
    
    /// The tools that will be provided to the model.
    public var tools: [Tool]
    
    /// The token count this chat has already taken. Will just be set if it's returned by the api.
    public var tokenCount: Int = 0
    
    /// The instruction on how to handle function calls.
    @available(*, deprecated, message: "You should use the new toolChoice field.")
    public var functionCall: FunctionCallInstruction
    
    /// The instruction how to handle tool calls.
    public var toolChoice: ToolChoice
    
    private let deprecationMode: Bool
    
    /// Creates a new chat.
    /// - Parameters:
    ///  - model: The model to use for the chat. Default is "gpt-4-1106-preview"
    ///  - messages: The messages of this chat.
    ///  - temperature: The temperature of the chat. Default is 0.7
    ///  - tools: The tools that will be provided to the model.
    ///  - toolChoice: The instruction on how to handle tool calls.
    ///  - tokenCount: The token count this chat has already taken.
    public init(
        model: String = "gpt-4-1106-preview",
        messages: [Message],
        temperature: Float = 0.7,
        tools: [Tool],
        toolChoice: ToolChoice = .auto
    ) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.tools = tools
        self.toolChoice = toolChoice
        
        deprecationMode = false
        
        self.functionCall = .auto
        self.functions = []
    }

    /// Creates a new chat.
    /// - Parameters:
    ///  - model: The model to use for the chat. Default is GPT4
    ///  - messages: The messages of this chat.
    ///  - temperature: The temperature of the chat. Default is 0.7
    ///  - functions: The functions that will be provided to the model.
    ///  - functionCall: The instruction on how to handle function calls.
    ///  - tokenCount: The token count this chat has already taken.
    @available(*, deprecated, message: "This is deprecated due to the deprecated function api of OpenAI. Use tools instead.")
    public init(
        model: String = "gpt-4-1106-preview",
        messages: [Message],
        temperature: Float = 0.7,
        functions: [Function] = [],
        functionCall: FunctionCallInstruction = .auto
    ) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.functions = functions
        self.functionCall = functionCall
        
        deprecationMode = true
        
        self.toolChoice = .auto
        self.tools = []
    }
}
