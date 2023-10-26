//
//  BaseModel.swift
//  
//
//  Created by Artur Hellmann on 26.10.23.
//

import Foundation

public protocol Datable {
    var createdAt: Date { get set }
    var updatedAt: Date? { get set }
}

public class BaseModel: Identifiable, Datable {
    public var id: String = UUID().uuidString
    
    public var createdAt: Date = .now
    public var updatedAt: Date?
}
