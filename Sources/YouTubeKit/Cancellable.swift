//
//  Cancellable.swift
//  
//
//  Created by Dani on 16/5/23.
//

import Foundation

public protocol Cancellable {
    mutating func cancel() throws
}

extension URLSessionTask: Cancellable {}
