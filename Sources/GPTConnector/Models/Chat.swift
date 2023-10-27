//
//  Chat.swift
//  
//
//  Created by Artur Hellmann on 26.10.23.
//

import Foundation

public class Chat: BaseModel {
    
    public enum FunctionCallInstruction {
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
    public var functions: [Function]
    
    /// The token count this chat has already taken. Will just be set if it's returned by the api.
    public var tokenCount: Int = 0
    
    /// The instruction on how to handle function calls.
    public var functionCall: FunctionCallInstruction

    /// Creates a new chat.
    /// - Parameters:
    ///  - model: The model to use for the chat. Default is GPT4
    ///  - messages: The messages of this chat.
    ///  - temperature: The temperature of the chat. Default is 0.7
    ///  - functions: The functions that will be provided to the model.
    ///  - functionCall: The instruction on how to handle function calls.
    ///  - tokenCount: The token count this chat has already taken.
    public init(
        model: String = "gpt-4",
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
    }
}
