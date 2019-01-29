//
//  AudioClockDirector.swift
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
import CoreMedia

class AudioClockDirector {
    static let sharedInstance = AudioClockDirector()
    
    private var needleClosures: DirectorThreadSafeClosures<(Key, Needle)> = DirectorThreadSafeClosures()
    private var durationClosures: DirectorThreadSafeClosures<(Key, Duration)> = DirectorThreadSafeClosures()
    private var playingStatusClosures: DirectorThreadSafeClosures<(Key, IsPlaying)> = DirectorThreadSafeClosures()
    private var bufferClosures: DirectorThreadSafeClosures<(Key, AudioAvailabilityRange)> = DirectorThreadSafeClosures()
    
    private var needleMap: [Key: Needle] = [:]
    private var durationMap: [Key: Duration] = [:]
    private var playingStatusMap: [Key: IsPlaying] = [:]
    private var bufferedRangeMap: [Key: AudioAvailabilityRange] = [:]
    
    private init() {}
    
    func create() {}
    
    func clear() {
        self.needleMap = [:]
        self.durationMap = [:]
        self.playingStatusMap = [:]
        self.bufferedRangeMap = [:]
        
        needleClosures.clear()
        durationClosures.clear()
        playingStatusClosures.clear()
        bufferClosures.clear()
    }
    
    // MARK: - Attaches
    
    // Needle
    func attachToChangesInNeedle(closure: @escaping ((Key, Needle)) throws -> Void) -> UInt{
        for (key, needle) in needleMap {
            do {
                try closure((key, needle))
            } catch {
                Log.debug(error.localizedDescription)
            }
        }
        
        return needleClosures.attach(closure: closure, payload: nil)
    }
    
    
    // Duration
    func attachToChangesInDuration(closure: @escaping ((Key, Duration)) throws -> Void) -> UInt {
        for (key, duration) in durationMap {
            do {
                try closure((key, duration))
            } catch {
                Log.debug(error.localizedDescription)
            }
        }
        
        return durationClosures.attach(closure: closure, payload: nil)
    }
    
    
    // Playing status
    func attachToChangesInPlayingStatus(closure: @escaping ((Key, IsPlaying)) throws -> Void) -> UInt{
        for (key, playing) in playingStatusMap {
            do {
                try closure((key, playing))
            } catch {
                Log.debug(error.localizedDescription)
            }
        }
        
        return playingStatusClosures.attach(closure: closure, payload: nil)
    }
    
    
    // Buffer
    func attachToChangesInBufferedRange(closure: @escaping ((Key, AudioAvailabilityRange)) throws -> Void) -> UInt{
        for (key, buffer) in bufferedRangeMap {
            do {
                try closure((key, buffer))
            } catch {
                Log.debug(error.localizedDescription)
            }
        }
        
        return bufferClosures.attach(closure: closure, payload: nil)
    }
    
    
    // MARK: - Detaches
    func detachFromChangesInNeedle(withID id: UInt) {
        needleClosures.detach(id: id)
    }
    
    func detachFromChangesInDuration(withID id: UInt) {
        durationClosures.detach(id: id)
    }
    
    func detachFromChangesInPlayingStatus(withID id: UInt) {
        playingStatusClosures.detach(id: id)
    }
    
    func detachFromChangesInBufferedRange(withID id: UInt) {
        bufferClosures.detach(id: id)
    }
}

// MARK: - Receives notifications from AudioEngine on ticks
extension AudioClockDirector {
    func needleTick(_ key: Key, needle: Needle) {
        self.needleMap[key] = needle
        needleClosures.broadcast(payload: (key, needle))
    }
}

extension AudioClockDirector {
    func durationWasChanged(_ key: Key, duration: Duration) {
        self.durationMap[key] = duration
        durationClosures.broadcast(payload: (key, duration))
    }
}

extension AudioClockDirector {
    func audioPaused(_ key: Key) {
        self.playingStatusMap[key] = false
        playingStatusClosures.broadcast(payload: (key, false))
    }
    
    func audioPlaying(_ key: Key) {
        self.playingStatusMap[key] = true
        playingStatusClosures.broadcast(payload: (key, true))
    }
}

extension AudioClockDirector {
    func changeInAudioBuffered(_ key: Key, buffered: AudioAvailabilityRange) {
        self.bufferedRangeMap[key] = buffered
        bufferClosures.broadcast(payload: (key, buffered))
    }
}
