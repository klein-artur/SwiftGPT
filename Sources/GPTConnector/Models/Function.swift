//
//  Function.swift
//  
//
//  Created by Artur Hellmann on 26.10.23.
//

import Foundation

public class Function: BaseModel, Codable {
    
    /// The name of the function
    public var name: String
    
    /// The description of the function provided to the model.
    public var description: String
    
    /// The type of the function. Default is object.
    public var type: String = "object"
    
    /// The parameters of the function.
    public var parameters: [Property]
    
    /// Creates a new function.
    /// - Parameters:
    /// - name: The name of the function
    /// - description: The description of the function provided to the model.
    /// - type: The type of the function. Default is object.
    /// - parameters: The parameters of the function.
    /// - id: The id of the function. If not provided, it will be generated.
    /// - Returns: A new function.
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
        
        /// The name of the parameter.
        public var name: String
        
        /// The type of the parameter.
        public var type: ParamType
        
        /// The description of the parameter.
        public var description: String
        
        /// If the parameter is required.
        public var required: Bool
        
        /// Creates a new parameter.
        /// - Parameters:
        /// - name: The name of the parameter.
        /// - type: The type of the parameter.
        /// - description: The description of the parameter.
        /// - required: If the parameter is required.
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
