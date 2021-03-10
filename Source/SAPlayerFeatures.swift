//
//  SAPlayerFeature.swift
//  SwiftAudioPlayer
//
//  Created by Tanha Kabir on 3/10/21.
//

import Foundation
import AVFoundation

extension SAPlayer {
    public struct Features {
        public struct SkipSilences {
            public static func enable() -> Bool {
                guard let engine = SAPlayer.shared.engine else { return false }
                
                Log.info("enabling skip silences feature")
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
                    Log.test(meterLevel)
                    if meterLevel < 0.6 {
                        self.changeRate(to: 3)
                    } else {
                        self.changeRate(to: 1)
                    }
                }
                
                return true
            }
            
            public static func disable() -> Bool {
                guard let engine = SAPlayer.shared.engine else { return false }
                Log.info("disabling skip silences feature")
                engine.mainMixerNode.removeTap(onBus: 0)
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
            
            private static func changeRate(to rate: Float) {
                guard let node = SAPlayer.shared.audioModifiers.first as? AVAudioUnitTimePitch else { return }
                node.rate = rate
                Log.test(rate)
                SAPlayer.shared.playbackRateOfAudioChanged(rate: rate)
            }
        }
    }
}
