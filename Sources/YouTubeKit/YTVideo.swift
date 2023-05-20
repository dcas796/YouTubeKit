//
//  YTVideo.swift
//  
//
//  Created by Dani on 4/5/23.
//

import Foundation

public struct YTVideo: Equatable, Hashable {
    public var details: YTVideoDetails
    public var formats: [YTVideoFormat]
    
    public var availableQualities: [YTVideoFormat.Quality] {
        Array(Set(formats.map { $0.quality })).sorted().reversed()
    }
    
    public var availableFormats: [YTFileFormat] {
        Array(Set(formats.compactMap { YTFileFormat(rawValue: $0.mimeType.subtype) })).sorted().reversed()
    }
}
