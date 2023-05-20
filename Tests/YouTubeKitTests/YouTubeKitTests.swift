import XCTest
@testable import YouTubeKit

final class YouTubeKitTests: XCTestCase {
    static let testVideoURL: URL = URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!
    static let testDestURL = URL.temporaryDirectory.appending(component: "video.mp4")
    static let testDownloadURL = URL(string: "https://file-examples.com/storage/fea9880a616463cab9f1575/2017/04/file_example_MP4_1920_18MG.mp4")!
    
    func testYTVideo() async throws {
        let video = try await YTDownloader().video(for: Self.testVideoURL)
        print(video)
    }
    
    func testDownload() async throws {
        var downloader = YTDownloader()
        let video = try await downloader.video(for: Self.testVideoURL)
        let format = downloader.bestFormat(for: video, quality: .hd1080)!
        try await downloader.download(video: video, format: format, outputURL: Self.testDestURL, updateHandler: { _, progress in
            let percentage = String(format: "%.3f", progress.fractionCompleted * 100)
            var throughput = "NaN"
            if let throughputCount = progress.throughput {
                throughput = String(throughputCount)
            }
            print("Downloaded \(progress.completedUnitCount)/\(progress.totalUnitCount) bytes (\(percentage)%) --- \(throughput) bytes/s")
        })

        print("Downloaded to '\(Self.testDestURL.path())'")
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
        let resultN = try YTDownloaderImpl(downloaderOption: .unthrottle).unthrottle(n: testN)
        print("Input: \(testN), expected: \(expectedN), result: \(resultN)")
        XCTAssertEqual(resultN, expectedN)
    }
    
    func testThumbnails() async throws {
        let downloader = YTDownloader()
        let video = try await downloader.video(for: Self.testVideoURL)
        print(video.details.thumbnails)
    }
    
    func testHTTPDownloader() async throws {
        var httpDownloader = try await YTHTTPDownloader(url: Self.testDownloadURL)
        print(httpDownloader)
        try await httpDownloader.download(to: Self.testDestURL) { _, progress in
            print("Downloaded \(progress.completedUnitCount) bytes of \(progress.totalUnitCount) bytes (\((progress.fractionCompleted*100).rounded())%)")
        }
        print("Downloaded file to '\(Self.testDestURL.path())'")
    }
}
