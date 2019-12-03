//
//  LockScreenViewProtocol.swift
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
import MediaPlayer
import UIKit

// MARK: - Set up lockscreen audio controls
// Documentation: https://developer.apple.com/documentation/avfoundation/media_assets_playback_and_editing/creating_a_basic_video_player_ios_and_tvos/controlling_background_audio
protocol LockScreenViewProtocol {
    var skipForwardSeconds: Double { get set }
    var skipBackwardSeconds: Double { get set }
}

extension LockScreenViewProtocol {
    func clearLockScreenInfo() {
         MPNowPlayingInfoCenter.default().nowPlayingInfo = [:]
    }
    
    @available(iOS 10.0, *)
    func setLockScreenInfo(withMediaInfo info: SALockScreenInfo?, duration: Duration) {
        var nowPlayingInfo:[String : Any] = [:]
        
        guard let info = info else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [:]
            return
        }
        
        let title = info.title
        let artist = info.artist
        let releaseDate = info.releaseDate
        
        // For some reason we need to set a duration here for the needle?
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(floatLiteral: duration)
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = artist
        //nowPlayingInfo[MPMediaItemPropertyGenre] = //maybe later when we have it
        //nowPlayingInfo[MPMediaItemPropertyIsExplicit] = //maybe later when we have it
        nowPlayingInfo[MPMediaItemPropertyAlbumArtist] = artist
        nowPlayingInfo[MPMediaItemPropertyMediaType] = MPMediaType.podcast.rawValue
        nowPlayingInfo[MPMediaItemPropertyPodcastTitle] = title
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0 //because default is 1.0. If we pause audio then it keeps ticking
        nowPlayingInfo[MPMediaItemPropertyReleaseDate] = Date(timeIntervalSince1970: TimeInterval(releaseDate))

        if let artwork = info.artwork {
            nowPlayingInfo[MPMediaItemPropertyArtwork] =
            MPMediaItemArtwork(boundsSize: artwork.size) { size in
                return artwork
            }
        } else {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: UIImage().size) { size in
                return UIImage()
            }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    // https://stackoverflow.com/questions/36754934/update-mpremotecommandcenter-play-pause-button
    func setLockScreenControls(presenter: SAPlayerPresenter) { //FIXME: this is weird
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [weak presenter] event in
            guard let presenter = presenter else {
                return .commandFailed
            }
            
            if !presenter.getIsPlaying() {
                presenter.handlePlay()
                return .success
            }
            
            return .commandFailed
        }
        
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [weak presenter] event in
            guard let presenter = presenter else {
                return .commandFailed
            }
            
            if presenter.getIsPlaying() {
                presenter.handlePause()
                return .success
            }
            
            return .commandFailed
        }
        
        commandCenter.skipBackwardCommand.preferredIntervals = [skipBackwardSeconds] as [NSNumber]
        commandCenter.skipForwardCommand.preferredIntervals = [skipForwardSeconds] as [NSNumber]
        
        commandCenter.skipBackwardCommand.addTarget { [weak presenter] event in
            guard let presenter = presenter else {
                return .commandFailed
            }
            presenter.handleSkipBackward()
            return .success
        }
        
        commandCenter.skipForwardCommand.addTarget { [weak presenter] event in
            guard let presenter = presenter else {
                return .commandFailed
            }
            presenter.handleSkipForward()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak presenter] event in
            guard let presenter = presenter else {
                return .commandFailed
            }
            if let positionEvent = event as? MPChangePlaybackPositionCommandEvent {
                presenter.handleSeek(toNeedle: Needle(positionEvent.positionTime))
                return .success
            }
            
            return .commandFailed
        }
    }
    
    func updateLockscreenElapsedTime(needle: Needle) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: Double(needle))
    }
    
    func updateLockscreenPlaybackDuration(duration: Duration) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: duration)
    }
    
    func updateLockscreenPaused(){
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
    }
    
    func updateLockscreenPlaying(){
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
    }
    
    func updateLockscreenChangePlaybackRate(speed: Float){
        if speed > 0.0{
            MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = speed
        }
    }
    
    func updateLockscreenSkipIntervals() {
        MPRemoteCommandCenter.shared().skipBackwardCommand.preferredIntervals = [skipBackwardSeconds] as [NSNumber]
        MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [skipForwardSeconds] as [NSNumber]
    }
}
