//
//  YTDownloader.swift
//
//
//  Created by Dani on 3/5/23.
//

import Foundation


public struct YTDownloader {
    private var extractor: YTExtractor = YTExtractor()
    private var downloader: YTDownloaderImpl = YTDownloaderImpl()
    private var operationQueue: OperationQueue = OperationQueue()
    
    public init() {}
    
    public func video(for videoURL: URL) async throws -> YTVideo {
        try await extractor.video(for: videoURL)
    }
    
    public func download(
        video: YTVideo,
        quality: YTVideoFormat.Quality,
        fileFormat: YTFileFormat? = nil,
        outputURL: URL,
        updateHandler: @escaping (YTVideo, Progress) -> Void = {_,_ in}
    ) async throws {
        try await downloader.download(video: video,
                                      quality: quality,
                                      fileFormat: fileFormat ?? .mp4,
                                      outputURL: outputURL,
                                      updateHandler: updateHandler)
    }
}
