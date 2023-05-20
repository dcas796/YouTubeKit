//
//  YTDefaultExtractor.swift
//  
//
//  Created by Dani on 13/5/23.
//

import Foundation

struct YTDefaultExtractor: YTExtractor {
    static let apiKey = "AIzaSyA8eiZmM1FaDVjRy-df2KTyQ_vz_yYM39w"
    static let playerAPIURL: URL = URL(string:
        "https://www.youtube.com/youtubei/v1/player?key=\(apiKey)&prettyPrint=false")!
    static let videoIDRegex: Regex = #/v=(.{11})/#
    static let userAgent: String = "com.google.android.youtube/17.31.35 (Linux; U; Android 11) gzip"
    static let requestHeaders: [String : String] = [
        "Content-Type": "application/json",
        "X-youtube-client-name": "3",
        "X-youtube-client-version": "17.31.35",
        "Origin": "https://www.youtube.com",
        "User-Agent": userAgent
    ]
    
    func video(for videoURL: URL) async throws -> YTVideo {
        let videoID = try await videoID(for: videoURL)
        
        return try await YTError.asyncWrapper {
            var request = URLRequest(url: Self.playerAPIURL)
            request.httpMethod = "POST"
            addHeaders(for: &request)
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
        return try await YTError.asyncWrapper {
            guard let (_, videoID) = try Self.videoIDRegex.firstMatch(in: lastComponent)?.output else {
                throw YTError.invalidURL()
            }
            return String(videoID)
        }
    }
    
    func addHeaders(for request: inout URLRequest) {
        for (header, value) in Self.requestHeaders {
            request.addValue(value, forHTTPHeaderField: header)
        }
    }
    
    func requestBody(videoID: String) -> [String : Any] {
        [
            "context": [
                "client": [
                    "clientName": "ANDROID",
                    "clientVersion": "17.31.35",
                    "androidSdkVersion": 30,
                    "userAgent": "com.google.android.youtube/17.31.35 (Linux; U; Android 11) gzip",
                    "hl": "en",
                    "timeZone": "UTC",
                    "utcOffsetMinutes": 0
                ] as [String : Any]
            ],
            "videoId": videoID,
            "playbackContext": [
                "contentPlaybackContext": [
                    "html5Preference": "HTML5_PREF_WANTS"
                ]
            ],
            "contentCheckOk": true,
            "racyCheckOk": true
        ]
    }
}
