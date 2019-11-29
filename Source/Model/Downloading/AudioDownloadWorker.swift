//
//  AudioDownloadWorker.swift
//  SwiftAudioPlayer
//
//  Created by Tanha Kabir on 2019-01-29.
//  Copyright © 2019 Tanha Kabir, Jon Mercer
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

protocol AudioDataDownloadable: AnyObject {
    init(allowCellular: Bool, progressCallback: @escaping (_ id: ID, _ progress: Double)->(), doneCallback: @escaping (_ id: ID, _ error: Error?)->(), backgroundDownloadCallback: @escaping ()->())
    
    var numberOfActive: Int { get }
    var numberOfQueued: Int { get }
    
    func getProgressOfDownload(withID id: ID) -> Double?
    
    func start(withID id: ID, withRemoteUrl remoteUrl: URL, completion: @escaping (URL) -> ())
    func stop(withID id: ID, callback: ((_ dataSoFar: Data?, _ totalBytesExpected: Int64?) -> ())?)
    func pauseAllActive() //Because of streaming
    func resumeAllActive() //Because of streaming
}

class AudioDownloadWorker: NSObject, AudioDataDownloadable {
    private let MAX_CONCURRENT_DOWNLOADS = 3
    
    // Given by the AppDelegate
    private let backgroundCompletion: () -> ()
    
    private let progressHandler: (ID, Double) -> ()
    private let completionHandler: (ID, Error?) -> ()
    
    private let allowsCellularDownload: Bool
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "SwiftAudioPlayer.background_downloader_\(Date.getUTC())")
        config.isDiscretionary = !allowsCellularDownload
        config.sessionSendsLaunchEvents = true
        config.allowsCellularAccess = allowsCellularDownload
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    private var activeDownloads: [ActiveDownload] = []
    private var queuedDownloads = Set<DownloadInfo>()
    
    var numberOfActive: Int {
        return activeDownloads.count
    }
    
    var numberOfQueued: Int {
        return queuedDownloads.count
    }
    
    required init(allowCellular: Bool,
                  progressCallback: @escaping (_ id: ID, _ progress: Double)->(),
                  doneCallback: @escaping (_ id: ID, _ error: Error?)->(),
                  backgroundDownloadCallback: @escaping ()->()) {
        Log.info("init with allowCellular: \(allowCellular)")
        self.progressHandler = progressCallback
        self.completionHandler = doneCallback
        self.backgroundCompletion = backgroundDownloadCallback
        self.allowsCellularDownload = allowCellular
        
        super.init()
    }
    
    func getProgressOfDownload(withID id: ID) -> Double? {
        return activeDownloads.filter { $0.info.id == id }.first?.progress
    }
    
    func start(withID id: ID, withRemoteUrl remoteUrl: URL, completion: @escaping (URL) -> ()) {
        Log.info("startExternal paramID: \(id) activeDownloadIDs: \((activeDownloads.map { $0.info.id } ).toLog)")
        let temp = activeDownloads.filter { $0.info.id == id }.count
        guard temp == 0 else {
            return
        }
        
        let info = queuedDownloads.updatePreservingOldCompletionHandlers(withID: id, withRemoteUrl: remoteUrl, completion: completion)
        
        start(withInfo: info)
    }
    
    fileprivate func start(withInfo info: DownloadInfo) {
        Log.info("paramID: \(info.id) activeDownloadIDs: \((activeDownloads.map { $0.info.id } ).toLog)")
        let temp = activeDownloads.filter { $0.info.id == info.id }.count
        guard temp == 0 else {
            return
        }
        
        guard numberOfActive < MAX_CONCURRENT_DOWNLOADS else {
            _ = queuedDownloads.updatePreservingOldCompletionHandlers(withID: info.id, withRemoteUrl: info.remoteUrl)
            return
        }
        
        queuedDownloads.remove(info)
        
        let task: URLSessionDownloadTask = session.downloadTask(with: info.remoteUrl)
        task.taskDescription = info.id
        
        let activeTask = ActiveDownload(info: info, task: task)
        
        activeDownloads.append(activeTask)
        activeTask.task.resume()
    }
    
    func pauseAllActive() {
        Log.info("activeDownloadIDs: \((activeDownloads.map { $0.info.id } ).toLog)")
        for download in activeDownloads {
            if download.task.state == .running {
                download.task.suspend()
            }
        }
    }
    
    func resumeAllActive() {
        Log.info("activeDownloadIDs: \((activeDownloads.map { $0.info.id } ).toLog)")
        for download in activeDownloads {
            download.task.resume()
        }
    }
    
    func stop(withID id: ID, callback: ((_ dataSoFar: Data?, _ totalBytesExpected: Int64?) -> ())?) {
        Log.info("paramId: \(id), activeDownloadIDs: \((activeDownloads.map { $0.info.id } ).toLog)")
        for download in activeDownloads {
            if download.info.id == id && download.task.state == .running {
                download.task.cancel { (data: Data?) in
                    callback?(nil, nil)
                    // Could not achieve this because this resume data isn't actually the data downloaded so far but instead metadata. Not sure how to get the actual data that download task is downloading
                    //                    callback?(data, download.totalBytesExpected)
                }
                activeDownloads = activeDownloads.filter { $0.info.id != id }
                return
            }
        }
        
        queuedDownloads.remove(withMatchingId: id)
        callback?(nil, nil)
    }
}

