//
//  SAPlayerPresenter.swift
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
import AVFoundation
import MediaPlayer

class SAPlayerPresenter {
    struct QueueItem {
        var loc: Location
        var url: URL
        var mediaInfo: SALockScreenInfo?
        var bitrate: SAPlayerBitrate
        
        init(loc: Location, url: URL, mediaInfo: SALockScreenInfo?, bitrate: SAPlayerBitrate = .high) {
            self.loc = loc
            self.url = url
            self.mediaInfo = mediaInfo
            self.bitrate = bitrate
        }
    }
    
    enum Location {
        case remote
        case disk
    }
    
    weak var delegate: SAPlayerDelegate?
    var shouldPlayImmediately = false //for auto-play
    
    var needle: Needle?
    var duration: Duration?
    
    private var key: String?
    private var isPlaying: SAPlayingStatus = .buffering
    
    private var urlKeyMap: [Key: URL] = [:]
    
    var durationRef:UInt = 0
    var needleRef:UInt = 0
    var playingStatusRef:UInt = 0
    var audioQueue: [QueueItem] = []
    
    init(delegate: SAPlayerDelegate?) {
        self.delegate = delegate
        
        delegate?.setLockScreenControls(presenter: self)
    }
    
    func getUrl(forKey key: Key) -> URL? {
        return urlKeyMap[key]
    }
    
    func addUrlToKeyMap(_ url: URL) {
        urlKeyMap[url.key] = url
    }
    
    func handleClear() {
        delegate?.clearEngine()
        
        needle = nil
        duration = nil
        key = nil
        delegate?.mediaInfo = nil
        delegate?.clearLockScreenInfo()
        
        AudioClockDirector.shared.detachFromChangesInDuration(withID: durationRef)
        AudioClockDirector.shared.detachFromChangesInNeedle(withID: needleRef)
        AudioClockDirector.shared.detachFromChangesInPlayingStatus(withID: playingStatusRef)
    }
    
    func handlePlaySavedAudio(withSavedUrl url: URL) {
        attachForUpdates(url: url)
        delegate?.startAudioDownloaded(withSavedUrl: url)
    }
    
    func handlePlayStreamedAudio(withRemoteUrl url: URL, bitrate: SAPlayerBitrate) {
        attachForUpdates(url: url)
        delegate?.startAudioStreamed(withRemoteUrl: url, bitrate: bitrate)
    }
    
    func handleQueueStreamedAudio(withRemoteUrl url: URL, mediaInfo: SALockScreenInfo?, bitrate: SAPlayerBitrate) {
        audioQueue.append(QueueItem(loc: .remote, url: url, mediaInfo: mediaInfo, bitrate: bitrate))
    }
    
    func handleQueueSavedAudio(withSavedUrl url: URL, mediaInfo: SALockScreenInfo?) {
        audioQueue.append(QueueItem(loc: .disk, url: url, mediaInfo: mediaInfo))
    }
    
    private func attachForUpdates(url: URL) {
        detachFromUpdates()
        
        self.key = url.key
        urlKeyMap[url.key] = url
        
        durationRef = AudioClockDirector.shared.attachToChangesInDuration(closure: { [weak self] (key, duration) in
            guard let self = self else { throw DirectorError.closureIsDead }
            guard key == self.key else {
                Log.debug("misfire expected key: \(self.key ?? "none") payload key: \(key)")
                return
            }
            
            self.delegate?.updateLockscreenPlaybackDuration(duration: duration)
            self.duration = duration
            
            self.delegate?.setLockScreenInfo(withMediaInfo: self.delegate?.mediaInfo, duration: duration)
        })
        
        needleRef = AudioClockDirector.shared.attachToChangesInNeedle(closure: { [weak self] (key, needle) in
            guard let self = self else { throw DirectorError.closureIsDead }
            guard key == self.key else {
                Log.debug("misfire expected key: \(self.key ?? "none") payload key: \(key)")
                return
            }
            
            self.needle = needle
            self.delegate?.updateLockscreenElapsedTime(needle: needle)
        })
        
        playingStatusRef = AudioClockDirector.shared.attachToChangesInPlayingStatus(closure: { [weak self] (key, isPlaying) in
            guard let self = self else { throw DirectorError.closureIsDead }
            guard key == self.key else {
                Log.debug("misfire expected key: \(self.key ?? "none") payload key: \(key)")
                return
            }
            
            self.isPlaying = isPlaying
            
            if(self.isPlaying == .paused && self.shouldPlayImmediately) {
                self.shouldPlayImmediately = false
                self.handlePlay()
            }
            
            if(self.isPlaying == .ended) {
                self.playNextAudioIfExists()
            }
        })
    }
    
