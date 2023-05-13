import XCTest
@testable import YouTubeKit

final class YouTubeKitTests: XCTestCase {
    func testYTVideo() async throws {
        let url = URL(string: "https://www.youtube.com/watch?v=2TtnD4jmCDQ")!
        let video = try await YTDownloader().video(for: url)
        print(video)
    }
    
    func testDownload() async throws {
        let url = URL(string: "https://www.youtube.com/watch?v=a8DM-tD9w2I")!
        let destURL = URL(filePath: "/Users/dani/Desktop/Video.mp4")
        
        let downloader = YTDownloader()
        let video = try await downloader.video(for: url)
        try await downloader.download(video: video, quality: .hd720, outputURL: destURL, updateHandler: { _, progress in
            let percentage = String(format: "%.3f", progress.fractionCompleted * 100)
            var throughput = "NaN"
            if let throughputCount = progress.throughput {
                throughput = String(throughputCount)
            }
            print("Downloaded \(progress.completedUnitCount)/\(progress.totalUnitCount) bytes (\(percentage)%) --- \(throughput) bytes/s")
        })
        
        print("Downloaded to '\(destURL.path())'")
    }
    
    func testYTMimeType() throws {
        let mimeTypeString = "video/mp4;codecs=\"avc1.640028\""
        guard let mimeType = YTMimeType(string: mimeTypeString) else {
            throw XCTestError(.failureWhileWaiting)
        }
        XCTAssertEqual(mimeTypeString, mimeType.description)
    }
    
    func testEnumEncoding() throws {
        XCTAssertEqual(String(data: try JSONEncoder().encode(YTVideoFormat.Quality.hd1080), encoding: .utf8)!, "\"hd1080\"")
    }
    
    func testNDescrambling() throws {
        let testN = "DqYwYTcfStkc4Ih1sB0"
        let expectedN = "8NoLfDQp50EcIA"
        let resultN = try YTDownloaderImpl().unthrottle(n: testN)
        print("Input: \(testN), expected: \(expectedN), result: \(resultN)")
        XCTAssertEqual(resultN, expectedN)
    }
}