extension AudioDownloadWorker: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let activeTask = activeDownloads.filter { $0.task == downloadTask }.first
        
        guard let task = activeTask else {
            Log.monitor("could not find corresponding active download task when done downloading: \(downloadTask.currentRequest?.url?.absoluteString ?? "nil url")")
            return
        }
        
        guard let fileType = downloadTask.response?.suggestedFilename?.pathExtension else {
            Log.monitor("No file type exists for file from downloading.. id: \(downloadTask.taskDescription ?? "nil") :: url: \(task.info.remoteUrl) where it suggested filename: \(downloadTask.response?.suggestedFilename ?? "nil")")
            return
        }
        
        let destinationUrl = FileStorage.Audio.getUrl(givenId: task.info.id, andFileExtension: fileType)
        Log.info("Writing download file with id: \(task.info.id) to file named: \(destinationUrl.lastPathComponent)")
        
        // https://stackoverflow.com/questions/20251432/cant-move-file-after-background-download-no-such-file
        // Apparently, the data of the temporary location get deleted outside of this function immediately, so others recommended extracting the data and writing it, this is why I'm not using DiskUtil
        do {
            _ = try FileManager.default.replaceItemAt(destinationUrl, withItemAt: location)
            
            Log.info("Successful write file to url: \(destinationUrl.absoluteString)")
            progressHandler(task.info.id, 1.0)
        } catch {
            if (error as NSError).code == NSFileWriteFileExistsError {
                do {
                    Log.info("File already existed at attempted download url: \(destinationUrl.absoluteString)")
                    try FileManager.default.removeItem(at: destinationUrl)
                    _ = try FileManager.default.replaceItemAt(destinationUrl, withItemAt: location)
                    Log.info("Replaced previous file at url: \(destinationUrl.absoluteString)")
                } catch {
                    Log.monitor("Error moving file after download for task id: \(task.info.id) and error: \(error.localizedDescription)")
                }
            } else {
                Log.monitor("Error moving file after download for task id: \(task.info.id) and error: \(error.localizedDescription)")
            }
        }
        
        completionHandler(task.info.id, nil)
    
        for handler in task.info.completionHandlers {
            handler(destinationUrl)
        }
        
        activeDownloads = activeDownloads.filter { $0 != task }
        
        if let queued = queuedDownloads.popHighestRanked() {
            start(withInfo: queued)
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundCompletion()
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let e = error {
            if let err: NSError = error as NSError? {
                if err.domain == NSURLErrorDomain && err.code == NSURLErrorCancelled {
                    Log.info("cancelled downloading")
                    return
                }
            }
            
            if let err: NSError = error as NSError? {
                if err.domain == NSPOSIXErrorDomain && err.code == 2 {
                    Log.error("download error where file says it doesn't exist, this could be because of bad network")
                    return
                }
            }
            
            for download in activeDownloads {
                if download.task == task {
                    completionHandler(download.info.id, e)
                    activeDownloads = activeDownloads.filter { $0.task != task }
                }
            }
            
            Log.monitor("\(task.currentRequest?.url?.absoluteString ?? "nil url") error: \(e.localizedDescription)")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        var found: Bool = false
        
        for download in activeDownloads {
            if download.task == downloadTask {
                found = true
                download.progress = Double(totalBytesWritten)/Double(totalBytesExpectedToWrite)
                download.totalBytesExpected = totalBytesExpectedToWrite
                if download.progress != 1.0 {
                    progressHandler(download.info.id, download.progress)
                }
            }
        }
        
        if !found {
            Log.monitor("could not find active download when receiving progress updates")
        }
    }
}

