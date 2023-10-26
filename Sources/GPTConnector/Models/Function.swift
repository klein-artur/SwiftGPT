//
//  Function.swift
//  
//
//  Created by Artur Hellmann on 26.10.23.
//

import Foundation

public class Function: BaseModel, Codable {
    
    public var name: String
    public var description: String
    public var type: String = "object"
    public var parameters: [Property]
    
    public init(
        id: String? = nil,
        name: String,
        description: String,
        type: String = "object",
        parameters: [Property]
    ) {
        self.name = name
        self.description = description
        self.type = type
        self.parameters = parameters
        super.init()
        if let id {
            self.id = id
        }
    }
    
    public class Property: BaseModel, Codable {
        
        public enum ParamType: String, CaseIterable, Codable {
            case string
            case boolean
            case integer
        }
        
        public var name: String
        public var type: ParamType
        public var description: String
        public var required: Bool
        
        public init(
            id: String? = nil,
            name: String,
            type: ParamType,
            description: String,
            required: Bool
        ) {
            self.name = name
            self.type = type
            self.description = description
            self.required = required
            super.init()
            if let id {
                self.id = id
            }
        }
    }
    
}
