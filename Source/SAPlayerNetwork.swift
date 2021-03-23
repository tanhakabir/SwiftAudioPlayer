//
//  SAPlayerNetwork.swift
//  SwiftAudioPlayer
//
//  Created by Tanha Kabir on 3/22/21.
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

extension SAPlayer {
    /**
     Actions relating to remote requests being made to download or stream audio data.
     */
    public struct Network {
        
        /**
         Handle permissions for downloading and/or streaming on cellular data.
         */
        public struct CellularData {
            /**
             Whether downloading audio on cellular data is allowed. By default this is set to `true`.
             */
            public static var allowUsage = true {
                didSet {
                    AudioDataManager.shared.setAllowCellularDownloadPreference(allowUsage)
                }
            }
        }
    }
}
