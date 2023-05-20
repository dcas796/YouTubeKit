//
//  YTOptions.swift
//  
//
//  Created by Dani on 13/5/23.
//

import Foundation

public struct YTOptions: Equatable, Hashable {
    public var extractor: ExtractorOption = .default
    public var downloader: DownloaderOption = .chunked
    
    public init() {}
}

extension YTOptions {
    public enum ExtractorOption {
        case `default`
        case legacy
    }
    
    public enum DownloaderOption {
        case chunked
        case unthrottle
    }
}
