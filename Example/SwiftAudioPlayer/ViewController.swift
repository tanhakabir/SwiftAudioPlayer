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
    struct AudioInfo {
        let index: Int
        
        var url: URL {
            switch index {
            case 0:
                return URL(string: "https://traffic.megaphone.fm/TTH7630150098.mp3")!
            case 1:
                return URL(string: "https://chtbl.com/track/18338/traffic.libsyn.com/secure/acquired/acquired_-_armrev_2.mp3?dest-id=376122")!
            case 2:
                return URL(string: "https://backtracks.fm/ycombinator/pr/0f685f72-29b1-11e9-9bcf-0ece7a7d2472/111---jake-klamka-and-kevin-hale---y-combinator.mp3?s=1&amp;sd=1&amp;u=1549423185")!
            default:
                return URL(string: "https://traffic.megaphone.fm/TTH7630150098.mp3")!
            }
        }
        
        var title: String {
            switch index {
            case 0:
                return "Twenty Thousand Hertz"
            case 1:
                return "Acquired"
            case 2:
                return "Y Combinator"
            default:
                return "Twenty Thousand Hertz"
            }
        }
        
        let artist: String = "SwiftAudioPlayer Sample App"
        let releaseDate: Int = 1550790640
    }
    
    var selectedAudio: AudioInfo = AudioInfo(index: 0) {
        didSet {
            if SAPlayer.Downloader.isDownloaded(withRemoteUrl: selectedAudio.url) {
                downloadButton.setTitle("Delete downloaded", for: .normal)
                streamButton.isEnabled = false
            }
        }
    }
    
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
    
    var timestampRef: UInt?
    var durationRef: UInt?
    var downloadRef: UInt?
    
    var isDownloading: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        adjustSpeed()
        
        playPauseButton.isEnabled = false
        skipBackwardButton.isEnabled = false
        skipForwardButton.isEnabled = false
        
        durationRef = SAPlayer.Updates.Duration.subscribe { [weak self] (url, duration) in
            guard let self = self else { return }
            guard url == self.selectedAudio.url else { return }
            self.durationLabel.text = SAPlayer.prettifyTimestamp(duration)
        }
        
        timestampRef = SAPlayer.Updates.ElapsedTime.subscribe { [weak self] (url, position) in
            guard let self = self else { return }
            guard url == self.selectedAudio.url else { return }
            self.currentTimestampLabel.text = SAPlayer.prettifyTimestamp(position)
        }
        
        downloadRef = SAPlayer.Updates.AudioDownloading.subscribe { [weak self] (url, progress) in
            guard let self = self else { return }
            guard url == self.selectedAudio.url else { return }
            
            if self.isDownloading {
                self.downloadButton.setTitle("Cancel \(String(format: "%02d", (progress * 100)))%", for: .normal)
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
    }
    
    @IBAction func scrubberSeeked(_ sender: Any) {
    }
    
    
    @IBAction func rateChanged(_ sender: Any) {
        adjustSpeed()
    }
    
    @IBAction func downloadTouched(_ sender: Any) {
        if !isDownloading {
            if SAPlayer.Downloader.isDownloaded(withRemoteUrl: selectedAudio.url) {
                SAPlayer.Downloader.deleteDownload(withRemoteUrl: selectedAudio.url)
                downloadButton.setTitle("Download", for: .normal)
                streamButton.isEnabled = true
                isDownloading = false
            } else {
                downloadButton.setTitle("Cancel 0%", for: .normal)
                isDownloading = true
                SAPlayer.Downloader.downloadAudio(withRemoteUrl: selectedAudio.url)
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
    }
    
    private func adjustSpeed() {
        let speed = rateSlider.value
        rateLabel.text = "rate: \(speed)x"
        SAPlayer.shared.rate = Double(speed)
    }
    
}

