import XCTest
@testable import GPTConnector

final class GPTConnectorTests: XCTestCase {
    
    var sut: GPTConnector!
    
    override func tearDownWithError() throws {
        sut = nil
    }
    
    func testReturnsChatWithInitialMessage() async throws {
        // given
        let apiConnectorMock = OpenAIConnectorMock { _ in
            return .init(
                choices: [
                    .init(message: .init(
                        role: .assistant,
                        content: "hello!",
                        function_call: nil,
                        tool_calls: [],
                        name: nil,
                        tool_call_id: nil
                    )),
                    .init(message: .init(
                        role: .assistant,
                        content: "hi!",
                        function_call: nil,
                        tool_calls: [],
                        name: nil,
                        tool_call_id: nil
                    ))
                ],
                usage: .init(total_tokens: 100)
            )
        }
        sut = DefaultGPTConnector(apiKey: "test", numberOfChoices: 2, connector: apiConnectorMock)
        
        let initialChat = Chat(
            messages: [
                .system("Test Message")
            ],
            tools: []
        )
        
        // when
        let result = try await sut.chat(context: initialChat)
        
        // then
        XCTAssertEqual(result.messages.count, 2)
        XCTAssertEqual(result.messages[1].content, "hello!")
        XCTAssertEqual(apiConnectorMock.lastNumberOfChoicesCall, 2)
    }
    
    func testApiKeySetLater_shouldWork() async throws {
        // given
        let apiConnectorMock = OpenAIConnectorMock { _ in
            return .init(
                choices: [
                    .init(message: .init(
                        role: .assistant,
                        content: "hello!",
                        function_call: nil,
                        tool_calls: [],
                        name: nil,
                        tool_call_id: nil
                    )),
                    .init(message: .init(
                        role: .assistant,
                        content: "hi!",
                        function_call: nil,
                        tool_calls: [],
                        name: nil,
                        tool_call_id: nil
                    ))
                ],
                usage: .init(total_tokens: 100)
            )
        }
        sut = DefaultGPTConnector(numberOfChoices: 2, connector: apiConnectorMock)
        
        sut.apiKey = "TEST"
        
        let initialChat = Chat(
            messages: [
                .system("Test Message")
            ],
            tools: []
        )
        
        // when
        let result = try await sut.chat(context: initialChat)
        
        // then
        XCTAssertEqual(result.messages.count, 2)
        XCTAssertEqual(result.messages[1].content, "hello!")
        XCTAssertEqual(apiConnectorMock.lastNumberOfChoicesCall, 2)
    }
    
    // MARK: Tool Call Tests:
    
    func testShouldToolsCallWithResult_firstChoice() async throws {
        // given
        var toolCallbackCalledExpectation = expectation(description: "ToolCallbackCalled")
        var numberOfCalls = 0
        let apiConnectorMock = OpenAIConnectorMock { chat in
            defer {
                numberOfCalls += 1
            }
            switch numberOfCalls {
            case 0:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: nil,
                            function_call: nil,
                            tool_calls: [
                                .init(
                                    id: "someId",
                                    type: .function,
                                    function: .init(name: "test_func", arguments: "{}")
                                )
                            ],
                            name: nil,
                            tool_call_id: nil
                        )),
                        .init(message: .init(
                            role: .assistant,
                            content: nil,
                            function_call: .init(name: "test_func2", arguments: "{}"),
                            tool_calls: [
                                .init(
                                    id: "someId2",
                                    type: .function,
                                    function: .init(name: "test_func2", arguments: "{}")
                                )
                            ],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            case 1:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: "function result",
                            function_call: nil,
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            default: throw NSError(domain: "com.example", code: 1, userInfo: nil)
            }

        }
        sut = DefaultGPTConnector(apiKey: "test", connector: apiConnectorMock)
        let inputChat = Chat(messages: [.system("Hello World!")], tools: [])

        let toolCallCallback: ((ToolCall) async throws -> String) = { call in
            XCTAssertEqual(call.id, "someId")
            XCTAssertEqual(call.function.name, "test_func")
            XCTAssertEqual(call.function.arguments, "{}")
            toolCallbackCalledExpectation.fulfill()
            return "function result"
        }

        // when
        let result = try await sut.chat(context: inputChat, onToolCall: toolCallCallback)

        // then
        
        await fulfillment(of: [toolCallbackCalledExpectation])
        
        XCTAssertEqual(result.messages.count, 4)
        XCTAssertEqual(result.messages[3].content, "function result")
    }
    
