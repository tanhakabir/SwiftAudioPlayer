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
    private var mediaInfo: SALockScreenInfo?
    
    private var urlKeyMap: [Key: URL] = [:]
    
    var durationRef:UInt = 0
    var needleRef:UInt = 0
    var playingStatusRef:UInt = 0
    var audioQueue: [(Location, URL)] = []
    
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
        mediaInfo = nil
        delegate?.clearLockScreenInfo()
        
        AudioClockDirector.shared.detachFromChangesInDuration(withID: durationRef)
        AudioClockDirector.shared.detachFromChangesInNeedle(withID: needleRef)
        AudioClockDirector.shared.detachFromChangesInPlayingStatus(withID: playingStatusRef)
    }
    
    func handlePlaySavedAudio(withSavedUrl url: URL) {
        // Because we support queueing, we want to clear off any existing players.
        // Therefore, instantiate new player every time, destroy any existing ones.
        // This prevents a crash where an owning engine already exists.
        handleClear()
        attachForUpdates(url: url)
        delegate?.startAudioDownloaded(withSavedUrl: url)
    }
    
    func handlePlayStreamedAudio(withRemoteUrl url: URL) {
        // Because we support queueing, we want to clear off any existing players.
        // Therefore, instantiate new player every time, destroy any existing ones.
        // This prevents a crash where an owning engine already exists.
        handleClear()
        attachForUpdates(url: url)
        delegate?.startAudioStreamed(withRemoteUrl: url)
    }
    
    func handleQueueStreamedAudio(withRemoteUrl url: URL) {
        audioQueue.append((.remote, url))
    }
    
    func handleQueueSavedAudio(withSavedUrl url: URL) {
        audioQueue.append((.disk, url))
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
            
            self.delegate?.setLockScreenInfo(withMediaInfo: self.mediaInfo, duration: duration)
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
    
    @available(iOS 10.0, *)
    func handleLockscreenInfo(info: SALockScreenInfo?) {
        self.mediaInfo = info
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
    
    func didEndPlaying() {
        Log.test("end of audio")
        playNextAudioIfExists()
    }
}

//MARK:- Autoplay
extension SAPlayerPresenter {
    func playNextAudioIfExists() {
        Log.test("will try to play next audio")
        guard audioQueue.count > 0 else {
            Log.info("no queued audio")
            return
        }
        let nextAudioURL = audioQueue.removeFirst()
        let key = nextAudioURL.1.key
        
        // We have to be on the main thread here. Seems like a hack but prevents the following:
        // reason: 'required condition is false: nil == owningEngine || GetEngine() == owningEngine'
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
            Log.test(nextAudioURL)
        AudioQueueDirector.shared.changeInQueue(key, url: nextAudioURL.1)
        
        switch nextAudioURL.0 {
        case .remote:
            self.handlePlayStreamedAudio(withRemoteUrl: nextAudioURL.1)
            break
        case .disk:
            self.handlePlaySavedAudio(withSavedUrl: nextAudioURL.1)
        }
        
            self.handlePlay()
//        }
    }
}
