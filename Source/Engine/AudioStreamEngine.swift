//
//  AudioStreamEngine.swift
//  SwiftAudioPlayer
//
//  Created by Tanha Kabir on 2019-01-29.
//  Copyright © 2019 Tanha Kabir, Jon Mercer
//
//  This file was modified and adapted from https://github.com/syedhali/AudioStreamer
//  which was released under Apache License 2.0. Apache License 2.0 requires explicit
//  documentation of modified files from source and a copy of the Apache License 2.0
//  in the project which is under the name Credited_LICENSE.
//
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

/**
 Start of the streaming chain. Get PCM buffer from lower chain and feed it to
 engine
 
 Main responsibilities:
 POLL FOR BUFFER. When we start a stream it takes time for the lower chain to
 receive audio format. We don't know how long this would take. Therefore we poll
 continually. We also poll continually when user seeks because they could have
 seeked beyond pcm buffer, and down-chain buffer. We keep polling until we fill
 N buffers. If we stick to one buffer the audio sounds choppy because sometimes
 the parser takes longer than usual to parse a buffer
 
 RECURSE FOR BUFFER. When we receive N buffers we switch to recursive mode. This
 means we only ask for the next buffer when one of the loaded buffers are
 used up. This is to prevent high CPU usage (100%) because otherwise we keep
 polling and parser keeps parsing even though the user is nowhere near that
 part of audio
 
 UPDATES FOR UI. Duration, needle ticking, playing status, etc.
 
 HANDLE PLAYING. Ensure the engine is in the correct state when playing,
 pausing, or seeking
 */
class AudioStreamEngine: AudioEngine {
    //Constants
    private let MAX_POLL_BUFFER_COUNT = 300 //Having one buffer in engine at a time is choppy.
    private let MIN_BUFFERS_TO_BE_PLAYABLE = 1
    private let PCM_BUFFER_SIZE: AVAudioFrameCount = 8192
    
    private let queue = DispatchQueue(label: "SwiftAudioPlayer.engine", qos: .userInitiated)
    
    //From init
    private var converter: AudioConvertable!
    
    //Fields
    private var currentTimeOffset: TimeInterval = 0
    
    private var numberOfBuffersScheduledInTotal = 0 {
        didSet {
            Log.debug("number of buffers scheduled in total: \(numberOfBuffersScheduledInTotal)")
            if numberOfBuffersScheduledInTotal == 0 {
                pause()
                //                delegate?.didError()
                // TODO: we should not have an error here. We should instead have the throttler
                // propegate when it doesn't enough buffers while they were playing
                // TODO: "Make this a legitimate warning to user about needing more data from stream"
            }
        }
    }
    
    private var wasPlaying = false
    private var numberOfBuffersScheduledFromPoll = 0 {
        didSet {
            if numberOfBuffersScheduledFromPoll > MAX_POLL_BUFFER_COUNT {
                shouldPollForNextBuffer = false
            }
            
            if numberOfBuffersScheduledFromPoll > MIN_BUFFERS_TO_BE_PLAYABLE {
                if wasPlaying {
                    play()
                    wasPlaying = false
                }
            }
        }
    }
    
    private var shouldPollForNextBuffer = true {
        didSet {
            if shouldPollForNextBuffer {
                numberOfBuffersScheduledFromPoll = 0
            }
        }
    }
    
    //Prediction keeps fluctuating. We debounce to keep the UI from jitter
    private var predictedStreamDurationDebounceHelper: Duration = 0
    private var predictedStreamDuration: Duration = 0 {
        didSet {
            let d = predictedStreamDuration
            let s = predictedStreamDurationDebounceHelper
            if d/DEBOUNCING_BUFFER_TIME != s/DEBOUNCING_BUFFER_TIME {
                predictedStreamDurationDebounceHelper = predictedStreamDuration
                duration = predictedStreamDuration
            }
        }
    }
    
    private var seekNeedleCommandBeforeEngineWasReady: Needle?
    private var isPlayable = false {
        didSet {
            if isPlayable != oldValue {
                Log.info("isPlayable status changed: \(isPlayable)")
            }
            
            if isPlayable, let needle = seekNeedleCommandBeforeEngineWasReady {
                seekNeedleCommandBeforeEngineWasReady = nil
                seek(toNeedle: needle)
            }
        }
    }
    
    init(withRemoteUrl url: AudioURL, delegate:AudioEngineDelegate?) {
        Log.info(url)
        super.init(url: url, delegate: delegate, engineAudioFormat: AudioEngine.defaultEngineAudioFormat)
        do {
            converter = try AudioConverter(withRemoteUrl: url, toEngineAudioFormat: AudioEngine.defaultEngineAudioFormat)
        } catch {
            delegate?.didError()
        }
        
        
        let timeInterval = 1 / (converter.engineAudioFormat.sampleRate / Double(PCM_BUFFER_SIZE))
        
        Timer.scheduledTimer(withTimeInterval: timeInterval / 32, repeats: true) { [weak self] (timer: Timer) in
            self?.timer = timer
            self?.pollForNextBuffer()
            self?.updateNetworkBufferRange()
            self?.updateNeedle()
            self?.updateIsPlaying()
            self?.updateDuration()
        }
    }
    
    //MARK:- Timer loop
    
