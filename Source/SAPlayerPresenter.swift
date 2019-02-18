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
    public static let SKIP_FORWARD_SECONDS: Double = 30
    public static let SKIP_BACKWARDS_SECONDS: Double = 15
    private let ID: String = #file.description
    
    weak var delegate: SAPlayerDelegate?
    var shouldPlayImmediately = false //for auto-play
    
    fileprivate var needle: Needle?
    fileprivate var isPlaying = false
    
    var durationRef:UInt = 0
    var needleRef:UInt = 0
    var playingStatusRef:UInt = 0
    
    init(delegate: SAPlayerDelegate?) {
        self.delegate = delegate
        
        delegate?.setLockScreenControls(presenter: self)
        
        prepareNextEpisodeToPlay()
    }
    
    func handlePlayAudio(withRemoteUrl url: URL) {
        if let savedUrl = AudioDataManager.shared.getPersistedUrl(withRemoteURL: url) {
            delegate?.startAudioDownloaded(withSavedUrl: savedUrl)
        } else {
            delegate?.startAudioStreamed(withRemoteUrl: url)
        }
    }
    
    @available(iOS 10.0, *)
    func handleLockscreenInfo(info: SALockScreenInfo) {
//        delegate?.setLockScreenInfo(withMediaInfo: info, duration: <#T##Duration#>)
    }
    
//    private func newEpisodeArrived(episode: EpisodePTO) {
//
//        mapper.fetchHistory(withEpisodeKey: key) { [weak self] (historyPTO: HistoryPTO?) in
//            guard let _ = self else {return}
//            self?.historyArrived(withHistory: historyPTO)
//        }
//
//
//        AudioClockDirector.sharedInstance.detachFromChangesInDuration(withID: durationRef)
//        AudioClockDirector.sharedInstance.detachFromChangesInNeedle(withID: needleRef)
//        AudioClockDirector.sharedInstance.detachFromChangesInPlayingStatus(withID: playingStatusRef)
//
//        durationRef = AudioClockDirector.sharedInstance.attachToChangesInDuration { [weak self] (payload: (Key, Duration)) in
//            guard let _ = self else { throw DirectorError.closureIsDead }
//            guard payload.0 == self?.episode?.getKey() else {
//                Log.debug("misfire eKey: \(self?.episode?.getKey() ?? "none") payload: \(payload.0)")
//                return
//            }
//
//            self?.delegate?.updateLockscreenPlaybackDuration(duration: payload.1)
//
//            guard let e = self?.episode else { return }
//            self?.delegate?.setLockScreenInfo(withEpisode: EpisodeVTO(pto: e), duration: payload.1)
//        }
//
//        needleRef = AudioClockDirector.sharedInstance.attachToChangesInNeedle { [weak self] (payload: (Key, Needle)) in
//            guard let _ = self else { throw DirectorError.closureIsDead }
//            guard payload.0 == self?.episode?.getKey() else {
//                Log.debug("misfire eKey: \(self?.episode?.getKey() ?? "none") payload: \(payload.0)")
//                return
//            }
//
//            self?.needle = payload.1
//            self?.delegate?.updateLockscreenElapsedTime(needle: payload.1)
//        }
//
//        playingStatusRef = AudioClockDirector.sharedInstance.attachToChangesInPlayingStatus { [weak self] (payload: (Key, IsPlaying)) in
//            guard let _ = self else { throw DirectorError.closureIsDead }
//            guard payload.0 == self?.episode?.getKey() else {
//                Log.debug("misfire eKey: \(self?.episode?.getKey() ?? "none") payload: \(payload.0)")
//                return
//            }
//
//            self?.isPlaying = payload.1
//        }
//    }
}

//MARK:- Used by outside world including:
// SPP, lock screen, directors
extension SAPlayerPresenter {
    func handlePause() {
        delegate?.pauseEngine()
    }
    
    func handlePlay() {
        delegate?.playEngine()
    }
    
    func handleTogglePlayingAndPausing() {
        if isPlaying {
            handlePause()
        } else {
            handlePlay()
        }
    }
    
    func handleSkipForward() {
        handleSeek(toNeedle: (needle ?? 0) + SAPlayerPresenter.SKIP_FORWARD_SECONDS)
    }
    
    func handleSkipBackward() {
        handleSeek(toNeedle: (needle ?? 0) - SAPlayerPresenter.SKIP_BACKWARDS_SECONDS)
    }
    
    func handleSeek(toNeedle needle: Needle) {
        delegate?.seekEngine(toNeedle: needle)
    }
    
    func handleSetSpeed(withMultiple: Double) {
        delegate?.setSpeedEngine(withMultiple: withMultiple)
    }
}

//MARK:- For lock screen
extension SAPlayerPresenter {
    func getIsPlaying() -> Bool {
        return isPlaying
    }
}

//MARK:- AVAudioEngineDelegate
extension SAPlayerPresenter: AudioEngineDelegate {
    func didError() {
        Log.monitor("We should have handled engine error")
    }
    
    func didEndPlaying() {
        playNextEpisode()
    }
}

//MARK:- Play Next Episode
//FIXME: This needs to be refactored
extension SAPlayerPresenter {
    func prepareNextEpisodeToPlay() {
        // TODO
    }
    
    /**
     - In shortlist
     - AND with UTC added less than current episode UTC
     - AND downloaded
     - AND has no history
     */
    func playNextEpisode() {
        shouldPlayImmediately = false
//        guard mapper.fetchShouldAutoplay() else {
//            return
//        }
//
//        guard let episode = episode, let shortlist = shortlist else {
//            Log.warn("should not be hitting end of episode if no such episode exists!")
//            return
//        }
//
//        let currentEpisodeKey = episode.getKey()
//        let keysAfterCurrentEpisode = shortlist.getSortedPinnedEpisodesAfter(afterEpisode: currentEpisodeKey)
//        let downloadedKeys = keysAfterCurrentEpisode.filter{mapper.isAudioDownloaded(withEpisodeKey: $0)}
//        playNextEpisodeWithNoHistory(fromListOfEpisodes: downloadedKeys)
    }
    
//    private func playNextEpisodeWithNoHistory(fromListOfEpisodes keys: [KeyEpisode]) {
//        guard keys.count > 0 else {
//            Log.info("no list of episodes to play next 32453")
//            return
//        }
//
//        playNextEpisodeWithNoHistoryHelper(index: 0, keys: keys)
//    }
    
//    private func playNextEpisodeWithNoHistoryHelper(index: Int, keys: [KeyEpisode]) {
//        guard index < keys.count else {
//            return
//        }
//        
//        mapper.fetchHistory(withEpisodeKey: keys[index]) { (pto: HistoryPTO?) in
//            if pto == nil {
//                if self.shouldPlayImmediately {
//                    //FIXME This is a hack because for some reason an episode is played twice within a second.
//                    return
//                }
//                self.shouldPlayImmediately = true
//                self.delegate?.seek(toNeedle: 0)
//                EpisodeDirector.sharedInstance.setEpisode(key: keys[index])
//                self.mapper.pinEpisode(withKey: keys[index])
//            } else {
//                self.playNextEpisodeWithNoHistoryHelper(index: index+1, keys: keys)
//            }
//        }
//    }
}