    private func detachFromUpdates() {
        AudioClockDirector.shared.detachFromChangesInDuration(withID: durationRef)
        AudioClockDirector.shared.detachFromChangesInNeedle(withID: needleRef)
        AudioClockDirector.shared.detachFromChangesInPlayingStatus(withID: playingStatusRef)
    }
    
    func handleStopStreamingAudio() {
        delegate?.clearEngine()
        detachFromUpdates()
    }
}

//MARK:- Used by outside world including:
// SPP, lock screen, directors
extension SAPlayerPresenter {
    func handlePause() {
        delegate?.pauseEngine()
        self.delegate?.updateLockscreenPaused()
    }
    
    func handlePlay() {
        delegate?.playEngine()
        self.delegate?.updateLockscreenPlaying()
    }
    
    func handleTogglePlayingAndPausing() {
        if isPlaying == .playing {
            handlePause()
        } else if isPlaying == .paused {
            handlePlay()
        }
    }
    
    func handleSkipForward() {
        guard let forward = delegate?.skipForwardSeconds else { return }
        handleSeek(toNeedle: (needle ?? 0) + forward)
    }
    
    func handleSkipBackward() {
        guard let backward = delegate?.skipForwardSeconds else { return }
        handleSeek(toNeedle: (needle ?? 0) - backward)
    }
    
    func handleSeek(toNeedle needle: Needle) {
        delegate?.seekEngine(toNeedle: needle)
    }
    
    func handleAudioRateChanged(rate: Float) {
        delegate?.updateLockscreenChangePlaybackRate(speed: rate)
    }
    
    func handleScrubbingIntervalsChanged() {
        delegate?.updateLockscreenSkipIntervals()
    }
}

//MARK:- For lock screen
extension SAPlayerPresenter {
    func getIsPlaying() -> Bool {
        return isPlaying == .playing
    }
}

//MARK:- AVAudioEngineDelegate
extension SAPlayerPresenter: AudioEngineDelegate {
    func didError() {
        Log.monitor("We should have handled engine error")
    }
}

//MARK:- Autoplay
extension SAPlayerPresenter {
    func playNextAudioIfExists() {
        Log.info("looking foor next audio in queue to play")
        guard audioQueue.count > 0 else {
            Log.info("no queued audio")
            return
        }
        let nextAudioURL = audioQueue.removeFirst()
        let key = nextAudioURL.url.key
        

        Log.info("getting ready to play \(nextAudioURL)")
        AudioQueueDirector.shared.changeInQueue(key, url: nextAudioURL.url)
        
        handleClear()
        
        delegate?.mediaInfo = nextAudioURL.mediaInfo
        
        // We need to give a second to clean up the previous engine properly. Deinit takes some time.
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] (_) in
            guard let self = self else { return }
            
            switch nextAudioURL.loc {
            case .remote:
                self.handlePlayStreamedAudio(withRemoteUrl: nextAudioURL.url, bitrate: nextAudioURL.bitrate)
                break
            case .disk:
                self.handlePlaySavedAudio(withSavedUrl: nextAudioURL.url)
            }
            
            self.shouldPlayImmediately = true
        }
    }
}
