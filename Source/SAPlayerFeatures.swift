//
//  SAPlayerFeature.swift
//  SwiftAudioPlayer
//
//  Created by Tanha Kabir on 3/10/21.
//

import Foundation
import AVFoundation

extension SAPlayer {
    /**
     Special features for audio manipulation. These are examples of manipulations you can do with the player outside of this library. This is just an aggregation of community contibuted ones.
     
     - Note: These features assume default state of the player and `audioModifiers` meaning some expect the first audio modifier to be the default `AVAudioUnitTimePitch` that comes with the SAPlayer.
     */
    public struct Features {
        
        /**
         Feature to skip silences in spoken word audio. The player will speed up the rate of audio playback when silence is detected.
         
         - Important: The first audio modifier must be the default `AVAudioUnitTimePitch` that comes with the SAPlayer for this feature to work.
         */
        public struct SkipSilences {
            
            static var enabled: Bool = false
            static var originalRate: Float = 1.0
            
            /**
             Enable feature to skip silences in spoken word audio. The player will speed up the rate of audio playback when silence is detected. This can be called at any point of audio playback.
             
             - Important: The first audio modifier must be the default `AVAudioUnitTimePitch` that comes with the SAPlayer for this feature to work.
             */
            public static func enable(fromRate rate: Float = SAPlayer.shared.rate ?? 1.0) -> Bool {
                guard let engine = SAPlayer.shared.engine else { return false }
                
                Log.info("enabling skip silences feature")
                enabled = true
                originalRate = rate
                let format = engine.mainMixerNode.outputFormat(forBus: 0)
                
                
                // look at documentation here to get an understanding of what is happening here: https://www.raywenderlich.com/5154-avaudioengine-tutorial-for-ios-getting-started#toc-anchor-005
                engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, when in
                    guard let channelData = buffer.floatChannelData else {
                        return
                    }

                    let channelDataValue = channelData.pointee
                    let channelDataValueArray = stride(from: 0,
                                                       to: Int(buffer.frameLength),
                                                       by: buffer.stride).map { channelDataValue[$0] }

                    let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))

                    let avgPower = 20 * log10(rms)

                    let meterLevel = self.scaledPower(power: avgPower)
                    Log.debug("meterLevel: \(meterLevel)")
                    if meterLevel < 0.6 { // below 0.6 decibels is below audible audio
                        SAPlayer.shared.rate = originalRate + 0.5
                        Log.debug("speed up rate to \(String(describing: SAPlayer.shared.rate))")
                    } else {
                        SAPlayer.shared.rate = originalRate
                        Log.debug("slow down rate to \(String(describing: SAPlayer.shared.rate))")
                    }
                }
                
                return true
            }
            
            /**
             Disable feature to skip silences in spoken word audio. The player will speed up the rate of audio playback when silence is detected. This can be called at any point of audio playback.
             
             - Important: The first audio modifier must be the default `AVAudioUnitTimePitch` that comes with the SAPlayer for this feature to work.
             */
            public static func disable() -> Bool {
                guard let engine = SAPlayer.shared.engine else { return false }
                Log.info("disabling skip silences feature")
                engine.mainMixerNode.removeTap(onBus: 0)
                SAPlayer.shared.rate = originalRate
                enabled = false
                return true
            }
            
            private static func scaledPower(power: Float) -> Float {
                guard power.isFinite else { return 0.0 }
                let minDb: Float = -80.0
                if power < minDb {
                    return 0.0
                } else if power >= 1.0 {
                    return 1.0
                } else {
                    return (abs(minDb) - abs(power)) / abs(minDb)
                }
            }
        }
        
        /**
         Feature to pause the player after a delay. This will happen regardless of if another audio clip has started.
         */
        public struct SleepTimer {
            static var timer: Timer?
            
            /**
             Enable feature to pause the player after a delay. This will happen regardless of if another audio clip has started.
             
             - Parameter afterDelay: The number of seconds to wait before pausing the audio
             */
            public static func enable(afterDelay delay: Double) {
                timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false, block: { _ in
                    SAPlayer.shared.pause()
                })
            }
            
            /**
             Disable feature to pause the player after a delay. 
             */
            public static func disable() {
                timer?.invalidate()
            }
        }
    }
}
