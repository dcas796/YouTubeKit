//
//  YTFileFormat.swift
//  
//
//  Created by Dani on 4/5/23.
//

import Foundation

public enum YTFileFormat: String, Equatable, Hashable {
    case mp4
    case webm
}

// This is just to make Array's ordered
extension YTFileFormat: Comparable {
    public static func < (lhs: YTFileFormat, rhs: YTFileFormat) -> Bool {
        switch (lhs, rhs) {
        case (.mp4, .mp4),
             (.webm, .webm),
             (.mp4, .webm):
            return false
        case (.webm, .mp4):
            return true
        }
    }
}
