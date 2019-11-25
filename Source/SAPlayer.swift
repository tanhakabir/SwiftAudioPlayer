//
//  SAPlayer.swift
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

public class SAPlayer {
    public static let shared: SAPlayer = SAPlayer()
    private var presenter: SAPlayerPresenter!
    private var player: AudioEngine?
    
    public var skipForwardSeconds: Double = 30
    public var skipBackwardSeconds: Double = 15
    
    public var rate: Double = 1.0 {
        didSet {
            presenter.handleSetSpeed(withMultiple: rate)
        }
    }
    
    public var duration: Double {
        get {
            return presenter.duration ?? 0.0
        }
    }
    
    public var prettyDuration: String {
        get {
            return SAPlayer.prettifyTimestamp(duration)
        }
    }
    
    public var elapsedTime: Double {
        get {
            return presenter.needle ?? 0
        }
    }
    
    public var prettyElapsedTime: String {
        get {
            return SAPlayer.prettifyTimestamp(elapsedTime)
        }
    }
    
    public var mediaInfo: SALockScreenInfo? = nil {
        didSet {
            if let info = mediaInfo {
                presenter.handleLockscreenInfo(info: info)
            }
        }
    }
    
    private init() {
        presenter = SAPlayerPresenter(delegate: self)
    }
    
    public static func prettifyTimestamp(_ timestamp: Double) -> String {
        let hours = Int(timestamp / 60 / 60)
        let minutes = Int((timestamp - Double(hours * 60)) / 60)
        
        let secondsLeft = Int(timestamp) - (minutes * 60)
        
        return "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", secondsLeft))"
    }
    
    func getUrl(forKey key: Key) -> URL? {
        return presenter.getUrl(forKey: key)
    }
    
    func addUrlToMapping(url: URL) {
        presenter.addUrlToKeyMap(url)
    }
}

//MARK: - External Player Controls
extension SAPlayer {
    public func togglePlayAndPause() {
        presenter.handleTogglePlayingAndPausing()
    }
    
    public func play() {
        presenter.handlePlay()
    }
    
    public func pause() {
        presenter.handlePause()
    }
    
    public func skipBackwards() {
        presenter.handleSkipBackward()
    }
    
    public func skipForward() {
        presenter.handleSkipForward()
    }
    
    public func seekTo(seconds: Double) {
        presenter.handleSeek(toNeedle: seconds)
    }
    
    public func initializeSavedAudio(withSavedUrl url: URL, mediaInfo: SALockScreenInfo? = nil) {
        self.mediaInfo = mediaInfo
        presenter.handlePlaySavedAudio(withSavedUrl: url)
    }
    
    public func initializeAudio(withRemoteUrl url: URL, mediaInfo: SALockScreenInfo? = nil) {
        self.mediaInfo = mediaInfo
        presenter.handlePlayStreamedAudio(withRemoteUrl: url)
    }
}


//MARK: - Internal implementation of delegate
extension SAPlayer: SAPlayerDelegate {
    func startAudioDownloaded(withSavedUrl url: AudioURL) {
        player?.pause()
        player?.invalidate()
        player = AudioDiskEngine(withSavedUrl: url, delegate: presenter)
    }
    
    func startAudioStreamed(withRemoteUrl url: AudioURL) {
        player?.pause()
        player?.invalidate()
        player = AudioStreamEngine(withRemoteUrl: url, delegate: presenter)
    }
    
    func playEngine() {
        becomeDeviceAudioPlayer()
        player?.play()
    }
    
    //Start taking control as the device's player
    private func becomeDeviceAudioPlayer() {
        do {
            if #available(iOS 11.0, *) {
//                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, policy: .longForm, options: [])
            } else {
                // Fallback on earlier versions
            }
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, mode: AVAudioSessionModeDefault, options: .allowAirPlay)

            try AVAudioSession.sharedInstance().setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            Log.monitor("Problem setting up AVAudioSession to play in:: \(error.localizedDescription)")
        }
    }
    
    func pauseEngine() {
        player?.pause()
    }
    
    func seekEngine(toNeedle needle: Needle) {
        var seekToNeedle = needle < 0 ? 0 : needle
        seekToNeedle = needle > Needle(duration) ? Needle(duration) : needle
        player?.seek(toNeedle: seekToNeedle)
    }
    
    func setSpeedEngine(withMultiple multiple: Double) {
        player?.setSpeed(speed: multiple)
    }
}

