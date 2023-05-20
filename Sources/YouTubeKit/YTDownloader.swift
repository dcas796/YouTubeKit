//
//  YTDownloader.swift
//
//
//  Created by Dani on 3/5/23.
//

import Foundation


public struct YTDownloader {
    private var extractor: YTExtractor
    private var downloader: YTDownloaderImpl
    private var operationQueue: OperationQueue = OperationQueue()
    
    private(set) var options: YTOptions
    
    public init() {
        self.init(options: YTOptions())
    }
    
    public init(options: YTOptions) {
        self.options = options
        switch options.extractor {
        case .`default`:
            self.extractor = YTDefaultExtractor()
        case .legacy:
            self.extractor = YTLegacyExtractor()
        }
        self.downloader = YTDownloaderImpl(downloaderOption: options.downloader)
    }
    
    public func video(for videoURL: URL) async throws -> YTVideo {
        try await extractor.video(for: videoURL)
    }
    
    public func bestFormat(for video: YTVideo, quality: YTVideoFormat.Quality, fileFormat: YTFileFormat? = nil) -> YTVideoFormat? {
        let fileFormat = fileFormat ?? .mp4
        return video.formats.first(where: {
            $0.quality == quality && $0.mimeType.subtype == fileFormat.rawValue
        })
    }
    
    public mutating func download(
        video: YTVideo,
        format: YTVideoFormat,
        outputURL: URL,
        updateHandler: @escaping (YTVideo, Progress) -> Void = {_,_ in}
    ) async throws {
        try await downloader.download(video: video,
                                      format: format,
                                      outputURL: outputURL,
                                      updateHandler: updateHandler)
    }
}

extension YTDownloader: Cancellable {
    public mutating func cancel() throws {
        try downloader.currentCancellable?.cancel()
    }
}
