//
//  AudioDiskEngine.swift
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

class AudioDiskEngine: AudioEngine {
    var audioFormat: AVAudioFormat?
    var audioSampleRate: Float = 0
    var audioLengthSamples: AVAudioFramePosition = 0
    var seekFrame: AVAudioFramePosition = 0
    var currentPosition: AVAudioFramePosition = 0
    
    var audioFile: AVAudioFile?
    
    var currentFrame: AVAudioFramePosition {
        guard let lastRenderTime = playerNode.lastRenderTime,
            let playerTime = playerNode.playerTime(forNodeTime: lastRenderTime) else {
                return 0
        }
        
        return playerTime.sampleTime
    }
    
    var audioLengthSeconds: Float = 0
    
    init(withSavedUrl url: AudioURL, delegate:AudioEngineDelegate?) {
        Log.info(url.key)
        
        do {
            audioFile = try AVAudioFile(forReading: url)
        } catch {
            Log.monitor(error.localizedDescription)
        }
        
        super.init(url: url, delegate: delegate, engineAudioFormat: audioFile?.processingFormat ?? AudioEngine.defaultEngineAudioFormat)
        
        if let file = audioFile {
            Log.debug("Audio file exists")
            audioLengthSamples = file.length
            audioFormat = file.processingFormat
            audioSampleRate = Float(audioFormat?.sampleRate ?? 44100)
            audioLengthSeconds = Float(audioLengthSamples) / audioSampleRate
            duration = Duration(audioLengthSeconds)
            bufferedSeconds = SAAudioAvailabilityRange(startingNeedle: 0, durationLoadedByNetwork: duration, predictedDurationToLoad: duration, isPlayable: true)
        } else {
            Log.monitor("Could not load downloaded file with url: \(url)")
        }
        
        
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] (timer: Timer) in
            guard let _ = self else { return }
            self?.timer = timer
            self?.updateIsPlaying()
            self?.updateNeedle()
        }
        
        scheduleAudioFile()
    }
    
    private func scheduleAudioFile() {
        guard let audioFile = audioFile else { return }
        
        playerNode.scheduleFile(audioFile, at: nil, completionHandler: nil)
    }
    
    private func updateNeedle() {
        guard engine.isRunning else { return }
        
        currentPosition = currentFrame + seekFrame
        currentPosition = max(currentPosition, 0)
        currentPosition = min(currentPosition, audioLengthSamples)
        
        if currentPosition >= audioLengthSamples {
            playerNode.stop()
            if state == .resumed {
                state = .suspended
            }
            playingStatus = .ended
        }
        
        guard audioSampleRate != 0 else {
            Log.error("Missing audio sample rate in update needle timer function!")
            return
        }
        
        needle = Double(Float(currentPosition)/audioSampleRate)
    }
    
    override func seek(toNeedle needle: Needle) {
        guard let audioFile = audioFile else {
            Log.error("did not have audio file when trying to seek")
            return
        }
        
        let playing = playerNode.isPlaying
        
        self.needle = needle // to tick while paused
        
        seekFrame = AVAudioFramePosition(Float(needle) * audioSampleRate)
        seekFrame = max(seekFrame, 0)
        seekFrame = min(seekFrame, audioLengthSamples)
        currentPosition = seekFrame
        
        playerNode.stop()
        
        if currentPosition < audioLengthSamples {
            playerNode.scheduleSegment(audioFile, startingFrame: seekFrame, frameCount: AVAudioFrameCount(audioLengthSamples - seekFrame), at: nil, completionHandler: nil)
            
            if playing {
                playerNode.play()
            }
        }
    }
    
    override func invalidate() {
        super.invalidate()
        //Nothing to invalidate for disk
    }
}
