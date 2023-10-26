//
//  URLSession.swift
//  
//
//  Created by Artur Hellmann on 26.10.23.
//

import Foundation

class MockURLProtocol: URLProtocol {

    static var stub: (Data?, HTTPURLResponse?)?

    override class func canInit(with task: URLSessionTask) -> Bool {
        return true
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        defer {
            client?.urlProtocolDidFinishLoading(self)
        }

        if let (data, response) = Self.stub {
            client?.urlProtocol(self, didLoad: data ?? Data())
            client?.urlProtocol(self, didReceive: response ?? HTTPURLResponse(), cacheStoragePolicy: .allowed)
        } else {
            client?.urlProtocol(self, didFailWithError: URLError(.networkConnectionLost))
        }
    }

    override func stopLoading() {}
}

func mockedURLSession(withStub stub: (Data?, HTTPURLResponse?)) -> URLSession {
    MockURLProtocol.stub = stub
    _ = URLProtocol.registerClass(MockURLProtocol.self)
    let mockConfig = URLSessionConfiguration.default
    mockConfig.protocolClasses?.insert(MockURLProtocol.self, at: 0)

    return URLSession(configuration: mockConfig)
}

