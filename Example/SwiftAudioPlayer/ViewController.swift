//
//  ViewController.swift
//  SwiftAudioPlayer
//
//  Created by tanhakabir on 01/28/2019.
//  Copyright (c) 2019 tanhakabir. All rights reserved.
//

import AVFoundation
import SwiftAudioPlayer
import UIKit

class ViewController: UIViewController {
    var selectedAudio = AudioInfo(index: 0)
    
    var freq: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    @IBOutlet var currentUrlLocationLabel: UILabel!
    @IBOutlet var bufferProgress: UIProgressView!
    @IBOutlet var scrubberSlider: UISlider!
    
    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var skipBackwardButton: UIButton!
    @IBOutlet var skipForwardButton: UIButton!
    
    @IBOutlet var audioSelector: UISegmentedControl!
    @IBOutlet var streamButton: UIButton!
    @IBOutlet var downloadButton: UIButton!
    @IBOutlet var rateSlider: UISlider!
    
    @IBOutlet var rateLabel: UILabel!
    
    @IBOutlet var reverbLabel: UILabel!
    @IBOutlet var reverbSlider: UISlider!
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var currentTimestampLabel: UILabel!
    
    var isDownloading: Bool = false
    var isStreaming: Bool = false
    var beingSeeked: Bool = false
    
    var downloadId: UInt?
    var durationId: UInt?
    var bufferId: UInt?
    var playingStatusId: UInt?
    var queueId: UInt?
    var elapsedId: UInt?

    var duration: Double = 0.0
    var playbackStatus: SAPlayingStatus = .paused
    
    var lastPlayedAudioIndex: Int?
    
