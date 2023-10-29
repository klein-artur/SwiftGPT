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
                        name: nil
                    )),
                    .init(message: .init(
                        role: .assistant,
                        content: "hi!",
                        function_call: nil,
                        name: nil
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
            functions: [
                Function(
                    name: "some_function",
                    description: "The description for the model.",
                    parameters: [
                        Function.Property(
                            name: "property_name",
                            type: .boolean,
                            description: "The description of the parameter.",
                            required: true
                        ),
                        Function.Property(
                            name: "property_name",
                            type: .integer,
                            description: "The description of the parameter.",
                            required: false
                        ),
                        Function.Property(
                            name: "property_name",
                            type: .string,
                            description: "The description of the parameter.",
                            required: true
                        )
                    ]
                )
            ]
        )
        
        // when
        let result = try await sut.chat(context: initialChat)
        
        // then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].messages.count, 2)
        XCTAssertEqual(result[0].messages[1].content, "hello!")
        XCTAssertEqual(result[1].messages[1].content, "hi!")
        XCTAssertEqual(apiConnectorMock.lastNumberOfChoicesCall, 2)
    }
    
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
                            name: nil
                        )),
                        .init(message: .init(
                            role: .assistant,
                            content: nil,
                            function_call: .init(name: "test_func2", arguments: "{}"),
                            name: nil
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
                            name: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            default: throw NSError(domain: "com.example", code: 1, userInfo: nil)
            }

        }
        sut = DefaultGPTConnector(apiKey: "test", connector: apiConnectorMock)
        let inputChat = Chat(messages: [.system("Hello World!")])

        let functionCallback: ((String, String) async throws -> String) = { name, arguments in
            XCTAssertEqual(name, "test_func")
            XCTAssertEqual(arguments, "{}")
            return "function result"
        }

        // when
        let result = try await sut.chat(context: inputChat, onFunctionCall: functionCallback)

        // then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].messages.count, 4)
        XCTAssertEqual(result[0].messages[3].content, "function result")
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
                            function_call: .init(name: "test_func", arguments: "{}"),
                            name: nil
                        )),
                        .init(message: .init(
                            role: .assistant,
                            content: nil,
                            function_call: .init(name: "test_func2", arguments: "{}"),
                            name: nil
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
                            name: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            default: throw NSError(domain: "com.example", code: 1, userInfo: nil)
            }

        }
        sut = DefaultGPTConnector(apiKey: "test", connector: apiConnectorMock)
        let inputChat = Chat(messages: [.system("Hello World!")])

        // when
        do {
            _ = try await sut.chat(context: inputChat)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(error as? GPTConnectorError, .noFunctionHandling)
        }
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
                            name: nil
                        )),
                        .init(message: .init(
                            role: .assistant,
                            content: nil,
                            function_call: .init(name: "test_func2", arguments: "{}"),
                            name: nil
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
                            name: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            default: throw NSError(domain: "com.example", code: 1, userInfo: nil)
            }

        }
        sut = DefaultGPTConnector(apiKey: "test", connector: apiConnectorMock)
        let inputChat = Chat(messages: [.system("Hello World!")])

        let functionCallback: ((String, String) async throws -> String) = { name, arguments in
            XCTAssertEqual(name, "test_func2")
            XCTAssertEqual(arguments, "{}")
            return "function result"
        }

        // when
        let result = try await sut.chat(
            context: inputChat,
            onChoiceSelect: { messages, _ in messages[1] },
            onFunctionCall: functionCallback
        )

        // then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].messages.count, 4)
        XCTAssertEqual(result[0].messages[3].content, "function result")
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
                            name: nil
                        )),
                        .init(message: .init(
                            role: .assistant,
                            content: "some test answer",
                            function_call: nil,
                            name: nil
                        )),
                        .init(message: .init(
                            role: .assistant,
                            content: "some test answer 1",
                            function_call: nil,
                            name: nil
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
                            name: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            default: throw NSError(domain: "com.example", code: 1, userInfo: nil)
            }

        }
        sut = DefaultGPTConnector(apiKey: "test", connector: apiConnectorMock)
        let inputChat = Chat(messages: [.system("Hello World!")])

        let functionCallback: ((String, String) async throws -> String) = { name, arguments in
            XCTAssertEqual(name, "test_func2")
            XCTAssertEqual(arguments, "{}")
            return "function result"
        }

        // when
        let result = try await sut.chat(
            context: inputChat,
            onChoiceSelect: { messages, _ in messages[2] },
            onFunctionCall: functionCallback
        )

        // then
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[2].messages.count, 2)
        XCTAssertEqual(result[2].messages[1].content, "some test answer 1")
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
                            name: nil
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
                            name: nil
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
                            name: nil
                        ))
                    ],
                    usage: .init(total_tokens: 100)
                )
            default: throw NSError(domain: "com.example", code: 1, userInfo: nil)
            }

        }
        sut = DefaultGPTConnector(apiKey: "test", connector: apiConnectorMock)
        let inputChat = Chat(messages: [.system("Hello World!")])

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
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].messages.count, 6)
        XCTAssertEqual(result[0].messages[5].content, "function result2")
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
            ]
        )
        
        // when
        do {
            _ = try await sut.chat(context: initialChat)
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(error as? GPTConnectorError, GPTConnectorError.apiKeyMissing, "Should throw api key error.")
        }
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
                        name: nil
                    )),
                    .init(message: .init(
                        role: .assistant,
                        content: "hi!",
                        function_call: nil,
                        name: nil
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
            ]
        )
        
        // when
        let result = try await sut.chat(context: initialChat)
        
        // then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].messages.count, 2)
        XCTAssertEqual(result[0].messages[1].content, "hello!")
        XCTAssertEqual(result[1].messages[1].content, "hi!")
        XCTAssertEqual(apiConnectorMock.lastNumberOfChoicesCall, 2)
    }
    
}

