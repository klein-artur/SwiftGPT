//
//  OpenAIApiConnectorTests.swift
//  
//
//  Created by Artur Hellmann on 26.10.23.
//

@testable import GPTConnector

import XCTest

final class OpenAIApiConnectorTests: XCTestCase {
    
    var sut: OpenAIApiConnector!
    
    override func tearDownWithError() throws {
        sut = nil
    }

}
