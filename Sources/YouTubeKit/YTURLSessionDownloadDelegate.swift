//
//  YTURLSessionDownloadDelegate.swift
//  
//
//  Created by Dani on 5/5/23.
//

import Foundation

class YTURLSessionDownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let video: YTVideo
    let updateHandler: (YTVideo, Progress) -> Void
    let completionHandler: (Result<URL, YTError>) -> Void
    private var isCompleted: Bool = false
    
    init(
        video: YTVideo,
        updateHandler: @escaping (YTVideo, Progress) -> Void,
        completionHandler: @escaping (Result<URL, YTError>) -> Void
    ) {
        self.video = video
        self.updateHandler = updateHandler
        self.completionHandler = completionHandler
    }
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Progress(totalUnitCount: totalBytesExpectedToWrite)
        progress.completedUnitCount = totalBytesWritten
        updateHandler(video, progress)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if !isCompleted {
            completionHandler(Result.failure(YTError.downloadError(context: YTError.Context(underlyingError: error))))
            isCompleted = true
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if !isCompleted {
            completionHandler(Result.success(location))
            isCompleted = true
        }
    }
}
