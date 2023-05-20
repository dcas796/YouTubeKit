//
//  YTVideoDetails.swift
//  
//
//  Created by Dani on 3/5/23.
//

import Foundation

public struct YTVideoDetails: Equatable, Hashable, Identifiable {
    public var id: String
    public var title: String
    public var lengthSeconds: String
    public var channelID: String
    public var shortDescription: String
    public var thumbnails: [YTVideoThumbnail]
    public var viewCount: Int
    public var author: String
    public var isPrivate: Bool
}

extension YTVideoDetails: Decodable {
    enum CodingKeys: CodingKey {
        case videoId
        case title
        case lengthSeconds
        case channelId
        case shortDescription
        case thumbnail
        case viewCount
        case author
        case isPrivate
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .videoId)
        self.title = try container.decode(String.self, forKey: .title)
        self.lengthSeconds = try container.decode(String.self, forKey: .lengthSeconds)
        self.channelID = try container.decode(String.self, forKey: .channelId)
        self.shortDescription = try container.decode(String.self, forKey: .shortDescription)
        guard let viewCount = Int(try container.decode(String.self, forKey: .viewCount)) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [CodingKeys.viewCount],
                                      debugDescription: "Failed Int conversion from String"))
        }
        let thumbnailsObject = try container.decode([String : [YTVideoThumbnail]].self, forKey: .thumbnail)
        guard let thumbnails = thumbnailsObject["thumbnails"] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [CodingKeys.thumbnail],
                                      debugDescription: "Unable to locate 'thumbnails' key in 'thumbnail' object"))
        }
        self.thumbnails = thumbnails
        self.viewCount = viewCount
        self.author = try container.decode(String.self, forKey: .author)
        self.isPrivate = try container.decode(Bool.self, forKey: .isPrivate)
    }
}
