//
//  Message.swift
//  
//
//  Created by Artur Hellmann on 26.10.23.
//

import Foundation

public class Message: BaseModel, Codable {
    public enum Role: String, Codable {
        case system
        case user
        case assistant
        case function
    }
    
    public var role: Role
    public var content: String?
    public var functionCall: FunctionCall?
    public var name: String?
    
    public init(
        role: Role,
        content: String?,
        functionCall: FunctionCall?,
        name: String?
    ) {
        self.role = role
        self.content = content
        self.functionCall = functionCall
        self.name = name
    }
    
    public static func user(_ content: String) -> Message {
        return Message(role: .user, content: content, functionCall: nil, name: nil)
    }
    
    public static func system(_ content: String, name: String? = nil) -> Message {
        return Message(role: .system, content: content, functionCall: nil, name: name)
    }
    
    public static func assistant(_ content: String?, functionCall: FunctionCall?) -> Message {
        return Message(role: .assistant, content: content, functionCall: functionCall, name: nil)
    }
    
    public static func function(name: String, result: String) -> Message {
        return Message(role: .function, content: result, functionCall: nil, name: name)
    }
}

public class FunctionCall: BaseModel, Codable {
    public let name: String
    public let arguments: String
    
    public init(name: String, arguments: String) {
        self.name = name
        self.arguments = arguments
        super.init()
    }
}
