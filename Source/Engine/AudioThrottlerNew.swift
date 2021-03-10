//
//  AudioThrottlerNew.swift
//  SwiftAudioPlayer
//
//  Created by Tanha Kabir on 3/7/21.
//

import Foundation

class AudioThrottlerNew: AudioThrottleable {
    enum State: String {
        case INIT
        case WAITING_FOR_DATA
        case RECEIVING_DATA
        case PUSH_DATA
        case END_OF_DATA
        case CLEAN_UP
    }
    
    private var delegate: AudioThrottleDelegate
    
    required init(withRemoteUrl url: AudioURL, withDelegate delegate: AudioThrottleDelegate) {
        self.delegate = delegate
    }
    
    func tellAudioFormatFound() {
        <#code#>
    }
    
    func tellByteOffset(offset: UInt64) {
        <#code#>
    }
    
    func tellSeek(offset: UInt64) {
        <#code#>
    }
    
    func tellBytesPerAudioPacket(count: UInt64) {
        <#code#>
    }
    
    func pollRangeOfBytesAvailable() -> (UInt64, UInt64) {
        <#code#>
    }
    
    func invalidate() {
        <#code#>
    }
}