    func testShouldFunctionCall_noFunctionHandler() async throws {
        // given
        var numberOfCalls = 0
        let apiConnectorMock = OpenAIConnectorMock { chat in
            defer {
                numberOfCalls += 1
            }
            switch numberOfCalls {
            case 0:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: nil,
                            function_call: nil,
                            tool_calls: [
                                .init(
                                    id: "someId",
                                    type: .function,
                                    function: .init(name: "test_func", arguments: "{}")
                                )
                            ],
                            name: nil,
                            tool_call_id: nil
                        )),
                        .init(message: .init(
                            role: .assistant,
                            content: nil,
                            function_call: .init(name: "test_func2", arguments: "{}"),
                            tool_calls: [
                                .init(
                                    id: "someId2",
                                    type: .function,
                                    function: .init(name: "test_func2", arguments: "{}")
                                )
                            ],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            case 1:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: "function result",
                            function_call: nil,
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            default: throw NSError(domain: "com.example", code: 1, userInfo: nil)
            }

        }
        sut = DefaultGPTConnector(apiKey: "test", connector: apiConnectorMock)
        let inputChat = Chat(messages: [.system("Hello World!")], tools: [])

        // when
        do {
            _ = try await sut.chat(context: inputChat)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(error as? GPTConnectorError, .noFunctionHandling)
        }
    }
    
    func testShouldToolCallWithResult_secondChoice() async throws {
        // given
        var numberOfCalls = 0
        let apiConnectorMock = OpenAIConnectorMock { chat in
            defer {
                numberOfCalls += 1
            }
            switch numberOfCalls {
            case 0:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: nil,
                            function_call: nil,
                            tool_calls: [
                                .init(
                                    id: "someId",
                                    type: .function,
                                    function: .init(name: "test_func", arguments: "{}")
                                )
                            ],
                            name: nil,
                            tool_call_id: nil
                        )),
                        .init(message: .init(
                            role: .assistant,
                            content: nil,
                            function_call: nil,
                            tool_calls: [
                                .init(
                                    id: "someId2",
                                    type: .function,
                                    function: .init(name: "test_func2", arguments: "{}")
                                )
                            ],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            case 1:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: "function result",
                            function_call: nil,
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            default: throw NSError(domain: "com.example", code: 1, userInfo: nil)
            }

        }
        sut = DefaultGPTConnector(apiKey: "test", connector: apiConnectorMock)
        let inputChat = Chat(messages: [.system("Hello World!")], tools: [])

        let toolCallCallback: ((ToolCall) async throws -> String) = { call in
            XCTAssertEqual(call.id, "someId2")
            XCTAssertEqual(call.function.name, "test_func2")
            XCTAssertEqual(call.function.arguments, "{}")
            return "function result"
        }
        
        var mrCounter = 0
        let messageReceivedCallback: ([Message], Chat) -> Message = { messages, _ in
            mrCounter += 1
            switch mrCounter {
            case 1: return messages[1]
            default: return messages[0]
            }
        }

        // when
        let result = try await sut.chat(
            context: inputChat,
            onMessagesReceived: messageReceivedCallback,
            onToolCall: toolCallCallback
        )

        // then
        XCTAssertEqual(result.messages.count, 4)
        XCTAssertEqual(result.messages[3].content, "function result")
    }
    
