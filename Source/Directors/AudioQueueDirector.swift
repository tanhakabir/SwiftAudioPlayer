//
//  AudioQueueDirector.swift
//  SwiftAudioPlayer
//
//  Created by Joe Williams on 3/10/21.
//

import Foundation

class AudioQueueDirector {
    static let shared = AudioQueueDirector()
    var closures: DirectorThreadSafeClosures<URL> = DirectorThreadSafeClosures()
    private init() {}

    func create() {}

    func clear() {
        closures.clear()
    }

    func attach(closure: @escaping (Key, URL) throws -> Void) -> UInt {
        return closures.attach(closure: closure)
    }

    func detach(withID id: UInt) {
        closures.detach(id: id)
    }
    
    func changeInQueue(_ key: Key, url: URL) {
        closures.broadcast(key: key, payload: url)
    }
}