    var isPlayable: Bool = false {
        didSet {
            if isPlayable {
                playPauseButton.isEnabled = true
                skipBackwardButton.isEnabled = true
                skipForwardButton.isEnabled = true
            } else {
                playPauseButton.isEnabled = false
                skipBackwardButton.isEnabled = false
                skipForwardButton.isEnabled = false
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let node = AVAudioUnitReverb()
        SAPlayer.shared.audioModifiers.append(node)
        node.wetDryMix = 300
        
        SAPlayer.Downloader.allowUsingCellularData = true
        
//        SAPlayer.shared.DEBUG_MODE = true
        
        isPlayable = false
        checkIfAudioDownloaded()
        selectAudio(atIndex: 0)
        
//        addRandomModifiers()
        
        subscribeToChanges()
    }
    
    func addRandomModifiers() {
        let node = AVAudioUnitReverb()
        SAPlayer.shared.audioModifiers.append(node)
        node.wetDryMix = 300
        let frequency: [Int] = [60, 170, 310, 600, 1000, 3000, 6000, 12000, 14000, 16000]
        let node2 = AVAudioUnitEQ(numberOfBands: frequency.count)
        node2.globalGain = 1
        for i in 0...(node2.bands.count - 1) {
            node2.bands[i].frequency = Float(frequency[i])
            node2.bands[i].gain = 0
            node2.bands[i].bypass = false
            node2.bands[i].filterType = .parametric
        }
        SAPlayer.shared.audioModifiers.append(node2)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func audioSelected(_ sender: Any) {
        let selected = audioSelector.selectedSegmentIndex
        
        selectAudio(atIndex: selected)
    }
    
    func selectAudio(atIndex i: Int) {
        selectedAudio.setIndex(i)
        
        if selectedAudio.savedUrl != nil {
            downloadButton.setTitle("Delete downloaded", for: .normal)
            streamButton.isEnabled = false
        } else {
            downloadButton.setTitle("Download", for: .normal)
            streamButton.isEnabled = true
        }
        
        if let savedUrl = selectedAudio.savedUrl {
            currentUrlLocationLabel.text = "saved url: \(savedUrl.absoluteString)"
        } else {
            currentUrlLocationLabel.text = "remote url: \(selectedAudio.url.absoluteString)"
        }
        
        //        if let savedUrl = savedUrls[selectedAudio] {}
        scrubberSlider.value = 0
        bufferProgress.progress = 0
        
//        unsubscribeFromChanges()
//        subscribeToChanges()
        
        SAPlayer.shared.mediaInfo = SALockScreenInfo(title: selectedAudio.title, artist: selectedAudio.artist, artwork: UIImage(), releaseDate: selectedAudio.releaseDate)
    }
    
    func checkIfAudioDownloaded() {
        for i in 0...2 {
            if let savedUrl = SAPlayer.Downloader.getSavedUrl(forRemoteUrl: selectedAudio.getUrl(atIndex: i)) {
                selectedAudio.addSavedUrl(savedUrl, atIndex: i)
            }
        }
    }
    
    func subscribeToChanges() {
        durationId = SAPlayer.Updates.Duration.subscribe { [weak self] url, duration in
            guard let self = self else { return }
            guard url == self.selectedAudio.savedUrl || url == self.selectedAudio.url else { return }
            self.durationLabel.text = SAPlayer.prettifyTimestamp(duration)
            self.duration = duration
        }
        
        elapsedId = SAPlayer.Updates.ElapsedTime.subscribe { [weak self] url, position in
            guard let self = self else { return }
            guard url == self.selectedAudio.savedUrl || url == self.selectedAudio.url else { return }
            
            self.currentTimestampLabel.text = SAPlayer.prettifyTimestamp(position)
            
            guard self.duration != 0 else { return }
            
            self.scrubberSlider.value = Float(position / self.duration)
        }
        
        downloadId = SAPlayer.Updates.AudioDownloading.subscribe { [weak self] url, progress in
            guard let self = self else { return }
            guard url == self.selectedAudio.url else { return }
            
            if self.isDownloading {
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        self.downloadButton.setTitle("Cancel \(String(format: "%.2f", progress * 100))%", for: .normal)
                    }
                }
            }
        }
        
        bufferId = SAPlayer.Updates.StreamingBuffer.subscribe { [weak self] url, buffer in
            guard let self = self else { return }
            guard url == self.selectedAudio.savedUrl || url == self.selectedAudio.url else { return }
            
            if self.duration == 0.0 { return }
            
            self.bufferProgress.progress = Float(buffer.bufferingProgress)
            
            if buffer.bufferingProgress >= 0.99 {
                self.streamButton.isEnabled = false
            } else {
                self.streamButton.isEnabled = true
            }
            
            self.isPlayable = buffer.isReadyForPlaying
        }
        
        playingStatusId = SAPlayer.Updates.PlayingStatus.subscribe { [weak self] url, playing in
            guard let self = self else { return }
            guard url == self.selectedAudio.savedUrl || url == self.selectedAudio.url else { return }
            
            self.playbackStatus = playing
            
            switch playing {
            case .playing:
                self.isPlayable = true
                self.playPauseButton.setTitle("Pause", for: .normal)
                return
            case .paused:
                self.isPlayable = true
                self.playPauseButton.setTitle("Play", for: .normal)
                return
            case .buffering:
                self.isPlayable = false
                self.playPauseButton.setTitle("Loading", for: .normal)
                return
            case .ended:
                self.isPlayable = false
                self.playPauseButton.setTitle("Done", for: .normal)
                return
            }
        }
        
        queueId = SAPlayer.Updates.AudioQueue.subscribe { [weak self] _, forthcomingPlaybackUrl in
            guard let self = self else { return }
            /// we update the selected audio. this is a little contrived, but allows us to update outlets
            if let indexFound = self.selectedAudio.getIndex(forURL: forthcomingPlaybackUrl) {
                self.selectAudio(atIndex: indexFound)
            }
            print("💥 Received queue update 💥")
        }
    }
    
    func unsubscribeFromChanges() {
        guard let durationId = self.durationId,
              let elapsedId = self.elapsedId,
              let downloadId = self.downloadId,
              let queueId = self.queueId,
              let bufferId = self.bufferId,
              let playingStatusId = self.playingStatusId else { return }
        
        SAPlayer.Updates.Duration.unsubscribe(durationId)
        SAPlayer.Updates.ElapsedTime.unsubscribe(elapsedId)
        SAPlayer.Updates.AudioDownloading.unsubscribe(downloadId)
        SAPlayer.Updates.AudioQueue.unsubscribe(queueId)
        SAPlayer.Updates.StreamingBuffer.unsubscribe(bufferId)
        SAPlayer.Updates.PlayingStatus.unsubscribe(playingStatusId)
    }
    
    @IBAction func scrubberStartedSeeking(_ sender: UISlider) {
        beingSeeked = true
    }
    
    @IBAction func scrubberSeeked(_ sender: Any) {
        let value = Double(scrubberSlider.value) * duration
        SAPlayer.shared.seekTo(seconds: value)
        beingSeeked = false
    }
    
    @IBAction func rateChanged(_ sender: Any) {
        let speed = rateSlider.value
        rateLabel.text = "rate: \(speed)x"
        
        if skipSilencesSwitch.isOn {
            SAPlayer.Features.SkipSilences.setRateSafely(speed) // if using Skip Silences, we need use this version of setting rate to safely change the rate with the feature enabled.
        } else {
            SAPlayer.shared.rate = speed
        }
    }

    @IBAction func reverbChanged(_ sender: Any) {
        if let node = SAPlayer.shared.audioModifiers[1] as? AVAudioUnitReverb {
            let reverb = reverbSlider.value
            reverbLabel.text = "reverb: \(reverb)"
            node.wetDryMix = reverbSlider.value
        }
    }

    @IBAction func queueTouched(_ sender: Any) {
        if let savedUrl = selectedAudio.savedUrl {
            SAPlayer.shared.queueSavedAudio(withSavedUrl: savedUrl)
        } else {
            SAPlayer.shared.queueRemoteAudio(withRemoteUrl: selectedAudio.url)
        }
        
        print("queue: \(SAPlayer.shared.audioQueued)")
    }
    
    @IBAction func downloadTouched(_ sender: Any) {
        if !isDownloading {
            if let savedUrl = SAPlayer.Downloader.getSavedUrl(forRemoteUrl: selectedAudio.url) {
                SAPlayer.Downloader.deleteDownloaded(withSavedUrl: savedUrl)
                selectedAudio.deleteSavedUrl()
                downloadButton.setTitle("Download", for: .normal)
                streamButton.isEnabled = true
                isDownloading = false
            } else {
                downloadButton.setTitle("Cancel 0%", for: .normal)
                isDownloading = true
                SAPlayer.Downloader.downloadAudio(withRemoteUrl: selectedAudio.url, completion: { [weak self] url in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.currentUrlLocationLabel.text = "saved to: \(url.lastPathComponent)"
                        self.selectedAudio.addSavedUrl(url)
                        
                        SAPlayer.shared.startSavedAudio(withSavedUrl: url, mediaInfo: self.selectedAudio.lockscreenInfo)
                        self.lastPlayedAudioIndex = self.selectedAudio.index
                    }
                })
                streamButton.isEnabled = false
            }
        } else {
            SAPlayer.Downloader.cancelDownload(withRemoteUrl: selectedAudio.url)
            downloadButton.setTitle("Download", for: .normal)
            streamButton.isEnabled = true
            isDownloading = false
        }
    }
    
