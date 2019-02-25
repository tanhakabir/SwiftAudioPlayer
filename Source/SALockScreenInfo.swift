//
//  SALockScreenInfo.swift
//  SwiftAudioPlayer
//
//  Created by Tanha Kabir on 2019-02-18.
//  Copyright © 2019 Tanha Kabir, Jon Mercer
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import UIKit

/**
 UTC corresponds to epoch time (number of seconds that have elapsed since January 1, 1970, midnight UTC/GMT). https://www.epochconverter.com/ is a useful site to convert to human readable format.
 */
public typealias UTC = Int

/**
 Use to set what will be displayed in the lockscreen.
 */
public struct SALockScreenInfo {
    var title: String
    var artist: String
    var artwork: UIImage?
    var releaseDate: UTC
    
    public init(title: String, artist: String, artwork: UIImage?, releaseDate: UTC) {
        self.title = title
        self.artist = artist
        self.artwork = artwork
        self.releaseDate = releaseDate
    }
}
