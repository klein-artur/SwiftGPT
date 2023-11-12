//
//  Mappers.swift
//  
//
//  Created by Artur Hellmann on 26.10.23.
//

import Foundation

// MARK: Chat <-> ChatData

extension Chat {
    var chatData: OpenAIApiConnector.ChatData {
        let functionCall: String?
        switch self.functionCall {
        case .none:
            functionCall = "none"
        case .auto:
            functionCall = nil
        case let .forced(name):
            functionCall = "{\"name\": \"\(name)\"}"
        }
        
        let toolChoice: String?
        switch self.toolChoice {
        case .none:
            toolChoice = "none"
        case .auto:
            toolChoice = nil
        case let .forced(name):
            toolChoice = "{\"type: \"function\", \"function\": {\"name\": \"\(name)\"}}"
        }
        return .init(
            model: self.model,
            temperature: self.temperature,
            messages: messages.messageDatas,
            functions: functions.isEmpty ? nil : functions.functionDatas,
            function_call: functionCall,
            tools: tools.isEmpty ? nil : tools.toolDatas,
            tool_choice: toolChoice
        )
    }
}

extension OpenAIApiConnector.ChatData {
    var chat: Chat {
        let isUsingDeprecatedMode = self.functions != nil && self.functions?.isEmpty != true
        
        if isUsingDeprecatedMode {
            return .init(
                model: self.model,
                messages: self.messages.messages,
                temperature: self.temperature,
                functions: self.functions?.functions ?? []
            )
        } else {
            return .init(
                model: self.model,
                messages: self.messages.messages,
                temperature: self.temperature,
                tools: self.tools?.tools ?? []
            )
        }
    }
}

// MARK: Message <-> MessageData

extension Message {
    var messageData: OpenAIApiConnector.ChatData.MessageData {
        .init(
            role: self.role,
            content: self.content,
            function_call: self.functionCall?.functionCallData,
            tool_calls: self.toolCalls.toolCallDatas.isEmpty ? nil : self.toolCalls.toolCallDatas,
            name: self.name,
            tool_call_id: self.toolCallId
        )
    }
}

extension Array where Element == Message {
    var messageDatas: [OpenAIApiConnector.ChatData.MessageData] {
        self.map { $0.messageData }
    }
}

extension OpenAIApiConnector.ChatData.MessageData {
    var message: Message {
        let usesDeprecationMode: Bool = self.function_call != nil
        
        if usesDeprecationMode {
            return .init(
                role: self.role,
                content: self.content,
                functionCall: self.function_call?.functionCall,
                name: self.name
            )
        } else {
            return .init(
                role: self.role,
                content: self.content,
                toolCalls: self.tool_calls?.toolCalls ?? [],
                name: self.name,
                toolCallId: self.tool_call_id
            )
        }
    }
}

extension Array where Element == OpenAIApiConnector.ChatData.MessageData {
    var messages: [Message] {
        self.map { $0.message }
    }
}

// MARK: Function <-> FunctionData

extension FunctionCall {
    var functionCallData: OpenAIApiConnector.ChatData.MessageData.FunctionCall {
        .init(
            name: self.name,
            arguments: self.arguments
        )
    }
}

extension OpenAIApiConnector.ChatData.MessageData.FunctionCall {
    var functionCall: FunctionCall {
        .init(
            name: self.name,
            arguments: self.arguments
        )
    }
}

extension Function {
    var functionData: OpenAIApiConnector.ChatData.Function {
        let parameters: [String: OpenAIApiConnector.ChatData.Function.Parameters.Property] = self.parameters.reduce(
            into: [String: OpenAIApiConnector.ChatData.Function.Parameters.Property]()) { partialResult, property in
                partialResult[property.name] = OpenAIApiConnector.ChatData.Function.Parameters.Property(
                    type: property.type.rawValue,
                    description: property.description
                )
            }
        return OpenAIApiConnector.ChatData.Function(
            name: self.name,
            description: self.description,
            parameters: OpenAIApiConnector.ChatData.Function.Parameters(
                type: self.type,
                properties: parameters,
                required: self.parameters.filter({ $0.required }).map({ $0.name })
            )
        )
    }
}

extension OpenAIApiConnector.ChatData.Function {
    var function: Function {
        let parameters: [Function.Property] = self.parameters.properties.map { property in
            .init(
                name: property.key,
                type: Function.Property.ParamType(rawValue: property.value.type)!,
                description: property.value.description,
                required: self.parameters.required.contains(property.key)
            )
        }
        return Function(
            name: self.name,
            description: self.description,
            type: self.parameters.type,
            parameters: parameters
        )
    }
}

extension Array where Element == Function {
    var functionDatas: [OpenAIApiConnector.ChatData.Function] {
        self.map { $0.functionData }
    }
}

extension Array where Element == OpenAIApiConnector.ChatData.Function {
    var functions: [Function] {
        self.map { $0.function }
    }
}

// MARK: Tools <-> Tools Data

extension Tool {
    var toolData: OpenAIApiConnector.ChatData.Tool {
        .init(
            type: OpenAIApiConnector.ChatData.Tool.ToolType(rawValue: self.type.rawValue)!,
            function: self.function.functionData
        )
    }
}

extension Array where Element == Tool {
    var toolDatas: [OpenAIApiConnector.ChatData.Tool] {
        self.map { $0.toolData }
    }
}

extension OpenAIApiConnector.ChatData.Tool {
    var tool: Tool {
        .init(type: Tool.ToolType(rawValue: self.type.rawValue)!, function: self.function.function)
    }
}

extension Array where Element == OpenAIApiConnector.ChatData.Tool {
    var tools: [Tool] {
        map { $0.tool }
    }
}

extension ToolCall {
    var toolCallData: OpenAIApiConnector.ChatData.MessageData.ToolCall {
        .init(
            id: self.id,
            type: OpenAIApiConnector.ChatData.Tool.ToolType.init(rawValue: self.type.rawValue)!,
            function: OpenAIApiConnector.ChatData.MessageData.ToolCall.Function(name: self.function.name, arguments: self.function.arguments)
        )
    }
}

extension Array where Element == ToolCall {
    var toolCallDatas: [OpenAIApiConnector.ChatData.MessageData.ToolCall] {
        map { $0.toolCallData }
    }
}

extension OpenAIApiConnector.ChatData.MessageData.ToolCall {
    var toolCall: ToolCall {
        .init(
            id: self.id,
            type: ToolCall.ToolType(rawValue: self.type.rawValue)!,
            function: ToolCall.Function(name: self.function.name, arguments: self.function.arguments)
        )
    }
}

extension Array where Element == OpenAIApiConnector.ChatData.MessageData.ToolCall {
    var toolCalls: [ToolCall] {
        map { $0.toolCall }
    }
}
