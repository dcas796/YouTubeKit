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
        formats.map { $0.quality }
    }
}
