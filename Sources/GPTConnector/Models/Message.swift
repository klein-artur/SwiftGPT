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
        case tool
    }
    
    private var usesDeprecationMode: Bool
    
    /// The role of the message.
    public var role: Role
    
    /// The content of the message.
    public var content: String?
    
    /// The function call.
    @available(*, deprecated, message: "This is deprecated due to the new tool calls api of OpenAI")
    public var functionCall: FunctionCall?
    
    /// The tool calls.
    public var toolCalls: [ToolCall]
    
    /// The name of the sender. In case of a function return it is the name of the function.
    public var name: String?
    
    /// If this message is of type tool, this id has to be set.
    public var toolCallId: String?
    
    /// Creates a new message.
    /// - Parameters:
    /// - role: The role of the message.
    /// - content: The content of the message.
    /// - functionCall: The function call.
    /// - name: The name of the sender. In case of a function return it is the name of the function.
    @available(*, deprecated, message: "This is deprecated, use tool call initializer instead.")
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
        
        self.toolCallId = nil
        self.toolCalls = []
        usesDeprecationMode = true
    }
    
    /// Creates a new message.
    /// - Parameters:
    /// - role: The role of the message.
    /// - content: The content of the message.
    /// - toolCalls: The tools to call.
    /// - name: The name of the sender. In case of a function return it is the name of the function.
    public init(
        role: Role,
        content: String?,
        toolCalls: [ToolCall],
        name: String?,
        toolCallId: String?
    ) {
        self.role = role
        self.content = content
        self.toolCalls = toolCalls
        self.name = name
        self.toolCallId = toolCallId
        
        self.functionCall = nil
        usesDeprecationMode = false
    }
    
    /// Creates a new user message.
    /// - Parameter content: The content of the message.
    public static func user(_ content: String) -> Message {
        return Message(role: .user, content: content, toolCalls: [], name: nil, toolCallId: nil)
    }
    
    /// Creates a new system message.
    /// - Parameter content: The content of the message.
    /// - Parameter name: The name of the sender. In case of a function return it is the name of the function.
    public static func system(_ content: String, name: String? = nil) -> Message {
        return Message(role: .system, content: content, toolCalls: [], name: name, toolCallId: nil)
    }
    
    /// Creates a new assistant message.
    /// - Parameter content: The content of the message.
    /// - Parameter functionCall: The function call.
    @available(*, deprecated, message: "Use the version with Tool Call instead.")
    public static func assistant(_ content: String?, functionCall: FunctionCall?) -> Message {
        return Message(role: .assistant, content: content, functionCall: functionCall, name: nil)
    }
    
    /// Creates a new assistant message.
    /// - Parameter content: The content of the message.
    /// - Parameter toolCalls: The toolCalls to call.
    public static func assistant(_ content: String?, toolCalls: [ToolCall]) -> Message {
        return Message(role: .assistant, content: content, toolCalls: toolCalls, name: nil, toolCallId: nil)
    }
    
    /// Creates a new function message.
    /// - Parameter name: The name of the function.
    /// - Parameter result: The result of the function.
    @available(*, deprecated, message: "Use the version with Tool Call instead.")
    public static func function(name: String, result: String) -> Message {
        return Message(role: .function, content: result, toolCalls: [], name: name, toolCallId: nil)
    }
    
    /// Creates a new tool message.
    ///  - Parameter toolCallId: The id of the tool call.
    ///  - Parameter result: The result of the tool call..
    public static func tool(toolCallId: String, result: String) -> Message {
        return Message(role: .tool, content: result, toolCalls: [], name: nil, toolCallId: toolCallId)
    }
}

@available(*, deprecated, message: "This is deprecated due to OpenAIs function depreaction. Use the Tool Call API instead")
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

public class ToolCall: BaseModel, Codable {
    
    public enum ToolType: String, Codable {
        case function
    }
    
    public let type: ToolType
    public let function: Function
    
    public class Function: BaseModel, Codable {
        
        /// The name of the function that is called.
        public let name: String
        
        /// The arguments fo the function passed in json format.
        public let arguments: String
        
        public init(
            name: String,
            arguments: String
        ) {
            self.name = name
            self.arguments = arguments
        }
    }
    
    public init(
        id: String,
        type: ToolType,
        function: Function
    ) {
        self.type = type
        self.function = function
        super.init()
        self.id = id
    }
}
