//
//  SAPlayerCombineUpdates.swift
//  SwiftAudioPlayer-SwiftUI
//
//  Created by Jon Mercer on 4/21/21.
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
import Combine

extension SAPlayer {
    class SAPlayerCombine: ObservableObject {
        static let shared = SAPlayerCombine()
        
        
//        Ideally this won't be a nil because we should be using a PassthroughSubject. However, most new users are used to `@Published` so I went with that.
//        If you're going to heavily use this player with SwiftUI consider making a PR using PassthroughSubject, or at least let me know and I'll implement that.
        @Published var update = CombineUpdate()

        struct CombineUpdate {
            var url: URL?
            var elapsedTime: Double?
            var duration: Double?
            var playingStatus: SAPlayingStatus?
            var streamingBuffer: SAAudioAvailabilityRange?
            var downloadProgress: Double?
            //TODO: add queue here if people use this
        }
        
        private var elapsedTimeId:UInt?
        private var durationId:UInt?
        private var playingStatusId:UInt?
        private var streamingBufferId:UInt?
        private var audioDownloadingId:UInt?
        private var audioQueueId:UInt? //TODO: add this later becuase it's more complicated
        deinit {
            if let id = elapsedTimeId { SAPlayer.Updates.ElapsedTime.unsubscribe(id) }
            if let id = durationId { SAPlayer.Updates.Duration.unsubscribe(id) }
            if let id = playingStatusId { SAPlayer.Updates.PlayingStatus.unsubscribe(id) }
            if let id = streamingBufferId { SAPlayer.Updates.StreamingBuffer.unsubscribe(id) }
            if let id = audioDownloadingId { SAPlayer.Updates.AudioDownloading.unsubscribe(id) }
        }
        
        init() {
            elapsedTimeId = SAPlayer.Updates.ElapsedTime.subscribe { [weak self] (url:URL, timePosition:Double) in
                guard let self = self else { return }
                self.update.url = url
                self.update.elapsedTime = timePosition
            }
            
            durationId = SAPlayer.Updates.Duration.subscribe { [weak self] (url:URL, duration:Double) in
                guard let self = self else { return }
                self.update.url = url
                self.update.duration = duration
            }
            
            playingStatusId = SAPlayer.Updates.PlayingStatus.subscribe { [weak self] (url:URL, status:SAPlayingStatus) in
                guard let self = self else { return }
                self.update.url = url
                self.update.playingStatus = status
            }
            
            streamingBufferId = SAPlayer.Updates.StreamingBuffer.subscribe { [weak self] (url:URL, buffer:SAAudioAvailabilityRange) in
                guard let self = self else { return }
                self.update.url = url
                self.update.streamingBuffer = buffer
            }
            
            audioDownloadingId = SAPlayer.Updates.AudioDownloading.subscribe { [weak self] (url:URL, progress:Double) in
                guard let self = self else { return }
                self.update.url = url
                self.update.downloadProgress = progress
            }
        }
    }
}
