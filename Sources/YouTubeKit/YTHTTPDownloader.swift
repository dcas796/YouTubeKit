//
//  YTHTTPDownloader.swift
//  
//
//  Created by Dani on 14/5/23.
//

import Foundation

struct YTHTTPDownloader {
    private(set) var request: URLRequest
    private(set) var expectedSize: Int64
    private(set) var chunkSize: Int64
    var maxRetries: Int = 3
    
    private var isDownloadCancelled: Bool = false
    
    init(url: URL, chunkSize: Int64? = nil) async throws {
        try await self.init(request: URLRequest(url: url), chunkSize: chunkSize)
    }
    
    init(request: URLRequest, chunkSize: Int64? = nil) async throws {
        self.request = request
        self.expectedSize = try await Self.contentLength(for: request)
        self.chunkSize = Self.bestChunkSize(for: expectedSize, preferred: chunkSize)
    }
    
    static private func contentLength(for request: URLRequest) async throws -> Int64 {
        try await YTError.asyncWrapper {
            var headRequest = request
            headRequest.httpMethod = "HEAD"
            let (_, response) = try await URLSession.shared.data(for: headRequest)
            guard response.expectedContentLength > 0 else {
                throw YTError.downloadError(context: YTError.Context(message: "Couldn't get remote resource size"))
            }
            return response.expectedContentLength
        }
    }
    
    static private func bestChunkSize(for contentLength: Int64, preferred preferredChunkSize: Int64?) -> Int64 {
        var chunkSize = preferredChunkSize ?? (1000 * 1000) /* 1MB */
        
        if chunkSize <= 0 || chunkSize > contentLength {
            chunkSize = contentLength
        }
        
        return chunkSize
    }
    
    
    mutating func download(to outputURL: URL, updateHandler: @escaping (Self, Progress) -> Void) async throws {
        guard !FileManager.default.fileExists(atPath: outputURL.path()) else {
            throw YTError.downloadError(context: YTError.Context(message: "File at '\(outputURL.path())' already exists"))
        }
        
        log("Downloading '\(request.url?.absoluteString ?? "unknown")' to '\(outputURL.path())'")
        log("Expected size: \(expectedSize) bytes")
        let partFile = try createPartFile(for: outputURL)
        log("Creating part file: \(partFile.path())")
        
        var remainingBytes = expectedSize
        var retryCount = 0
        
        while remainingBytes > 0 && retryCount < maxRetries {
            guard !isDownloadCancelled else {
                isDownloadCancelled = false
                throw YTError.downloadCancelled()
            }
            
            let completed = expectedSize - remainingBytes
            updateHandler(self, progress(completedCount: completed))
            let nextChunkSize = min(chunkSize, remainingBytes)
            
            var request = request
            addRangeHeader(for: &request, start: completed, end: completed + chunkSize)
            let (data, _) = try await URLSession.shared.data(for: request)
            guard Int64(data.count) == nextChunkSize else {
                log("Mismatched header range and response bytes. Retrying...")
                retryCount += 1
                try await Task.sleep(nanoseconds: 1_000_000_000)
                continue
            }
            try append(to: partFile, data: data)
            
            remainingBytes -= nextChunkSize
            retryCount = 0
        }
        
        if retryCount >= maxRetries {
            throw YTError.downloadError(context: YTError.Context(message: "Hit maximum retries for individial chunk"))
        }
        
        updateHandler(self, progress(completedCount: expectedSize))
        
        try FileManager.default.moveItem(at: partFile, to: outputURL)
    }
    
    func log(_ message: String) {
        print("[YTHTTPDownloader] \(message)")
    }
    
    func progress(completedCount: Int64) -> Progress {
        let progress = Progress(totalUnitCount: expectedSize)
        progress.completedUnitCount = completedCount
        return progress
    }
    
    func addRangeHeader(for request: inout URLRequest, start: Int64, end: Int64) {
        request.addValue("bytes=\(start)-\(end-1)", forHTTPHeaderField: "Range")
    }
    
    func createPartFile(for url: URL) throws -> URL {
        let partFile = url.appendingPathExtension("part")
        FileManager.default.createFile(atPath: partFile.path(), contents: nil)
        guard FileManager.default.fileExists(atPath: partFile.path()) else {
            throw YTError.downloadError(context: YTError.Context(message: "Failed to create part file at \(partFile.path())"))
        }
        return partFile
    }
    
    func append(to url: URL, data: Data) throws {
        let handle = try FileHandle(forWritingTo: url)
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
        try handle.close()
    }
}

extension YTHTTPDownloader: Cancellable {
    mutating func cancel() throws {
        log("Cancelling download...")
        isDownloadCancelled = true
    }
}
