//
//  Tool.swift
//
//
//  Created by Artur Hellmann on 12.11.23.
//

import Foundation

public class Tool: BaseModel {
    public enum ToolType: String {
        case function
    }
    
    public let type: ToolType
    public let function: Function
    
    init(type: ToolType = .function, function: Function) {
        self.type = type
        self.function = function
    }
}
