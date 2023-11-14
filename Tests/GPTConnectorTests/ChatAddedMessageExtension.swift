//
//  ChatAddedMessageExtension.swift
//  
//
//  Created by Artur Hellmann on 14.11.23.
//

import XCTest
@testable import GPTConnector

final class ChatAddedMessageExtension: XCTestCase {

    func testAddingMessageDeprecationMode() throws {
        // given
        let sut = Chat(
            model: "some",
            messages: [.system("test")],
            temperature: 0.111,
            functions: [
                Function(name: "Test", description: "Test", parameters: [])
            ],
            functionCall: .forced(name: "test")
        )
        
        // when
        let result = sut.byAddingMessage(.user("test"))
        
        // then
        XCTAssertEqual(result.model, "some")
        XCTAssertEqual(result.temperature, 0.111)
        XCTAssertEqual(result.messages.count, 2)
        XCTAssertEqual(result.messages[1].role, .user)
        XCTAssertEqual(result.functions.count, 1)
        XCTAssertEqual(result.functionCall, .forced(name: "test"))
    }
    
    func testAddingMessage() throws {
        // given
        let sut = Chat(
            model: "some",
            messages: [.system("test")],
            temperature: 0.111,
            tools: [
                Tool(function: Function(name: "Test", description: "Test", parameters: []))
            ],
            toolChoice: .forced(name: "test")
        )
        
        // when
        let result = sut.byAddingMessage(.user("test"))
        
        // then
        XCTAssertEqual(result.model, "some")
        XCTAssertEqual(result.temperature, 0.111)
        XCTAssertEqual(result.messages.count, 2)
        XCTAssertEqual(result.messages[1].role, .user)
        XCTAssertEqual(result.tools.count, 1)
        XCTAssertEqual(result.toolChoice, .forced(name: "test"))
    }

}
