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
            
            /**
             Enable feature to skip silences in spoken word audio. The player will speed up the rate of audio playback when silence is detected. This can be called at any point of audio playback.
             
             - Important: The first audio modifier must be the default `AVAudioUnitTimePitch` that comes with the SAPlayer for this feature to work.
             */
            public static func enable() -> Bool {
                guard let engine = SAPlayer.shared.engine else { return false }
                
                Log.info("enabling skip silences feature")
                enabled = true
                let originalRate = SAPlayer.shared.rate ?? 1.0
                let format = engine.mainMixerNode.outputFormat(forBus: 0)
                
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
                    if meterLevel < 0.6 {
                        SAPlayer.shared.rate = originalRate + 0.5
                        Log.test("speed up rate to \(String(describing: SAPlayer.shared.rate))")
                    } else {
                        SAPlayer.shared.rate = originalRate
                        Log.test("slow down rate to \(String(describing: SAPlayer.shared.rate))")
                    }
                }
                
                return true
            }
            
            /**
             Disable feature to skip silences in spoken word audio. The player will speed up the rate of audio playback when silence is detected. This can be called at any point of audio playback.
             
             - Important: The first audio modifier must be the default `AVAudioUnitTimePitch` that comes with the SAPlayer for this feature to work.
             */
            public static func disable() -> Bool {
                // TODO fix disabling on speed up portion and being stuck at faster speed https://github.com/tanhakabir/SwiftAudioPlayer/issues/76
                guard let engine = SAPlayer.shared.engine else { return false }
                Log.info("disabling skip silences feature")
                engine.mainMixerNode.removeTap(onBus: 0)
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
    }
}
