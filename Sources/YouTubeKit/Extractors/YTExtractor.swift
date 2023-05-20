//
//  YTExtractor.swift
//  
//
//  Created by Dani on 13/5/23.
//

import Foundation

protocol YTExtractor {
    func video(for videoURL: URL) async throws -> YTVideo
}
