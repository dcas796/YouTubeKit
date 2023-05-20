//
//  YTDownloaderImpl.swift
//  
//
//  Created by Dani on 7/5/23.
//

import Foundation
import JavaScriptCore

struct YTDownloaderImpl {
    static let descramblerFuncName: String = "descramble"
    static let descramblerURL: URL? = Bundle.module.url(forResource: "descrambler", withExtension: "js")
    
    var downloaderOption: YTOptions.DownloaderOption
    
    var currentCancellable: Cancellable?
    
    mutating func download(
        video: YTVideo,
        format: YTVideoFormat,
        outputURL: URL,
        updateHandler: @escaping (YTVideo, Progress) -> Void
    ) async throws {
        switch downloaderOption {
        case .chunked:
            try await downloadFileChunked(from: format.url, to: outputURL, video: video, updateHandler: updateHandler)
        case .unthrottle:
            let unthrottledURL = try unthrottle(videoURL: format.url)
            try await downloadFile(from: unthrottledURL, to: outputURL, video: video, updateHandler: updateHandler)
        }
    }
    
    mutating func downloadFile(from url: URL,
                      to outputURL: URL,
                      video: YTVideo,
                      updateHandler: @escaping (YTVideo, Progress) -> Void) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let delegate = YTURLSessionDownloadDelegate(video: video,
                                                        updateHandler: updateHandler,
                                                        completionHandler: { result in
                do {
                    switch result {
                    case .success(let url):
                        try FileManager().copyItem(at: url, to: outputURL)
                        continuation.resume()
                    case .failure(let error):
                        throw error
                    }
                } catch {
                    continuation.resume(throwing: YTError.downloadError(context: YTError.Context(underlyingError: error)))
                }
            })
            let configuration = URLSessionConfiguration.default
            let session = URLSession(configuration: configuration,
                                     delegate: delegate,
                                     delegateQueue: .main)
            
            
            let downloadTask = session.downloadTask(with: url)
            self.currentCancellable = downloadTask
            downloadTask.resume()
        }
    }
    
    mutating func downloadFileChunked(from url: URL,
                             to outputURL: URL,
                             video: YTVideo,
                             updateHandler: @escaping (YTVideo, Progress) -> Void) async throws {
        var httpDownloader = try await YTHTTPDownloader(url: url)
        self.currentCancellable = httpDownloader
        try await httpDownloader.download(to: outputURL) { _, progress in
            updateHandler(video, progress)
        }
    }
    
    func unthrottle(videoURL: URL) throws -> URL {
        guard let queryString = videoURL.query() else {
            throw YTError.downloadError()
        }
        let query = try parse(query: queryString)
        guard let n = query["n"] else {
            throw YTError.downloadError(context: YTError.Context(message: "Could not find n query in download URL"))
        }
        let unthrottled = try unthrottle(n: n)
        guard var components = URLComponents(url: videoURL, resolvingAgainstBaseURL: false),
              let nQueryItemIndex = components.queryItems?.firstIndex(where: { $0.name == "n" }) as? Int else {
            throw YTError.downloadError()
        }
        components.queryItems?[nQueryItemIndex].value = unthrottled
        guard let url = components.url else {
            throw YTError.downloadError()
        }
        
        return url
    }
    
    func unthrottle(n: String) throws -> String {
        guard let descramblerURL = Self.descramblerURL else {
            throw YTError.downloadError(context: YTError.Context(message: "Could not get path for descrambler.js file"))
        }
        
        let descramblerString = try String(contentsOf: descramblerURL)
        guard let context = JSContext() else {
            throw YTError.downloadError(context: YTError.Context(message: "Could not create JavaScript context"))
        }
        context.evaluateScript(descramblerString)
        guard let descramblerFunc = context.objectForKeyedSubscript(Self.descramblerFuncName) else {
            throw YTError.downloadError(context: YTError.Context(message: "Could not find descrambling function with name '\(Self.descramblerFuncName)'"))
        }
        guard let descrambledNValue = descramblerFunc.call(withArguments: [n]),
              let unthrottledN = descrambledNValue.toString() else {
            throw YTError.downloadError()
        }
        
        return unthrottledN
    }
    
    func parse(query: String) throws -> [String : String] {
        let components = query.split(separator: "&")
        let keyValues = try components.map {
            let keyValues = $0.split(separator: "=")
            guard keyValues.count == 2 else {
                throw YTError.parsingError(context: YTError.Context(message: "Could not parse URL query"))
            }
            return (String(keyValues[0]), String(keyValues[1]))
        }
        return Dictionary(uniqueKeysWithValues: keyValues)
    }
}
