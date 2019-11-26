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
    /**
     Access to the player.
     */
    public static let shared: SAPlayer = SAPlayer()
    
    private var presenter: SAPlayerPresenter!
    private var player: AudioEngine?
    
    /**
     Corresponding to the skipping forward button on the media player on the lockscreen. Default is set to 30 seconds.
     */
    public var skipForwardSeconds: Double = 30 {
        didSet {
            presenter.handleScrubbingIntervalsChanged()
        }
    }
    
    /**
     Corresponding to the skipping backwards button on the media player on the lockscreen. Default is set to 15 seconds.
     */
    public var skipBackwardSeconds: Double = 15 {
        didSet {
            presenter.handleScrubbingIntervalsChanged()
        }
    }
    
    /**
     List of [AVAudioUnit](https://developer.apple.com/documentation/avfoundation/audio_track_engineering/audio_engine_building_blocks/audio_enhancements) audio modifiers to pass to the engine on initialization.
     
     - Important: To have the intended effects, the list of modifiers must be finalized before initializing the audio to be played. The modifers are added to the engine in order of the list.
     
     - Note: The default list already has an AVAudioUnitTimePitch node first in the list. This node is specifically set to change the rate of audio without changing the pitch of the audio (intended for changing the rate of spoken word).
     
         The component description of this node is:
         ````
         var componentDescription: AudioComponentDescription {
            get {
                var ret = AudioComponentDescription()
                ret.componentType = kAudioUnitType_FormatConverter
                ret.componentSubType = kAudioUnitSubType_AUiPodTimeOther
                return ret
            }
         }
         ````
         Please look at [forums.developer.apple.com/thread/5874](https://forums.developer.apple.com/thread/5874) and [forums.developer.apple.com/thread/6050](https://forums.developer.apple.com/thread/6050) for more details.
     */
    public var audioModifiers: [AVAudioUnit] = []
    
    /**
     Total duration of current audio initialized. Returns nil if no audio is initialized in player.
     */
    public var duration: Double? {
        get {
            return presenter.duration
        }
    }
    
    /**
     A textual representation of the duration of the current audio initialized. Returns nil if no audio is initialized in player.
     */
    public var prettyDuration: String? {
        get {
            guard let d = duration else { return nil }
            return SAPlayer.prettifyTimestamp(d)
        }
    }
    
    /**
     Elapsed playback time of the current audio initialized. Returns nil if no audio is initialized in player.
     */
    public var elapsedTime: Double? {
        get {
            return presenter.needle
        }
    }
    
    /**
     A textual representation of the elapsed playback time of the current audio initialized. Returns nil if no audio is initialized in player.
     */
    public var prettyElapsedTime: String? {
        get {
            guard let e = elapsedTime else { return nil }
            return SAPlayer.prettifyTimestamp(e)
        }
    }
    
    /**
     Corresponding to the media info to display on the lockscreen for the current audio.
     
     - Note: Setting this to nil clears the information displayed on the lockscreen media player.
     */
    public var mediaInfo: SALockScreenInfo? = nil {
        didSet {
            presenter.handleLockscreenInfo(info: mediaInfo)
        }
    }
    
    private init() {
        presenter = SAPlayerPresenter(delegate: self)
        
        // https://forums.developer.apple.com/thread/5874
        // https://forums.developer.apple.com/thread/6050
        // AVAudioTimePitchAlgorithm.timeDomain (just in case we want it)
        var componentDescription: AudioComponentDescription {
            get {
                var ret = AudioComponentDescription()
                ret.componentType = kAudioUnitType_FormatConverter
                ret.componentSubType = kAudioUnitSubType_AUiPodTimeOther
                return ret
            }
        }
        
        audioModifiers.append(AVAudioUnitTimePitch(audioComponentDescription: componentDescription))
    }
    
    /**
     Formats a textual representation of a given timestamp for display in hh:MM:SS format, that is hours:minutes:seconds.

     - Parameter timestamp: The timestamp to format.
     - Returns: A textual representation of the given timestamp
     */
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
    /**
     Toggles between the play and pause state of the player if the player is not buffering (thus is playable).
     */
    public func togglePlayAndPause() {
        presenter.handleTogglePlayingAndPausing()
    }
    
    /**
     Attempts to play the player even if nothing playable is loaded (aka still in buffering state or no audio is initialized).
     */
    public func play() {
        presenter.handlePlay()
    }
    
    /**
     Attempts to pause the player even if nothing playable is loaded (aka still in buffering state or no audio is initialized).
     */
    public func pause() {
        presenter.handlePause()
    }
    
    /**
     Attempts to skip forward in audio even if nothing playable is loaded (aka still in buffering state or no audio is initialized). The interval to which to skip forward is defined by `SAPlayer.shared.skipForwardSeconds`.
     
     - Note: The skipping is limited to the duration of the audio, if the intended skip is past the duration of the current audio, the skip will just go to the end.
     */
    public func skipForward() {
        presenter.handleSkipForward()
    }
    
    /**
     Attempts to skip backwards in audio even if nothing playable is loaded (aka still in buffering state or no audio is initialized). The interval to which to skip backwards is defined by `SAPlayer.shared.skipBackwardSeconds`.
     
     - Note: The skipping is limited to the playable timestamps, if the intended skip is below 0 seconds, the skip will just go to 0 seconds.
     */
    public func skipBackwards() {
        presenter.handleSkipBackward()
    }
    
    /**
     Attempts to seek/scrub through the audio even if nothing playable is loaded (aka still in buffering state or no audio is initialized).
     
     - Parameter seconds: The intended seconds within the audio to seek to.
     
     - Note: The seeking is limited to the playable timestamps, if the intended seek is below 0 seconds, the skip will just go to 0 seconds. If the intended seek is past the curation of the current audio, the seek will just go to the end.
     */
    public func seekTo(seconds: Double) {
        presenter.handleSeek(toNeedle: seconds)
    }
    
    /**
     If using an AVAudioUnitTimePitch, it's important to notify the player that the rate at which the audio playing has changed to keep the media player in the lockscreen up to date. This is only important for playback rate changes.
     
     - Parameter rate: The current rate at which the audio is playing.
     */
    public func playbackRateOfAudioChanged(rate: Float) {
        presenter.handleAudioRateChanged(rate: rate)
    }
    
    /**
     Sets up player to play audio that has been saved on the device.
     
     - Important: If intending to use [AVAudioUnit](https://developer.apple.com/documentation/avfoundation/audio_track_engineering/audio_engine_building_blocks/audio_enhancements) audio modifiers during playback, the list of audio modifiers under `SAPlayer.shared.audioModifiers` must be finalized before calling this function. After all realtime audio manipulations within the this will be effective.
     
     - Parameter withSavedUrl: The URL of the audio saved on the device.
     - Parameter mediaInfo: The media information of the audio to show on the lockscreen media player (optional).
     */
    public func initializeSavedAudio(withSavedUrl url: URL, mediaInfo: SALockScreenInfo? = nil) {
        self.mediaInfo = mediaInfo
        presenter.handlePlaySavedAudio(withSavedUrl: url)
    }
    
    /**
     Sets up player to play audio that will be streamed from a remote location.
     
     - Important: If intending to use [AVAudioUnit](https://developer.apple.com/documentation/avfoundation/audio_track_engineering/audio_engine_building_blocks/audio_enhancements) audio modifiers during playback, the list of audio modifiers under `SAPlayer.shared.audioModifiers` must be finalized before calling this function. After all realtime audio manipulations within the this will be effective.
     
     - Note: Subscribe to `SAPlayer.Updates.StreamingBuffer` to see updates in streaming progress.
     
     - Parameter withRemoteUrl: The URL of the remote audio.
     - Parameter mediaInfo: The media information of the audio to show on the lockscreen media player (optional).
     */
    public func initializeRemoteAudio(withRemoteUrl url: URL, mediaInfo: SALockScreenInfo? = nil) {
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
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode(rawValue: convertFromAVAudioSessionMode(AVAudioSession.Mode.default)), options: .allowAirPlay)

            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            Log.monitor("Problem setting up AVAudioSession to play in:: \(error.localizedDescription)")
        }
    }
    
    func pauseEngine() {
        player?.pause()
    }
    
    func seekEngine(toNeedle needle: Needle) {
        var seekToNeedle = needle < 0 ? 0 : needle
        seekToNeedle = needle > Needle(duration ?? 0) ? Needle(duration ?? 0) : needle
        player?.seek(toNeedle: seekToNeedle)
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionMode(_ input: AVAudioSession.Mode) -> String {
	return input.rawValue
}
