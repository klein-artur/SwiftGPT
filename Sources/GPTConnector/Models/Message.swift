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
    
    /// The role of the message.
    public var role: Role
    
    /// The content of the message.
    public var content: String?
    
    /// The function call.
    public var functionCall: FunctionCall?
    
    /// The name of the sender. In case of a function return it is the name of the function.
    public var name: String?
    
    /// Creates a new message.
    /// - Parameters:
    /// - role: The role of the message.
    /// - content: The content of the message.
    /// - functionCall: The function call.
    /// - name: The name of the sender. In case of a function return it is the name of the function.
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
    
    /// Creates a new user message.
    /// - Parameter content: The content of the message.
    public static func user(_ content: String) -> Message {
        return Message(role: .user, content: content, functionCall: nil, name: nil)
    }
    
    /// Creates a new system message.
    /// - Parameter content: The content of the message.
    /// - Parameter name: The name of the sender. In case of a function return it is the name of the function.
    public static func system(_ content: String, name: String? = nil) -> Message {
        return Message(role: .system, content: content, functionCall: nil, name: name)
    }
    
    /// Creates a new assistant message.
    /// - Parameter content: The content of the message.
    /// - Parameter functionCall: The function call.
    public static func assistant(_ content: String?, functionCall: FunctionCall?) -> Message {
        return Message(role: .assistant, content: content, functionCall: functionCall, name: nil)
    }
    
    /// Creates a new function message.
    /// - Parameter name: The name of the function.
    /// - Parameter result: The result of the function.
    public static func function(name: String, result: String) -> Message {
        return Message(role: .function, content: result, functionCall: nil, name: name)
    }
}

public class FunctionCall: BaseModel, Codable {
    
    /// The name of the function that is called..
    public let name: String
    
    /// The arguments of the function call.
    public let arguments: String
    
    /// Creates a new function call.
    /// - Parameters:
    /// - name: The name of the function that is called..
    /// - arguments: The arguments of the function call.
    public init(name: String, arguments: String) {
        self.name = name
        self.arguments = arguments
        super.init()
    }
}
