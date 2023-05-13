//
//  YTExtractor.swift
//  
//
//  Created by Dani on 3/5/23.
//

import Foundation
import RegexBuilder

struct YTExtractor {
    static let playerAPIURL: URL = URL(string: "https://www.youtube.com/youtubei/v1/player")!
    static let videoIDRegex: Regex = #/v=(.{11})/#
    
    func video(for videoURL: URL) async throws -> YTVideo {
        let videoID = try await videoID(for: videoURL)
        
        return try await throwingYTError {
            var request = URLRequest(url: Self.playerAPIURL)
            request.httpMethod = "POST"
            request.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")
            let requestBody = requestBody(videoID: videoID)
            let requestBodyData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = requestBodyData
            
            let (responseData, _) = try await URLSession.shared.data(for: request)
            guard let responseJSON = try JSONSerialization.jsonObject(with: responseData) as? [String : Any],
                  let videoDetails = responseJSON["videoDetails"],
                  let videoFormats = (responseJSON["streamingData"] as? [String : Any])?["formats"],
                  let videoAdaptiveFormats = (responseJSON["streamingData"] as? [String : Any])?["adaptiveFormats"] else {
                throw YTError.parsingError()
            }
            
            let detailsJSON = try JSONSerialization.data(withJSONObject: videoDetails)
            let details = try JSONDecoder().decode(YTVideoDetails.self, from: detailsJSON)
            
            let formatsJSON = try JSONSerialization.data(withJSONObject: videoFormats)
            var formats = try JSONDecoder().decode([YTVideoFormat].self, from: formatsJSON)
            
            let apaptiveFormatsJSON = try JSONSerialization.data(withJSONObject: videoAdaptiveFormats)
            formats.append(contentsOf: try JSONDecoder().decode([YTVideoFormat].self, from: apaptiveFormatsJSON))
            
            return YTVideo(details: details, formats: formats)
        }
    }
    
    func videoID(for videoURL: URL) async throws -> String {
        guard let lastComponent = videoURL.query() else {
            throw YTError.invalidURL()
        }
        return try await throwingYTError {
            guard let (_, videoID) = try Self.videoIDRegex.firstMatch(in: lastComponent)?.output else {
                throw YTError.invalidURL()
            }
            return String(videoID)
        }
    }
    
    func requestBody(videoID: String) -> [String : Any] {
        [
            "videoId": videoID,
            "context": [
                "client": [
                    "clientName": "WEB_EMBEDDED_PLAYER",
                    "clientVersion": "1.20230430.00.00"
                ]
            ]
        ]
    }
    
    func throwingYTError<T>(_ code: () async throws -> T) async throws -> T {
        do {
            return try await code()
        } catch {
            if let error = error as? YTError {
                throw error
            }
            throw YTError.unknown(context: YTError.Context(underlyingError: error))
        }
    }
}
