//
//  LockScreenViewProtocol.swift
//  Pods-SwiftAudioPlayer_Example
//
//  Created by Tanha Kabir on 2019-01-29.
//

import Foundation
import MediaPlayer
import UIKit

// MARK: - Set up lockscreen audio controls
// Documentation: https://developer.apple.com/documentation/avfoundation/media_assets_playback_and_editing/creating_a_basic_video_player_ios_and_tvos/controlling_background_audio
protocol LockScreenViewProtocol {
}

extension LockScreenViewProtocol {
//    func setLockScreenInfo(withEpisode vto: EpisodeVTO, duration: Duration) {
//        var nowPlayingInfo:[String : Any] = [:]
//        
//        let episodeName = vto.getName()
//        let podcastName = vto.getPodcastName()
//        let releaseDate = vto.getPublicationDate()
//        
//        // For some reason we need to set a duration here for the needle?
//        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(floatLiteral: duration)
//        
//        nowPlayingInfo[MPMediaItemPropertyTitle] = episodeName
//        nowPlayingInfo[MPMediaItemPropertyArtist] = podcastName
//        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = podcastName
//        //nowPlayingInfo[MPMediaItemPropertyGenre] = //maybe later when we have it
//        //nowPlayingInfo[MPMediaItemPropertyIsExplicit] = //maybe later when we have it
//        nowPlayingInfo[MPMediaItemPropertyAlbumArtist] = podcastName
//        nowPlayingInfo[MPMediaItemPropertyMediaType] = MPMediaType.podcast.rawValue
//        nowPlayingInfo[MPMediaItemPropertyPodcastTitle] = episodeName
//        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0 //because default is 1.0. If we pause audio then it keeps ticking
//        nowPlayingInfo[MPMediaItemPropertyReleaseDate] = Date(timeIntervalSince1970: TimeInterval(releaseDate))
//        if let episodeImage = vto.getEpisodeImage() {
//            nowPlayingInfo[MPMediaItemPropertyArtwork] =
//                MPMediaItemArtwork(boundsSize: episodeImage.size) { size in
//                    return episodeImage
//            }
//        }
//        
//        
//        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
//    }
    
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
                presenter.play()
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
                presenter.pause()
                return .success
            }
            
            return .commandFailed
        }
        
        commandCenter.skipBackwardCommand.preferredIntervals = [SAPlayerPresenter.SKIP_BACKWARDS_SECONDS] as [NSNumber]
        commandCenter.skipForwardCommand.preferredIntervals = [SAPlayerPresenter.SKIP_FORWARD_SECONDS] as [NSNumber]
        
        commandCenter.skipBackwardCommand.addTarget { [weak presenter] event in
            guard let presenter = presenter else {
                return .commandFailed
            }
            presenter.skipBackward()
            return .success
        }
        
        commandCenter.skipForwardCommand.addTarget { [weak presenter] event in
            guard let presenter = presenter else {
                return .commandFailed
            }
            presenter.skipForward()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak presenter] event in
            guard let presenter = presenter else {
                return .commandFailed
            }
            if let positionEvent = event as? MPChangePlaybackPositionCommandEvent {
                presenter.seek(toNeedle: Needle(positionEvent.positionTime))
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
}