    //Called when
    //1. First time audio is finally parsed
    //2. When we run to the end of the network buffer and we're waiting again
    private func pollForNextBuffer() {
        guard shouldPollForNextBuffer else { return }
        
        do {
            let nextScheduledBuffer = try converter.pullBuffer(withSize: PCM_BUFFER_SIZE)
            numberOfBuffersScheduledFromPoll += 1
            numberOfBuffersScheduledInTotal += 1
            
            Log.debug("processed buffer for engine of frame length \(nextScheduledBuffer.frameLength)")
            queue.async { [weak self] in
                self?.playerNode.scheduleBuffer(nextScheduledBuffer) {
                    self?.numberOfBuffersScheduledInTotal -= 1
                    self?.pollForNextBufferRecursionHelper()
                }
            }
            
            //TODO: re-do how to pass and log these errors
        } catch ConverterError.reachedEndOfFile {
            Log.info(ConverterError.reachedEndOfFile.localizedDescription)
        } catch ConverterError.notEnoughData {
            Log.debug(ConverterError.notEnoughData.localizedDescription)
        } catch ConverterError.superConcerningShouldNeverHappen {
            Log.error(ConverterError.superConcerningShouldNeverHappen.localizedDescription)
        } catch {
            Log.debug(error.localizedDescription)
        }
    }
    
    private func pollForNextBufferRecursionHelper() {
        do {
            let nextScheduledBuffer = try converter.pullBuffer(withSize: PCM_BUFFER_SIZE)
            Log.debug("processed buffer for engine of frame lengthL \(nextScheduledBuffer.frameLength)")
            numberOfBuffersScheduledInTotal += 1
            
            queue.async { [weak self] in
                self?.playerNode.scheduleBuffer(nextScheduledBuffer) {
                    self?.numberOfBuffersScheduledInTotal -= 1
                    self?.pollForNextBufferRecursionHelper()
                }
                
            }
            
        } catch ConverterError.reachedEndOfFile {
            Log.info(ConverterError.reachedEndOfFile.localizedDescription)
        } catch ConverterError.notEnoughData {
            shouldPollForNextBuffer = true
            Log.debug(ConverterError.notEnoughData.localizedDescription)
        } catch ConverterError.superConcerningShouldNeverHappen {
            Log.error(ConverterError.superConcerningShouldNeverHappen.localizedDescription)
        } catch {
            Log.debug(error.localizedDescription)
        }
    }
    
    private func updateNetworkBufferRange() { //for ui
        let range = converter.pollNetworkAudioAvailabilityRange()
        isPlayable = (numberOfBuffersScheduledInTotal >= MIN_BUFFERS_TO_BE_PLAYABLE && range.1 > 0) && predictedStreamDuration > 0
        Log.debug("loaded \(range), numberOfBuffersScheduledInTotal: \(numberOfBuffersScheduledInTotal), isPlayable: \(isPlayable)")
        bufferedSeconds = SAAudioAvailabilityRange(startingNeedle: range.0, durationLoadedByNetwork: range.1, predictedDurationToLoad: predictedStreamDuration, isPlayable: isPlayable)
    }
    
    private func updateNeedle() {
        guard engine.isRunning else { return }
        
        guard let nodeTime = playerNode.lastRenderTime,
            let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else {
                return
        }
        
        //NOTE: playerTime can sometimes be < 0 when seeking. Reason pasted below
        //"The usual AVAudioNode sample times (as observed by lastRenderTime ) have an arbitrary zero point.
        //AVAudioPlayerNode superimposes a second “player timeline” on top of this, to reflect when the
        //player was started, and intervals during which it was paused."
        var currentTime = TimeInterval(playerTime.sampleTime) / playerTime.sampleRate
        currentTime = currentTime > 0 ? currentTime : 0
        
        needle = (currentTime + currentTimeOffset)
    }
    
    private func updateDuration() {
        if let d = converter.pollPredictedDuration() {
            self.predictedStreamDuration = d
        }
    }
    
    
    //MARK:- Overriden From Parent
    override func seek(toNeedle needle: Needle) {
        Log.info("didSeek to needle: \(needle)")
        guard needle < (ceil(predictedStreamDuration)) else {
            if !isPlayable {
                seekNeedleCommandBeforeEngineWasReady = needle
            }
            Log.error("tried to seek beyond duration")
            return
        }
        
        self.needle = needle //to tick while paused
        
        queue.sync { [weak self] in
            self?.seekHelperDispatchQueue(needle: needle)
        }
    }
    
    /**
     The UI would freeze when we tried to call playerNode.stop() while
     simultaneously filling a buffer on another thread. Solution was to put
     playerNode related commands in a DispatchQueue
     */
    private func seekHelperDispatchQueue(needle: Needle) {
        wasPlaying = playerNode.isPlaying
        
        //NOTE: Order matters
        //seek needs to be called before stop
        //Why? Stop will clear all buffers. Each buffer being cleared
        //will call the callback which then fills the buffers with things to the
        //right of the needle. If the order of these two were reversed we would
        //schedule things to the right of the old needle then actually schedule everything
        //after the new needle
        //We also need to poll right after the seek to give us more buffers
        converter.seek(needle)
        currentTimeOffset = TimeInterval(needle)
        
        playerNode.stop()
        
        shouldPollForNextBuffer = true
        
        updateNetworkBufferRange()
    }
    
    override func invalidate() {
        super.invalidate()
        converter.invalidate()
    }
}
