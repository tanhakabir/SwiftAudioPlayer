//
//  Model.swift
//  SwiftAudioPlayer_Example
//
//  Created by Tanha Kabir on 3/17/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation

struct AudioInfo: Hashable {
    var index: Int = 0
    
    var urls: [URL] = [URL(string: "https://www.fesliyanstudios.com/musicfiles/2019-04-23_-_Trusted_Advertising_-_www.fesliyanstudios.com/15SecVersion2019-04-23_-_Trusted_Advertising_-_www.fesliyanstudios.com.mp3")!,
                       URL(string: "https://chtbl.com/track/18338/traffic.libsyn.com/secure/acquired/acquired_-_armrev_2.mp3?dest-id=376122")!,
                       URL(string: "https://backtracks.fm/ycombinator/pr/0f685f72-29b1-11e9-9bcf-0ece7a7d2472/111---jake-klamka-and-kevin-hale---y-combinator.mp3?s=1&amp;sd=1&amp;u=1549423185")!]
    
    var url: URL {
        switch index {
        case 0:
            return URL(string: "https://www.fesliyanstudios.com/musicfiles/2019-04-23_-_Trusted_Advertising_-_www.fesliyanstudios.com/15SecVersion2019-04-23_-_Trusted_Advertising_-_www.fesliyanstudios.com.mp3")!
        case 1:
            return URL(string: "https://chtbl.com/track/18338/traffic.libsyn.com/secure/acquired/acquired_-_armrev_2.mp3?dest-id=376122")!
        case 2:
            return URL(string: "https://backtracks.fm/ycombinator/pr/0f685f72-29b1-11e9-9bcf-0ece7a7d2472/111---jake-klamka-and-kevin-hale---y-combinator.mp3?s=1&amp;sd=1&amp;u=1549423185")!
        default:
            return URL(string: "https://www.fesliyanstudios.com/musicfiles/2019-04-23_-_Trusted_Advertising_-_www.fesliyanstudios.com/15SecVersion2019-04-23_-_Trusted_Advertising_-_www.fesliyanstudios.com.mp3")!
        }
    }
    
    var title: String {
        switch index {
        case 0:
            return "Soundbite"
        case 1:
            return "Acquired"
        case 2:
            return "Y Combinator"
        default:
            return "Soundbite"
        }
    }
    
    let artist: String = "SwiftAudioPlayer Sample App"
    let releaseDate: Int = 1550790640
    
    var savedUrl: URL? {
        get {
            return savedUrls[index]
        }
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
