//
//  YTVideoFormat.swift
//  
//
//  Created by Dani on 4/5/23.
//

import Foundation

public struct YTVideoFormat: Equatable, Hashable, Identifiable {
    public var id: Int
    public var url: URL
    public var mimeType: YTMimeType
    public var bitrate: Int
    public var width: Int?
    public var height: Int?
    public var contentLength: String?
    public var quality: Quality
    public var audioQuality: AudioQuality?
    public var fps: Int?
}

extension YTVideoFormat {
    public enum Quality: String, Equatable, Hashable, Codable {
        // TODO: More quality formats
        /// An HD 1080p video
        case hd1080
        /// An HD 720p video
        case hd720
        /// A 480p video
        case large
        /// A 360p video
        case medium
        /// A 240p video
        case small
        /// A 144p video
        case tiny
    }
    
    public enum AudioQuality: String, Equatable, Hashable, Decodable {
        case medium = "AUDIO_QUALITY_MEDIUM"
        case low = "AUDIO_QUALITY_LOW"
    }
}

extension YTVideoFormat.Quality {
    public var pixels: Int {
        switch self {
        case .hd1080:
            return 1080
        case .hd720:
            return 720
        case .large:
            return 480
        case .medium:
            return 360
        case .small:
            return 240
        case .tiny:
            return 144
        }
    }
}

extension YTVideoFormat.Quality: Comparable {
    public static func < (lhs: YTVideoFormat.Quality, rhs: YTVideoFormat.Quality) -> Bool {
        lhs.pixels < rhs.pixels
    }
}

extension YTVideoFormat.Quality: CustomStringConvertible {
    public var description: String {
        switch self {
        case .hd1080:
            return "1080p"
        case .hd720:
            return "720p"
        case .large:
            return "480p"
        case .medium:
            return "360p"
        case .small:
            return "240p"
        case .tiny:
            return "144p"
        }
    }
}

extension YTVideoFormat: Decodable {
    enum CodingKeys: CodingKey {
        case itag
        case url
        case mimeType
        case bitrate
        case width
        case height
        case contentLength
        case quality
        case audioQuality
        case fps
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .itag)
        self.url = try container.decode(URL.self, forKey: .url)
        self.mimeType = try container.decode(YTMimeType.self, forKey: .mimeType)
        self.bitrate = try container.decode(Int.self, forKey: .bitrate)
        self.width = try? container.decode(Int.self, forKey: .width)
        self.height = try? container.decode(Int.self, forKey: .height)
        self.contentLength = try? container.decode(String.self, forKey: .contentLength)
        self.quality = try container.decode(Quality.self, forKey: .quality)
        self.audioQuality = try? container.decode(AudioQuality.self, forKey: .audioQuality)
        self.fps = try? container.decode(Int.self, forKey: .fps)
    }
}