    @IBAction func streamTouched(_ sender: Any) {
        if !isStreaming {
            if selectedAudio.index == 2 { // radio
                SAPlayer.shared.startRemoteAudio(withRemoteUrl: selectedAudio.url, bitrate: .low, mediaInfo: selectedAudio.lockscreenInfo)
            } else {
                SAPlayer.shared.startRemoteAudio(withRemoteUrl: selectedAudio.url, mediaInfo: selectedAudio.lockscreenInfo)
            }

            lastPlayedAudioIndex = selectedAudio.index
            streamButton.setTitle("Cancel streaming", for: .normal)
            downloadButton.isEnabled = false
            isStreaming = true
        } else {
            SAPlayer.shared.stopStreamingRemoteAudio()
            streamButton.setTitle("Stream", for: .normal)
            downloadButton.isEnabled = true
            isStreaming = false
        }
    }
    
    @IBAction func playPauseTouched(_ sender: Any) {
//        if lastPlayedAudioIndex != selectedAudio.index {
//            if let savedUrl = selectedAudio.savedUrl {
//                SAPlayer.shared.startSavedAudio(withSavedUrl: savedUrl)
//            } else {
//                SAPlayer.shared.startRemoteAudio(withRemoteUrl: selectedAudio.url)
//            }
//
//            return
//        }
        
        SAPlayer.shared.togglePlayAndPause()
    }
    
    @IBAction func skipBackwardTouched(_ sender: Any) {
        SAPlayer.shared.skipBackwards()
    }
    
    @IBAction func skipForwardTouched(_ sender: Any) {
        SAPlayer.shared.skipForward()
    }

    @IBAction func setEqualizerValue(_ sender: Any) {
        if let slider = sender as? UISlider {
            print("slider of index:", slider.tag, "is changed to", slider.value)
            freq[slider.tag] = Int(slider.value)
            print("current frequency : ", freq)
            if let node = SAPlayer.shared.audioModifiers[2] as? AVAudioUnitEQ {
                for i in 0...(node.bands.count - 1) {
                    node.bands[i].gain = Float(freq[i])
                }
            }
        }
    }
    
    @IBOutlet var skipSilencesSwitch: UISwitch!
    
    @IBAction func skipSilencesSwitched(_ sender: Any) {
        if skipSilencesSwitch.isOn {
            _ = SAPlayer.Features.SkipSilences.enable()
        } else {
            _ = SAPlayer.Features.SkipSilences.disable()
        }
    }

    @IBOutlet var sleepSwitch: UISwitch!
    
    @IBAction func sleepSwitched(_ sender: Any) {
        if sleepSwitch.isOn {
            _ = SAPlayer.Features.SleepTimer.enable(afterDelay: 5.0)
        } else {
            _ = SAPlayer.Features.SleepTimer.disable()
        }
    }
}
