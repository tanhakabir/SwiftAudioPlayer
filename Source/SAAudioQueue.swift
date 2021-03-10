//
//  SAAudioQueue.swift
//  SwiftAudioPlayer
//
//  Created by Joe Williams on 09/03/2021.
//

import Foundation

struct SAAudioQueue<T> {
    private var audioUrls: [T] = []

    var isQueueEmpty: Bool {
        return audioUrls.isEmpty
    }

    var count: Int {
        return audioUrls.count
    }

    var front: T? {
        return audioUrls.first
    }

    mutating func append(item: T) {
        audioUrls.append(item)
    }

    mutating func dequeue() -> T? {
        guard !isQueueEmpty else { return nil }
        return audioUrls.removeFirst()
    }
}
