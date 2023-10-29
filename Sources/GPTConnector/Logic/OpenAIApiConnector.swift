//
//  OpenAIApiConnector.swift
//  
//
//  Created by Artur Hellmann on 26.10.23.
//

import Foundation

class OpenAIApiConnector {
    
    enum OpenAIApiConnectorError: Error {
        case apiKeyMissing
    }
    
    struct ChatResult: Codable {
        let choices: [
            Choice
        ]
        let usage: Usage
        
        
        struct Choice: Codable {
            let message: ChatData.MessageData
        }
        
        struct Usage: Codable {
            let total_tokens: Int
        }
        
    }
    
    struct ChatData: Codable {
        let model: String
        let temperature: Float
        let messages: [MessageData]
        let functions: [Function]?
        let function_call: String?
        
        struct MessageData: Codable {
            
            enum CodingKeys: String, CodingKey {
                case role
                case content
                case function_call
                case name
            }
            
            let role: Message.Role
            let content: String?
            let function_call: FunctionCall?
            let name: String?
            
            struct FunctionCall: Codable {
                let name: String
                let arguments: String
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)

                try container.encode(role, forKey: .role)

                if let content = content {
                    try container.encode(content, forKey: .content)
                } else {
                    try container.encodeNil(forKey: .content)
                }
                
                if let name = name {
                    try container.encode(name, forKey: .name)
                }

                if let functionCall = function_call {
                    try container.encode(functionCall, forKey: .function_call)
                }
            }
        }
        
        struct Function: Codable {
            let name: String
            let description: String
            let parameters: Parameters
            
            struct Parameters: Codable {
                let type: String
                let properties: [String: Property]
                let required: [String]
                
                struct Property: Codable {
                    let type: String
                    let description: String
                }
            }
        }
    }
    
    var apiKey: String?
    private let baseUrl: String = "https://api.openai.com/v1/chat/completions"
    
    private var session: URLSession
    
    init(apiKey: String?, session: URLSession) {
        self.apiKey = apiKey
        self.session = session
    }
    
    public func send(chatData: ChatData, numberOfChoices: Int) async throws -> ChatResult {
        guard let apiKey else {
            throw OpenAIApiConnectorError.apiKeyMissing
        }
        
        let url = URL(string: baseUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        
        let jsonData = try encoder.encode(chatData)
        
        if var jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [String: Any] {
            
            jsonDict["n"] = numberOfChoices
            
            let newJsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
            request.httpBody = newJsonData
        }
        
        
        let (data, _) = try await session.data(for: request)
        
        let decoder = JSONDecoder()
        let chatResult = try decoder.decode(ChatResult.self, from: data)
        
        return chatResult
    }
}
