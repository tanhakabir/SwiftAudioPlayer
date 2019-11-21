//
//  ViewController.swift
//  SwiftAudioPlayer
//
//  Created by tanhakabir on 01/28/2019.
//  Copyright (c) 2019 tanhakabir. All rights reserved.
//

import UIKit
import SwiftAudioPlayer

class ViewController: UIViewController {
    struct AudioInfo: Hashable {
        let index: Int
        
        var url: URL {
            switch index {
            case 0:
                return URL(string: "https://cdn.fastlearner.media/bensound-rumble.mp3")!
            case 1:
                return URL(string: "https://chtbl.com/track/18338/traffic.libsyn.com/secure/acquired/acquired_-_armrev_2.mp3?dest-id=376122")!
            case 2:
                return URL(string: "https://backtracks.fm/ycombinator/pr/0f685f72-29b1-11e9-9bcf-0ece7a7d2472/111---jake-klamka-and-kevin-hale---y-combinator.mp3?s=1&amp;sd=1&amp;u=1549423185")!
            default:
                return URL(string: "https://cdn.fastlearner.media/bensound-rumble.mp3")!
            }
        }
        
        var title: String {
            switch index {
            case 0:
                return "Soundbite"
            case 1:
                return "Acquired"
            case 2:
                return "Y Combinator"
            default:
                return "Soundbite"
            }
        }
        
        let artist: String = "SwiftAudioPlayer Sample App"
        let releaseDate: Int = 1550790640
    }
    
    var savedUrls: [AudioInfo: URL] = [:]
    
    var selectedAudio: AudioInfo = AudioInfo(index: 0) {
        didSet {
            if SAPlayer.Downloader.isDownloaded(withRemoteUrl: selectedAudio.url) {
                downloadButton.setTitle("Delete downloaded", for: .normal)
                streamButton.isEnabled = false
            } else {
                downloadButton.setTitle("Download", for: .normal)
                streamButton.isEnabled = true
            }
            
            self.currentUrlLocationLabel.text = "remote url: \(selectedAudio.url.absoluteString)"
        }
    }
    
    @IBOutlet weak var currentUrlLocationLabel: UILabel!
    @IBOutlet weak var bufferProgress: UIProgressView!
    @IBOutlet weak var scrubberSlider: UISlider!
    
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var skipBackwardButton: UIButton!
    @IBOutlet weak var skipForwardButton: UIButton!
    
    @IBOutlet weak var audioSelector: UISegmentedControl!
    @IBOutlet weak var streamButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var rateSlider: UISlider!
    
    @IBOutlet weak var rateLabel: UILabel!
    
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var currentTimestampLabel: UILabel!
    
    var isDownloading: Bool = false
    var isStreaming: Bool = false
    var beingSeeked: Bool = false
    
    var duration: Double = 0.0
    
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
        
        adjustSpeed()
        
        isPlayable = false
        selectedAudio = AudioInfo(index: 0)
        
        _ = SAPlayer.Updates.Duration.subscribe { [weak self] (url, duration) in
            guard let self = self else { return }
            guard url == self.selectedAudio.url || url == self.savedUrls[self.selectedAudio] else { return }
            self.durationLabel.text = SAPlayer.prettifyTimestamp(duration)
            self.duration = duration
        }
        
        _ = SAPlayer.Updates.ElapsedTime.subscribe { [weak self] (url, position) in
            guard let self = self else { return }
            if self.beingSeeked == false{
                guard url == self.selectedAudio.url || url == self.savedUrls[self.selectedAudio] else { return }
                
                self.currentTimestampLabel.text = SAPlayer.prettifyTimestamp(position)
                
                guard self.duration != 0 else { return }
                
                self.scrubberSlider.value = Float(position/self.duration)
            }
        }
        
        _ = SAPlayer.Updates.AudioDownloading.subscribe { [weak self] (url, progress) in
            guard let self = self else { return }
            guard url == self.selectedAudio.url else { return }
            
            if self.isDownloading {
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        self.downloadButton.setTitle("Cancel \(String(format: "%.2f", (progress * 100)))%", for: .normal)
                    }
                }
            }
        }
        
        _ = SAPlayer.Updates.StreamingBuffer.subscribe{ [weak self] (url, buffer) in
            guard let self = self else { return }
            guard url == self.selectedAudio.url || url == self.savedUrls[self.selectedAudio] else { return }
            
            if self.duration == 0.0 { return }
            
            let progress = Float((buffer.totalDurationBuffered + buffer.startingBufferTimePositon) / self.duration)
            
            self.bufferProgress.progress = progress
            
            if progress >= 0.99 {
                self.streamButton.isEnabled = false
            }
            
            self.isPlayable = buffer.isReadyForPlaying
        }
        
        _ = SAPlayer.Updates.PlayingStatus.subscribe { [weak self] (url, playing) in
            guard let self = self else { return }
            guard url == self.selectedAudio.url || url == self.savedUrls[self.selectedAudio] else { return }
            
            if playing {
                self.playPauseButton.setTitle("Pause", for: .normal)
            } else {
                self.playPauseButton.setTitle("Play", for: .normal)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func audioSelected(_ sender: Any) {
        let selected = audioSelector.selectedSegmentIndex
        
        selectedAudio = AudioInfo(index: selected)
        
        SAPlayer.shared.mediaInfo = SALockScreenInfo(title: selectedAudio.title, artist: selectedAudio.artist, artwork: UIImage(), releaseDate: selectedAudio.releaseDate)
        
        //        if let savedUrl = savedUrls[selectedAudio] {}
    }
    @IBAction func beingScrubberSeeked(_ sender: UISlider) {
        beingSeeked = true
    }
    
    @IBAction func scrubberSeeked(_ sender: Any) {
        let value = Double(scrubberSlider.value) * duration
        SAPlayer.shared.seekTo(seconds: value)
        beingSeeked = false
        SAPlayer.shared.play()
    }
    
    
    @IBAction func rateChanged(_ sender: Any) {
        adjustSpeed()
    }
    
    @IBAction func downloadTouched(_ sender: Any) {
        if !isDownloading {
            if let savedUrl = SAPlayer.Downloader.getSavedUrl(forRemoteUrl: selectedAudio.url) {
                SAPlayer.Downloader.deleteDownloaded(withSavedUrl: savedUrl)
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
                        self.savedUrls[self.selectedAudio] = url
                        
                        SAPlayer.shared.initializeSavedAudio(withSavedUrl: url)
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
            SAPlayer.shared.initializeAudio(withRemoteUrl: selectedAudio.url)
            streamButton.setTitle("Cancel streaming", for: .normal)
            downloadButton.isEnabled = false
        } else {
            // TODO
        }
    }
    
    @IBAction func playPauseTouched(_ sender: Any) {
        SAPlayer.shared.togglePlayAndPause()
    }
    
    @IBAction func skipBackwardTouched(_ sender: Any) {
        SAPlayer.shared.skipBackwards()
    }
    
    @IBAction func skipForwardTouched(_ sender: Any) {
        SAPlayer.shared.skipForward()
    }
    
    private func adjustSpeed() {
        let speed = rateSlider.value
        rateLabel.text = "rate: \(speed)x"
        SAPlayer.shared.rate = Double(speed)
    }
    
}