// MARK:- Helpers
extension AudioDownloadWorker {
}

// MARK:- Helper Classes
extension AudioDownloadWorker {
    fileprivate struct DownloadInfo: Hashable {
        static func == (lhs: AudioDownloadWorker.DownloadInfo, rhs: AudioDownloadWorker.DownloadInfo) -> Bool {
            return lhs.id == rhs.id && lhs.remoteUrl == rhs.remoteUrl
        }
        
        let id: ID
        let remoteUrl: URL
        let rank: Int
        var completionHandlers: [(URL) -> ()]
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(remoteUrl)
        }
    }
    
    private class ActiveDownload: Hashable {
        static func == (lhs: AudioDownloadWorker.ActiveDownload, rhs: AudioDownloadWorker.ActiveDownload) -> Bool {
            return lhs.info.id == rhs.info.id
        }
        
        let info: DownloadInfo
        var totalBytesExpected: Int64?
        var progress: Double = 0.0
        let task: URLSessionDownloadTask
        
        init(info: DownloadInfo, task: URLSessionDownloadTask) {
            self.info = info
            self.task = task
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(info.id)
            hasher.combine(task)
        }
    }
}

extension Set where Element == AudioDownloadWorker.DownloadInfo {
    mutating func popHighestRanked() -> AudioDownloadWorker.DownloadInfo? {
        guard self.count > 0 else { return nil }
        
        var ret: AudioDownloadWorker.DownloadInfo = self.first!
        
        for info in self {
            if info.rank > ret.rank {
                ret = info
            }
        }
        
        self.remove(ret)
        
        return ret
    }
    
    mutating func updatePreservingOldCompletionHandlers(withID id: ID, withRemoteUrl remoteUrl: URL, completion: ((URL) -> ())? = nil) -> AudioDownloadWorker.DownloadInfo {
        
        let rank = Date.getUTC()
        
        let tempHandlers: [(URL) -> ()] = completion != nil ? [completion!] : []
        
        var newInfo = AudioDownloadWorker.DownloadInfo.init(id: id, remoteUrl: remoteUrl, rank: rank, completionHandlers: tempHandlers)
        
        if let previous = self.update(with: newInfo) {
            let prevHandlers = previous.completionHandlers
            let newHandlers = prevHandlers + tempHandlers
            
            newInfo = AudioDownloadWorker.DownloadInfo.init(id: id, remoteUrl: remoteUrl, rank: rank, completionHandlers: newHandlers)
            
            self.update(with: newInfo)
        }
        
        return newInfo
    }
    
    mutating func remove(withMatchingId id: ID) {
        var toRemove: AudioDownloadWorker.DownloadInfo? = nil
        var matchCount = 0
        
        for item in self.enumerated() {
            if item.element.id == id {
                toRemove = item.element
                matchCount += 1
            }
        }
        
        guard matchCount <= 1 else {
            Log.error("Found \(matchCount) matches of queued info with the same id of: \(id), this should have never happened.")
            return
        }
        
        if let removeInfo = toRemove {
            self.remove(removeInfo)
        }
    }
}

extension String {
    var pathExtension: String? {
        let cleaned = self.replacingOccurrences(of: " ", with: "_")
        let ext = URL(string: cleaned)?.pathExtension
        return ext == "" ? nil : ext
    }
}
