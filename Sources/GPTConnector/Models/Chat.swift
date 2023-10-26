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
    
    public var model: String
    public var messages: [Message]
    public var temperature: Float
    public var functions: [Function]
    public var tokenCount: Int = 0
    public var functionCall: FunctionCallInstruction

    public init(
        model: String = "gpt-3.5-turbo",
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