    func testShouldToolCallWithoutResult_choiceNoFunc() async throws {
        // given
        var numberOfCalls = 0
        let apiConnectorMock = OpenAIConnectorMock { chat in
            defer {
                numberOfCalls += 1
            }
            switch numberOfCalls {
            case 0:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: nil,
                            function_call: nil,
                            tool_calls: [
                                .init(
                                    id: "someId",
                                    type: .function,
                                    function: .init(name: "test_func", arguments: "{}")
                                )
                            ],
                            name: nil,
                            tool_call_id: nil
                        )),
                        .init(message: .init(
                            role: .assistant,
                            content: "some test answer",
                            function_call: nil,
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        )),
                        .init(message: .init(
                            role: .assistant,
                            content: "some test answer 1",
                            function_call: nil,
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            case 1:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: "function result",
                            function_call: nil,
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            default: throw NSError(domain: "com.example", code: 1, userInfo: nil)
            }

        }
        sut = DefaultGPTConnector(apiKey: "test", connector: apiConnectorMock)
        let inputChat = Chat(messages: [.system("Hello World!")], tools: [])

        let toolCalback: ((ToolCall) async throws -> String) = { call in
            XCTFail("Should not be called!")
            return ""
        }
        
        var mrCounter = 0
        let messageReceivedCallback: ([Message], Chat) -> Message = { messages, _ in
            mrCounter += 1
            switch mrCounter {
            case 1: return messages[2]
            default: return messages[0]
            }
        }

        // when
        let result = try await sut.chat(
            context: inputChat,
            onMessagesReceived: messageReceivedCallback,
            onToolCall: toolCalback
        )

        // then
        XCTAssertEqual(result.messages.count, 2)
        XCTAssertEqual(result.messages[1].content, "some test answer 1")
    }

    func testShouldMultipleSequentToolCallsWithResult() async throws {
        // given
        var numberOfCalls = 0
        let apiConnectorMock = OpenAIConnectorMock { chat in
            defer {
                numberOfCalls += 1
            }
            switch numberOfCalls {
            case 0:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: nil,
                            function_call: nil,
                            tool_calls: [
                                .init(id: "id1", type: .function, function: .init(name: "test_func", arguments: "{}"))
                            ],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            case 1:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: nil,
                            function_call: nil,
                            tool_calls: [
                                .init(id: "id2", type: .function, function: .init(name: "test_func2", arguments: "{asdf}"))
                            ],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            case 2:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: "function result2",
                            function_call: nil,
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            default: throw NSError(domain: "com.example", code: 1, userInfo: nil)
            }

        }
        sut = DefaultGPTConnector(apiKey: "test", connector: apiConnectorMock)
        let inputChat = Chat(messages: [.system("Hello World!")], tools: [])

        var functionCallbackNumber = 0
        let toolCallback: ((ToolCall) async throws -> String) = { call in
            defer {
                functionCallbackNumber += 1
            }
            switch functionCallbackNumber {
            case 0:
                XCTAssertEqual(call.id, "id1")
                XCTAssertEqual(call.function.name, "test_func")
                XCTAssertEqual(call.function.arguments, "{}")
                return "function result"
            case 1:
                XCTAssertEqual(call.id, "id2")
                XCTAssertEqual(call.function.name, "test_func2")
                XCTAssertEqual(call.function.arguments, "{asdf}")
                return "function result2"
            default: throw NSError(domain: "com.example", code: 1, userInfo: nil)
            }
        }

        // when
        let result = try await sut.chat(context: inputChat, onToolCall: toolCallback)

        // then
        XCTAssertEqual(result.messages.count, 6)
        XCTAssertEqual(result.messages[2].role, .tool)
        XCTAssertEqual(result.messages[2].toolCallId, "id1")
        XCTAssertEqual(result.messages[5].content, "function result2")
    }
    
    func testApiKeyNotSetShouldThrow() async throws {
        // given
        let apiConnectorMock = OpenAIConnectorMock { _ in
            return .init(
                choices: [],
                usage: .init(total_tokens: 100)
            )
        }
        sut = DefaultGPTConnector(numberOfChoices: 2, connector: apiConnectorMock)
        
        let initialChat = Chat(
            messages: [
                .system("Test Message")
            ],
            tools: []
        )
        
        // when
        do {
            _ = try await sut.chat(context: initialChat)
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(error as? GPTConnectorError, GPTConnectorError.apiKeyMissing, "Should throw api key error.")
        }
    }
    
