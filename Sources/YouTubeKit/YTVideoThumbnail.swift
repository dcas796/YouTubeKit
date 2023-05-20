//
//  YTVideoThumbnail.swift
//  
//
//  Created by Dani on 14/5/23.
//

import Foundation

public struct YTVideoThumbnail: Equatable, Hashable, Decodable {
    public var url: URL
    public var width: Int
    public var height: Int
}

extension Sequence where Element == YTVideoThumbnail {
    public var maxResolution: YTVideoThumbnail? {
        self.max { ($0.width * $0.height) < ($1.width * $1.height) }
    }
}
