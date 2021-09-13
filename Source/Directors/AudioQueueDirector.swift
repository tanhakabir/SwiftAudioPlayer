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

    func attach(closure: @escaping (URL) throws -> Void) -> UInt {
        return closures.attach(closure: closure)
    }

    func detach(withID id: UInt) {
        closures.detach(id: id)
    }
    
    func changeInQueue(url: URL) {
        closures.broadcast(payload: url)
    }
}