    func testShouldMultipleToolsCallWithResult() async throws {
        // given
        var numberOfCalls = 0
        let apiConnectorMock = OpenAIConnectorMock { chat in
            defer {
                numberOfCalls += 1
            }
            switch numberOfCalls {
            case 0:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: nil,
                            function_call: nil,
                            tool_calls: [
                                .init(
                                    id: "someId",
                                    type: .function,
                                    function: .init(name: "test_func", arguments: "{}")
                                ),
                                .init(
                                    id: "someId2",
                                    type: .function,
                                    function: .init(name: "test_func2", arguments: "{}")
                                )
                            ],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            case 1:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: "Thank You!",
                            function_call: nil,
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            default: throw NSError(domain: "com.example", code: 1, userInfo: nil)
            }

        }
        sut = DefaultGPTConnector(apiKey: "test", connector: apiConnectorMock)
        let inputChat = Chat(messages: [.system("Hello World!")], tools: [])

        var callCount: Int = 0
        let toolCallCallback: ((ToolCall) async throws -> String) = { call in
            defer {
                callCount += 1
            }
            switch callCount {
            case 0:
                XCTAssertEqual(call.id, "someId")
                XCTAssertEqual(call.function.name, "test_func")
                XCTAssertEqual(call.function.arguments, "{}")
                return "function result"
            case 1:
                XCTAssertEqual(call.id, "someId2")
                XCTAssertEqual(call.function.name, "test_func2")
                XCTAssertEqual(call.function.arguments, "{}")
                return "function result2"
            default: 
                throw NSError(domain: "com.example", code: 1, userInfo: nil)
            }
        }

        // when
        let result = try await sut.chat(context: inputChat, onToolCall: toolCallCallback)

        // then
        
        XCTAssertEqual(result.messages.count, 5)
        XCTAssertEqual(result.messages[2].content, "function result")
        XCTAssertEqual(result.messages[2].role, .tool)
        XCTAssertEqual(result.messages[2].toolCallId, "someId")
        XCTAssertEqual(result.messages[3].content, "function result2")
        XCTAssertEqual(result.messages[3].role, .tool)
        XCTAssertEqual(result.messages[3].toolCallId, "someId2")
    }
    
    
    // MARK: Deprecated Function Tests:
    
    func testShouldFunctionCallWithResult_firstChoice() async throws {
        // given
        var numberOfCalls = 0
        let apiConnectorMock = OpenAIConnectorMock { chat in
            defer {
                numberOfCalls += 1
            }
            switch numberOfCalls {
            case 0:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: nil,
                            function_call: .init(name: "test_func", arguments: "{}"),
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        )),
                        .init(message: .init(
                            role: .assistant,
                            content: nil,
                            function_call: .init(name: "test_func2", arguments: "{}"),
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            case 1:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: "function result",
                            function_call: nil,
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            default: throw NSError(domain: "com.example", code: 1, userInfo: nil)
            }

        }
        sut = DefaultGPTConnector(apiKey: "test", connector: apiConnectorMock)
        let inputChat = Chat(messages: [.system("Hello World!")], tools: [])

        let functionCallback: ((String, String) async throws -> String) = { name, arguments in
            XCTAssertEqual(name, "test_func")
            XCTAssertEqual(arguments, "{}")
            return "function result"
        }

        // when
        let result = try await sut.chat(context: inputChat, onFunctionCall: functionCallback)

        // then
        XCTAssertEqual(result.messages.count, 4)
        XCTAssertEqual(result.messages[3].content, "function result")
    }
    
    func testShouldFunctionCallWithResult_secondChoice() async throws {
        // given
        var numberOfCalls = 0
        let apiConnectorMock = OpenAIConnectorMock { chat in
            defer {
                numberOfCalls += 1
            }
            switch numberOfCalls {
            case 0:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: nil,
                            function_call: .init(name: "test_func", arguments: "{}"),
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        )),
                        .init(message: .init(
                            role: .assistant,
                            content: nil,
                            function_call: .init(name: "test_func2", arguments: "{}"),
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            case 1:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: "function result",
                            function_call: nil,
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            default: throw NSError(domain: "com.example", code: 1, userInfo: nil)
            }

        }
        sut = DefaultGPTConnector(apiKey: "test", connector: apiConnectorMock)
        let inputChat = Chat(messages: [.system("Hello World!")], tools: [])

        let functionCallback: ((String, String) async throws -> String) = { name, arguments in
            XCTAssertEqual(name, "test_func2")
            XCTAssertEqual(arguments, "{}")
            return "function result"
        }
        
        var mrCounter = 0
        let messageReceivedCallback: ([Message], Chat) -> Message = { messages, _ in
            mrCounter += 1
            switch mrCounter {
            case 1: return messages[1]
            default: return messages[0]
            }
        }

        // when
        let result = try await sut.chat(
            context: inputChat,
            onMessagesReceived: messageReceivedCallback,
            onFunctionCall: functionCallback
        )

        // then
        XCTAssertEqual(result.messages.count, 4)
        XCTAssertEqual(result.messages[3].content, "function result")
    }
    
