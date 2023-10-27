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
        return .init(
            model: self.model,
            temperature: self.temperature,
            messages: messages.messageDatas,
            functions: functions.isEmpty ? nil : functions.functionDatas,
            function_call: functionCall
        )
    }
}

extension OpenAIApiConnector.ChatData {
    var chat: Chat {
        .init(
            model: self.model,
            messages: self.messages.messages,
            temperature: self.temperature,
            functions: self.functions?.functions ?? []
        )
    }
}

// MARK: Message <-> MessageData

extension Message {
    var messageData: OpenAIApiConnector.ChatData.MessageData {
        .init(
            role: self.role,
            content: self.content,
            function_call: self.functionCall?.functionCallData,
            name: self.name
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
        .init(
            role: self.role,
            content: self.content,
            functionCall: self.function_call?.functionCall,
            name: self.name
        )
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
