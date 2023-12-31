//
//  File.swift
//  
//
//  Created by Artur Hellmann on 26.10.23.
//

@testable import GPTConnector

import Foundation

class OpenAIConnectorMock: OpenAIApiConnector {
    let doOnSend: (OpenAIApiConnector.ChatData) async throws -> OpenAIApiConnector.ChatResult
    
    var lastSendChatData: ChatData? = nil
    var lastNumberOfChoicesCall: Int? = nil
    
    init(doOnSend: @escaping (OpenAIApiConnector.ChatData) async throws -> OpenAIApiConnector.ChatResult) {
        self.doOnSend = doOnSend
        super.init(apiKey: "", session: URLSession.shared)
    }
    
    override func send(chatData: OpenAIApiConnector.ChatData, numberOfChoices: Int) async throws -> OpenAIApiConnector.ChatResult {
        self.lastSendChatData = chatData
        self.lastNumberOfChoicesCall = numberOfChoices
        return try await doOnSend(chatData)
    }
}
