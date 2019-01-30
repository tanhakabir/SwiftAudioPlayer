//
//  URL.swift
//  Pods-SwiftAudioPlayer_Example
//
//  Created by Tanha Kabir on 2019-01-29.
//

import Foundation

extension URL {
    var key: String {
        get {
            return "audio_\(self.absoluteString.hashed)"
        }
    }
}


fileprivate extension String {
    var hashed: UInt64 {
        get {
            var result = UInt64 (8742)
            let buf = [UInt8](self.utf8)
            for b in buf {
                result = 127 * (result & 0x00ffffffffffffff) + UInt64(b)
            }
            return result
        }
    }
}
