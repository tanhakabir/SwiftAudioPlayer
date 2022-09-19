//
//  Model.swift
//  SwiftAudioPlayer_Example
//
//  Created by Tanha Kabir on 3/17/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import SwiftAudioPlayerKuama

struct AudioInfo: Hashable {
    var index: Int = 0

    var urls: [URL] = [URL(string: "https://www.fesliyanstudios.com/musicfiles/2019-04-23_-_Trusted_Advertising_-_www.fesliyanstudios.com/15SecVersion2019-04-23_-_Trusted_Advertising_-_www.fesliyanstudios.com.mp3")!,
                       URL(string: "https://chtbl.com/track/18338/traffic.libsyn.com/secure/acquired/acquired_-_armrev_2.mp3?dest-id=376122")!,
                       URL(string: "https://ice6.somafm.com/groovesalad-256-mp3")!]

    var url: URL {
        switch index {
        case 0:
            return urls[0]
        case 1:
            return urls[1]
        case 2:
            return urls[2]
        default:
            return urls[0]
        }
    }

    var title: String {
        switch index {
        case 0:
            return "Soundbite"
        case 1:
            return "Podcast"
        case 2:
            return "Radio"
        default:
            return "Soundbite"
        }
    }

    let artist: String = "SwiftAudioPlayer Sample App"
    let releaseDate: Int = 1_550_790_640

    var lockscreenInfo: SALockScreenInfo {
        return SALockScreenInfo(title: title, artist: artist, albumTitle: nil, artwork: nil, releaseDate: releaseDate)
    }

    var savedUrl: URL? {
        return savedUrls[index]
    }

    var savedUrls: [URL?] = [nil, nil, nil]

    mutating func addSavedUrl(_ url: URL) {
        savedUrls[index] = url
    }

    mutating func deleteSavedUrl() {
        savedUrls[index] = nil
    }

    mutating func addSavedUrl(_ url: URL, atIndex i: Int) {
        savedUrls[i] = url
    }

    mutating func deleteSavedUrl(atIndex i: Int) {
        savedUrls[i] = nil
    }

    func getUrl(atIndex i: Int) -> URL {
        return urls[i]
    }

    mutating func setIndex(_ i: Int) {
        index = i
    }

    func getIndex(forURL url: URL) -> Int? {
        return urls.firstIndex(of: url) ?? savedUrls.firstIndex(of: url)
    }
}
