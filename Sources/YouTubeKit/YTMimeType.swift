//
//  YTMimeType.swift
//  
//
//  Created by Dani on 4/5/23.
//

import Foundation

public struct YTMimeType: Equatable, Hashable {
    private static let mimeTypeRegex: Regex = #/(.+)\/([^;]+)(;.+)?/#
    private static let mimeTypeParametersRegex: Regex = #/; *([^;]+)=([^;]+)/#
    
    public var type: String
    public var subtype: String
    public var parameters: [String : String] = [:]
    
    public init?(string: String) {
        guard let match = try? Self.mimeTypeRegex.firstMatch(in: string) else {
            return nil
        }
        let (_, type, subtype, parameters) = match.output
        self.type = String(type)
        self.subtype = String(subtype)
        if let parameters {
            let parameterArray = String(parameters).matches(of: Self.mimeTypeParametersRegex).map { (String($0.output.1), String($0.output.2)) }
            self.parameters = Dictionary(uniqueKeysWithValues: parameterArray)
        }
    }
}

extension YTMimeType: CustomStringConvertible {
    public var description: String {
        var description = "\(type)/\(subtype)"
        for (parameter, value) in parameters {
            description.append(";\(parameter)=\(value)")
        }
        return description
    }
}

extension YTMimeType: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let mimeTypeString = try container.decode(String.self)
        guard let this = Self.init(string: mimeTypeString) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Failed to parse mime type"))
        }
        self = this
    }
}
