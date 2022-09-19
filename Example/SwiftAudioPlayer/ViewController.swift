//
//  ViewController.swift
//  SwiftAudioPlayer
//
//  Created by tanhakabir on 01/28/2019.
//  Copyright (c) 2019 tanhakabir. All rights reserved.
//

import AVFoundation
import SwiftAudioPlayerKuama
import UIKit

class ViewController: UIViewController {
    var selectedAudio: AudioInfo = .init(index: 0)

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
    var loopEnabled = false

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

    let engine = AVAudioEngine()

    let longTrackUrl = URL(string: "https://www.fesliyanstudios.com/musicfiles/2019-04-23_-_Trusted_Advertising_-_www.fesliyanstudios.com/15SecVersion2019-04-23_-_Trusted_Advertising_-_www.fesliyanstudios.com.mp3")!

    let yodelTrackUrl = URL(string: "https://s3-us-west-2.amazonaws.com/s.cdpn.io/123941/Yodel_Sound_Effect.mp3")!

    lazy var player = SAPlayer(engine: engine)

    lazy var player1 = SAPlayer(engine: engine)

    lazy var player2 = SAPlayer(engine: engine)

    override func viewDidLoad() {
        super.viewDidLoad()

        SAPlayer.Downloader.allowUsingCellularData = true
        player.HTTPHeaderFields = ["User-Agent": "foobar"]

        player.DEBUG_MODE = true
        player1.DEBUG_MODE = true
        player2.DEBUG_MODE = true
        
        //player.startSavedAudio(withSavedUrl: Bundle.main.url(forResource: "shakerando.mp3", withExtension: "")!)
        //player.startRemoteAudio(withRemoteUrl: longTrackUrl)
        //player.play()

        isPlayable = false

        selectAudio(atIndex: 0)

        addRandomModifiers()

        subscribeToChanges()

        checkIfAudioDownloaded()

        // Uncommment the following to test the "play more than one audio at time"
//        testMultiAudioRemote()
//        testMultiAudioSaved()
    }

    func testMultiAudioRemote() {
        player1.startRemoteAudio(withRemoteUrl: longTrackUrl)
        player2.startRemoteAudio(withRemoteUrl: yodelTrackUrl)
        player1.play()
        player2.play()
    }

    func testMultiAudioSaved() {
        SAPlayer.Downloader.downloadAudio(on: player1, withRemoteUrl: longTrackUrl) { longSavedUrl, _ in

            SAPlayer.Downloader.downloadAudio(on: self.player2, withRemoteUrl: self.yodelTrackUrl) { savedUrl, _ in
                self.player1.startSavedAudio(withSavedUrl: longSavedUrl)
                self.player2.startSavedAudio(withSavedUrl: savedUrl)

                self.player1.play()
                self.player2.play()
            }
        }
    }

