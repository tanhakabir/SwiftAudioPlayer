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
    
    public var rate: Double = 1.0 {
        didSet {
            Log.test("foo")
        }
    }
    
    private init() {
        presenter = SAPlayerPresenter(delegate: self)
    }
    
    func create() {
        //do nothing
    }
    
    func togglePlayPause() {
    }
}


extension SAPlayer: SAPlayerDelegate {
    func startAudioDownloaded(withRemoutUrl url: AudioURL) {
        player?.pause()
        player?.invalidate()
        player = AudioDiskEngine(withRemoteUrl: url, delegate: presenter)
    }
    
    func startAudioStreamed(withRemoutUrl url: AudioURL) {
        player?.pause()
        player?.invalidate()
        player = AudioStreamEngine(withRemoteUrl: url, delegate: presenter)
    }
    
    func play() {
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
            try AVAudioSession.sharedInstance().setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            Log.monitor("Problem setting up AVAudioSession to play in:: \(error.localizedDescription)")
        }
    }
    
    func pause() {
        player?.pause()
    }
    
    func seek(toNeedle needle: Needle) {
        player?.seek(toNeedle: needle)
    }
    
    func setSpeed(withMultiple multiple: Double) {
        player?.setSpeed(speed: multiple)
    }
}

