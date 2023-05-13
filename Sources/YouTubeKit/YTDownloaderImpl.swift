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
    static let alphabet: String = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_="
    
    func download(
        video: YTVideo,
        quality: YTVideoFormat.Quality,
        fileFormat: YTFileFormat,
        outputURL: URL,
        updateHandler: @escaping (YTVideo, Progress) -> Void
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                guard let videoFormat = video.formats.first(where: { $0.quality == quality && $0.mimeType.subtype == fileFormat.rawValue }) else {
                    throw YTError.unavailableFormatAndQuality(format: fileFormat, quality: quality)
                }
                
                let configuration = URLSessionConfiguration.default
                
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
                let session = URLSession(configuration: configuration,
                                         delegate: delegate,
                                         delegateQueue: .main)
                
                let unthrottledURL = try unthrottle(videoURL: videoFormat.url)
                let downloadTask = session.downloadTask(with: unthrottledURL)
                downloadTask.resume()
            } catch {
                continuation.resume(throwing: error)
            }
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
    
    func createTemporaryFileURL() -> URL {
        let filename = "download" + (0..<8).compactMap { _ in
            Self.alphabet.randomElement()
        } + ".tmp"
        return URL(filePath: NSTemporaryDirectory()).appending(path: filename)
    }
}
