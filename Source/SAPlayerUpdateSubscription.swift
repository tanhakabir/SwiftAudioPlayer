//
//  SAPlayerUpdateSubscription.swift
//  SwiftAudioPlayer
//
//  Created by Tanha Kabir on 2019-02-18.
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

extension SAPlayer {
    public struct Updates {
        public struct ElapsedTime {
            public static func subscribe(_ closure: @escaping (URL, Double) -> ()) -> UInt {
                return AudioClockDirector.shared.attachToChangesInNeedle(closure: { (key, needle) in
                    guard let url = SAPlayer.shared.getUrl(forKey: key) else { return }
                    closure(url, needle)
                })
            }
            
            public static func unsubscribe(_ id: UInt) {
                AudioClockDirector.shared.detachFromChangesInNeedle(withID: id)
            }
        }
        
        public struct Duration {
            public static func subscribe(_ closure: @escaping (URL, Double) -> ()) -> UInt {
                return AudioClockDirector.shared.attachToChangesInDuration(closure: { (key, duration) in
                    guard let url = SAPlayer.shared.getUrl(forKey: key) else { return }
                    closure(url, duration)
                })
            }
            
            public static func unsubscribe(_ id: UInt) {
                AudioClockDirector.shared.detachFromChangesInDuration(withID: id)
            }
        }
        
        public struct PlayingStatus {
            public static func subscribe(_ closure: @escaping (URL, Bool) -> ()) -> UInt {
                return AudioClockDirector.shared.attachToChangesInPlayingStatus(closure: { (key, isPlaying) in
                    guard let url = SAPlayer.shared.getUrl(forKey: key) else { return }
                    closure(url, isPlaying)
                })
            }
            
            public static func unsubscribe(_ id: UInt) {
                AudioClockDirector.shared.detachFromChangesInPlayingStatus(withID: id)
            }
        }
        
        public struct StreamingBuffer {
            public static func subscribe(_ closure: @escaping (URL, SAAudioAvailabilityRange) -> ()) -> UInt {
                return AudioClockDirector.shared.attachToChangesInBufferedRange(closure: { (key, buffer) in
                    guard let url = SAPlayer.shared.getUrl(forKey: key) else { return }
                    closure(url, buffer)
                })
            }
            
            public static func unsubscribe(_ id: UInt) {
                AudioClockDirector.shared.detachFromChangesInBufferedRange(withID: id)
            }
        }
        
        public struct AudioDownloading {
            public static func subscribe(_ closure: @escaping (URL, Double) -> ()) -> UInt {
                return DownloadProgressDirector.shared.attach(closure: { (key, progress) in
                    guard let url = SAPlayer.shared.getUrl(forKey: key) else { return }
                    closure(url, progress)
                })
            }
            
            public static func unsubscribe(_ id: UInt) {
                DownloadProgressDirector.shared.detach(withID: id)
            }
        }
    }
}