    func addRandomModifiers() {
        let node = AVAudioUnitReverb()
        player.audioModifiers.append(node)
        node.wetDryMix = 300
        let frequency: [Int] = [60, 170, 310, 600, 1000, 3000, 6000, 12000, 14000, 16000]
        let node2 = AVAudioUnitEQ(numberOfBands: frequency.count)
        node2.globalGain = 1
        for i in 0 ... (node2.bands.count - 1) {
            node2.bands[i].frequency = Float(frequency[i])
            node2.bands[i].gain = 0
            node2.bands[i].bypass = false
            node2.bands[i].filterType = .parametric
        }
        player.audioModifiers.append(node2)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func audioSelected(_: Any) {
        let selected = audioSelector.selectedSegmentIndex

        selectAudio(atIndex: selected)
    }

    func selectAudio(atIndex i: Int) {
        selectedAudio.setIndex(i)

        if selectedAudio.savedUrl != nil {
            downloadButton.isEnabled = true
            downloadButton.setTitle("Delete downloaded", for: .normal)
            streamButton.isEnabled = false
            player.startSavedAudio(withSavedUrl: selectedAudio.savedUrl!)
            isPlayable = true
        } else {
            downloadButton.isEnabled = true
            downloadButton.setTitle("Download", for: .normal)
            streamButton.isEnabled = true
        }
    }

    func checkIfAudioDownloaded() {
        for i in 0 ... 2 {
            if let savedUrl = SAPlayer.Downloader.getSavedUrl(forRemoteUrl: selectedAudio.getUrl(atIndex: i)) {
                selectedAudio.addSavedUrl(savedUrl, atIndex: i)
            }
        }
    }

    func subscribeToChanges() {
        durationId = SAPlayer.Updates.Duration.subscribe { [weak self] duration in
            guard let self = self else { return }
            self.durationLabel.text = SAPlayer.prettifyTimestamp(duration)
            self.duration = duration
        }

        elapsedId = SAPlayer.Updates.ElapsedTime.subscribe { [weak self] position in
            guard let self = self else { return }

            self.currentTimestampLabel.text = SAPlayer.prettifyTimestamp(position)

            guard self.duration != 0 else { return }

            self.scrubberSlider.value = Float(position / self.duration)
        }

        downloadId = SAPlayer.Updates.AudioDownloading.subscribe(on: player) { [weak self] url, progress in
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

        bufferId = SAPlayer.Updates.StreamingBuffer.subscribe { [weak self] buffer in
            guard let self = self else { return }

            self.bufferProgress.progress = Float(buffer.bufferingProgress)

            if buffer.bufferingProgress >= 0.99 {
                self.streamButton.isEnabled = false
            } else {
                self.streamButton.isEnabled = true
            }

            self.isPlayable = buffer.isReadyForPlaying
        }

        playingStatusId = SAPlayer.Updates.PlayingStatus.subscribe { [weak self] playing in
            guard let self = self else { return }

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
                if !self.loopEnabled {
                    self.isPlayable = false
                    self.playPauseButton.setTitle("Done", for: .normal)
                }
                return
            }
        }

        queueId = SAPlayer.Updates.AudioQueue.subscribe { [weak self] forthcomingPlaybackUrl in
            guard let self = self else { return }
            /// we update the selected audio. this is a little contrived, but allows us to update outlets
            if let indexFound = self.selectedAudio.getIndex(forURL: forthcomingPlaybackUrl) {
                self.selectAudio(atIndex: indexFound)
            }

            self.currentUrlLocationLabel.text = "\(forthcomingPlaybackUrl.absoluteString)"
        }
    }

    func unsubscribeFromChanges() {
        guard let durationId = durationId,
              let elapsedId = elapsedId,
              let downloadId = downloadId,
              let queueId = queueId,
              let bufferId = bufferId,
              let playingStatusId = playingStatusId else { return }

        SAPlayer.Updates.Duration.unsubscribe(durationId)
        SAPlayer.Updates.ElapsedTime.unsubscribe(elapsedId)
        SAPlayer.Updates.AudioDownloading.unsubscribe(downloadId)
        SAPlayer.Updates.AudioQueue.unsubscribe(queueId)
        SAPlayer.Updates.StreamingBuffer.unsubscribe(bufferId)
        SAPlayer.Updates.PlayingStatus.unsubscribe(playingStatusId)
    }

    @IBAction func scrubberStartedSeeking(_: UISlider) {
        beingSeeked = true
    }

    @IBAction func scrubberSeeked(_: Any) {
        let value = Double(scrubberSlider.value) * duration
        player.seekTo(seconds: value)
        beingSeeked = false
    }

    @IBAction func rateChanged(_: Any) {
        let speed = rateSlider.value
        rateLabel.text = "rate: \(speed)x"

        if skipSilencesSwitch.isOn {
            SAPlayer.Features.SkipSilences.setRateSafely(speed, on: player) // if using Skip Silences, we need use this version of setting rate to safely change the rate with the feature enabled.
        } else {
            player.rate = speed
        }
    }

    @IBAction func reverbChanged(_: Any) {
        let reverb = reverbSlider.value
        reverbLabel.text = "reverb: \(reverb)"
        if let node = player.audioModifiers[1] as? AVAudioUnitReverb {
            node.wetDryMix = reverb
        }
    }

    @IBAction func queueTouched(_: Any) {
        if let savedUrl = selectedAudio.savedUrl {
            player.queueSavedAudio(withSavedUrl: savedUrl)
        } else {
            player.queueRemoteAudio(withRemoteUrl: selectedAudio.url)
        }

        print("queue: \(player.audioQueued)")
    }

    @IBAction func downloadTouched(_: Any) {
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
                SAPlayer.Downloader.downloadAudio(on: player, withRemoteUrl: selectedAudio.url, completion: { [weak self] url, error in
                    guard let self = self else { return }
                    guard error == nil else {
                        DispatchQueue.main.async {
                            self.currentUrlLocationLabel.text = "ERROR! \(error!.localizedDescription)"
                        }
                        return
                    }

                    DispatchQueue.main.async {
                        self.currentUrlLocationLabel.text = "saved to: \(url.lastPathComponent)"
                        self.selectedAudio.addSavedUrl(url)
                        self.selectAudio(atIndex: self.selectedAudio.index)
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

    @IBAction func streamTouched(_: Any) {
        if !isStreaming {
            currentUrlLocationLabel.text = "remote url: \(selectedAudio.url.absoluteString)"
            if selectedAudio.index == 2 { // radio
                player.startRemoteAudio(withRemoteUrl: selectedAudio.url, bitrate: .low, mediaInfo: selectedAudio.lockscreenInfo)
            } else {
                player.startRemoteAudio(withRemoteUrl: selectedAudio.url, mediaInfo: selectedAudio.lockscreenInfo)
            }

            lastPlayedAudioIndex = selectedAudio.index
            streamButton.setTitle("Cancel streaming", for: .normal)
            downloadButton.isEnabled = false
            isStreaming = true
        } else {
            player.stopStreamingRemoteAudio()
            streamButton.setTitle("Stream", for: .normal)
            downloadButton.isEnabled = true
            isStreaming = false
        }
    }

    @IBAction func playPauseTouched(_: Any) {
        player.togglePlayAndPause()
    }

    @IBAction func skipBackwardTouched(_: Any) {
        player.skipBackwards()
    }

    @IBAction func skipForwardTouched(_: Any) {
        player.skipForward()
    }

    @IBAction func setEqualizerValue(_ sender: Any) {
        if let slider = sender as? UISlider {
            print("slider of index:", slider.tag, "is changed to", slider.value)
            freq[slider.tag] = Int(slider.value)
            print("current frequency : ", freq)
            if let node = player.audioModifiers[2] as? AVAudioUnitEQ {
                for i in 0 ... (node.bands.count - 1) {
                    node.bands[i].gain = Float(freq[i])
                }
            }
        }
    }

    @IBOutlet var skipSilencesSwitch: UISwitch!

    @IBAction func skipSilencesSwitched(_: Any) {
        if skipSilencesSwitch.isOn {
            _ = SAPlayer.Features.SkipSilences.enable(on: player)
        } else {
            _ = SAPlayer.Features.SkipSilences.disable(on: player)
        }
    }

    @IBOutlet var sleepSwitch: UISwitch!

    @IBAction func sleepSwitched(_: Any) {
        if sleepSwitch.isOn {
            _ = SAPlayer.Features.SleepTimer.enable(afterDelay: 5.0, on: player)
        } else {
            _ = SAPlayer.Features.SleepTimer.disable()
        }
    }

    @IBOutlet var loopSwitch: UISwitch!

    @IBAction func loopSwitched(_: Any) {
        loopEnabled = loopSwitch.isOn

        if loopSwitch.isOn {
            SAPlayer.Features.Loop.enable(on: player)
        } else {
            SAPlayer.Features.Loop.disable()
        }
    }
}