    func testShouldFunctionCallWithoutResult_choiceNoFunc() async throws {
        // given
        var numberOfCalls = 0
        let apiConnectorMock = OpenAIConnectorMock { chat in
            defer {
                numberOfCalls += 1
            }
            switch numberOfCalls {
            case 0:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: nil,
                            function_call: .init(name: "test_func", arguments: "{}"),
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        )),
                        .init(message: .init(
                            role: .assistant,
                            content: "some test answer",
                            function_call: nil,
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        )),
                        .init(message: .init(
                            role: .assistant,
                            content: "some test answer 1",
                            function_call: nil,
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            case 1:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: "function result",
                            function_call: nil,
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            default: throw NSError(domain: "com.example", code: 1, userInfo: nil)
            }

        }
        sut = DefaultGPTConnector(apiKey: "test", connector: apiConnectorMock)
        let inputChat = Chat(messages: [.system("Hello World!")], tools: [])

        let functionCallback: ((String, String) async throws -> String) = { name, arguments in
            XCTAssertEqual(name, "test_func2")
            XCTAssertEqual(arguments, "{}")
            return "function result"
        }
        
        var mrCounter = 0
        let messageReceivedCallback: ([Message], Chat) -> Message = { messages, _ in
            mrCounter += 1
            switch mrCounter {
            case 1: return messages[2]
            default: return messages[0]
            }
        }

        // when
        let result = try await sut.chat(
            context: inputChat,
            onMessagesReceived: messageReceivedCallback,
            onFunctionCall: functionCallback
        )

        // then
        XCTAssertEqual(result.messages.count, 2)
        XCTAssertEqual(result.messages[1].content, "some test answer 1")
    }
    
    func testShouldMultipleFunctionCallWithResult() async throws {
        // given
        var numberOfCalls = 0
        let apiConnectorMock = OpenAIConnectorMock { chat in
            defer {
                numberOfCalls += 1
            }
            switch numberOfCalls {
            case 0:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: nil,
                            function_call: .init(name: "test_func", arguments: "{}"),
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            case 1:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: nil,
                            function_call: .init(name: "test_func2", arguments: "{asdf}"),
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            case 2:
                return .init(
                    choices: [
                        .init(message: .init(
                            role: .assistant,
                            content: "function result2",
                            function_call: nil,
                            tool_calls: [],
                            name: nil,
                            tool_call_id: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            default: throw NSError(domain: "com.example", code: 1, userInfo: nil)
            }

        }
        sut = DefaultGPTConnector(apiKey: "test", connector: apiConnectorMock)
        let inputChat = Chat(messages: [.system("Hello World!")], tools: [])

        var functionCallbackNumber = 0
        let functionCallback: ((String, String) async throws -> String) = { name, arguments in
            defer {
                functionCallbackNumber += 1
            }
            switch functionCallbackNumber {
            case 0:
                XCTAssertEqual(name, "test_func")
                XCTAssertEqual(arguments, "{}")
                return "function result"
            case 1:
                XCTAssertEqual(name, "test_func2")
                XCTAssertEqual(arguments, "{asdf}")
                return "function result2"
            default: throw NSError(domain: "com.example", code: 1, userInfo: nil)
            }
        }

        // when
        let result = try await sut.chat(context: inputChat, onFunctionCall: functionCallback)

        // then
        XCTAssertEqual(result.messages.count, 6)
        XCTAssertEqual(result.messages[5].content, "function result2")
    }
}

