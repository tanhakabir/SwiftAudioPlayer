//
//  AudioEngine.swift
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

protocol AudioEngineProtocol {
    func play()
    func pause()
    func seek(toNeedle needle: Needle)
    func setSpeed(speed: Double)
    func invalidate()
}

protocol AudioEngineDelegate: AnyObject {
    func didEndPlaying() //for auto play
    func didError()
}

class AudioEngine: AudioEngineProtocol {
    weak var delegate:AudioEngineDelegate?
    let key:Key
    
    let engine = AVAudioEngine()
    let playerNode = AVAudioPlayerNode()
    let rateNode: AVAudioUnitTimePitch
    
    var timer: Timer?
    
    static let defaultEngineAudioFormat: AVAudioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: false)!
    
    var state:TimerState = .suspended
    enum TimerState {
        case suspended
        case resumed
    }
    
    var audioSpeed: Double = 1.0 {
        didSet {
            rateNode.rate = Float(audioSpeed)
        }
    }
    
    var needle: Needle = -1 {
        didSet {
            if needle >= 0 && oldValue != needle {
                AudioClockDirector.shared.needleTick(key, needle: needle)
            }
        }
    }
    
    var duration: Duration = -1 {
        didSet {
            if duration >= 0 && oldValue != duration {
                AudioClockDirector.shared.durationWasChanged(key, duration: duration)
            }
        }
    }
    
    var playingStatus: SAPlayingStatus? = nil {
        didSet {
            guard playingStatus != oldValue, let status = playingStatus else {
                return
            }
            
            AudioClockDirector.shared.audioPlayingStatusWasChanged(key, status: status)
        }
    }
    
    var bufferedSecondsDebouncer: SAAudioAvailabilityRange = SAAudioAvailabilityRange(startingNeedle: 0.0, durationLoadedByNetwork: 0.0, isPlayable: false)
    var bufferedSeconds: SAAudioAvailabilityRange =  SAAudioAvailabilityRange(startingNeedle: 0.0, durationLoadedByNetwork: 0.0, isPlayable: false) {
        didSet {
            if bufferedSeconds.startingNeedle == 0.0 && bufferedSeconds.durationLoadedByNetwork == 0.0 {
                bufferedSecondsDebouncer = bufferedSeconds
                AudioClockDirector.shared.changeInAudioBuffered(key, buffered: bufferedSeconds)
                return
            }
            
            if bufferedSeconds.startingNeedle == oldValue.startingNeedle && bufferedSeconds.durationLoadedByNetwork == oldValue.durationLoadedByNetwork {
                return
            }
            
            if bufferedSeconds.durationLoadedByNetwork - DEBOUNCING_BUFFER_TIME < bufferedSecondsDebouncer.durationLoadedByNetwork {
                Log.debug("skipping pushing buffer: \(bufferedSeconds)")
                return
            }
            
            bufferedSecondsDebouncer = bufferedSeconds
            AudioClockDirector.shared.changeInAudioBuffered(key, buffered: bufferedSeconds)
        }
    }
    
    init(url: AudioURL, delegate:AudioEngineDelegate?, engineAudioFormat: AVAudioFormat) {
        self.key = url.key
        self.delegate = delegate
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
        
        rateNode = AVAudioUnitTimePitch(audioComponentDescription: componentDescription)
        
        engine.attach(playerNode)
        engine.attach(rateNode)
        engine.connect(playerNode, to: rateNode, format: engineAudioFormat)
        engine.connect(rateNode, to: engine.mainMixerNode, format: engineAudioFormat)
        
        engine.prepare()
    }
    
    deinit {
        timer?.invalidate()
        if state == .resumed {
            engine.stop()
        }
    }
    
    func updateIsPlaying() {
        if !bufferedSeconds.isPlayable {
            playingStatus = .buffering
            return
        }
        
        let isPlaying = engine.isRunning && playerNode.isPlaying
        playingStatus = isPlaying ? .playing : .paused
    }
    
    func play() {
        // https://stackoverflow.com/questions/36754934/update-mpremotecommandcenter-play-pause-button
        if !engine.isRunning {
            do {
                try engine.start()
                
            } catch let error {
                Log.monitor(error.localizedDescription)
            }
        }
        
        playerNode.play()
        
        if state == .suspended {
            state = .resumed
        }
    }
    
    func pause() {
        // https://stackoverflow.com/questions/36754934/update-mpremotecommandcenter-play-pause-button
        playerNode.pause()
        engine.pause()
        
        if state == .resumed {
            state = .suspended
        }
    }
    
    func seek(toNeedle needle: Needle) {
        fatalError("No implementation for seek inAudioEngine, should be using streaming or disk type")
    }
    
    func setSpeed(speed: Double) {
        audioSpeed = speed
    }
    
    func invalidate() {
        
    }
}
