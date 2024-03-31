
# YouTubeKit

A Swift package that extracts and downloads YouTube videos.

Note: this is just a fun side-project, don't use this for production :)

| Test               | Passing  |
|--------------------|----------|
| testYTVideo        | ❌       |
| testDownload       | ❌       |
| testYTMimeType     | ✅       |
| testEnumEncoding   | ✅       |
| testNDescrambling  | ✅       |
| testThumbnails     | ❌       |
| testHTTPDownloader | ❌       |

Note: This project hasn't been updated in a long time, so don't expect it to work. 
I will continue committing to this project whenever I find spare time.

## Example
```swift
let videoURL = URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!
let destURL = URL(filePath: "video.mp4")

var downloader = YTDownloader()
let video = try await downloader.video(for: videoURL)
let format = downloader.bestFormat(for: video, quality: .hd1080)!

try await downloader.download(video: video, format: format, outputURL: destURL, updateHandler: { _, progress in
    let percentage = String(format: "%.3f", progress.fractionCompleted * 100)
    print("Downloaded \(progress.completedUnitCount) bytes of \(progress.totalUnitCount) bytes (\(percentage)%)")
})

print("Video downloaded to \(destURL.path())")
```

## Features

- Extract info from YouTube videos
- Download YouTube videos at any resolution and format (mp4, webm)
- Integrated HTTP multi-threaded chunked downloader for faster download speeds
- Unthrottle YouTube download speeds (using n param descrambling)
- Pure Swift interface for handling video info
- More coming soon...

## Install with SPM
To include this package, add this line to your ```Package.swift```:

```swift
.package(url: "https://github.com/dcas796/YouTubeKit.git", exact: "0.0.3")
```

---
Made by [dcas796](https://dcas796.github.com/)
