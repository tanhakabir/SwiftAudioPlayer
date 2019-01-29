//
//  AudioThrottler.swift
//  SwiftAudioPlayer
//
//  Created by Tanha Kabir on 2019-01-29.
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

protocol AudioThrottleDelegate: AnyObject {
    func didUpdate(totalBytesExpected bytes: Int64)
    func didUpdate(networkStreamProgress progress: Double)
    func shouldProcess(networkData data: Data)
}

protocol AudioThrottleable {
    init(withRemoteUrl url: AudioURL, withDelegate delegate: AudioThrottleDelegate)
    func tellAudioFormatFound()
    func tellByteOffset(offset: UInt64)
    func tellSeek(offset: UInt64)
    func pollRangeOfBytesAvailable() -> (UInt64, UInt64)
    func invalidate()
}

class AudioThrottler: AudioThrottleable {
    private class NetworkDataWrapper: NSObject {
        let startOffset: UInt
        var data: Data
        var alreadySent: Bool
        var next: NetworkDataWrapper?
        
        var endOffset: UInt {
            return startOffset + UInt(data.count) - 1
        }
        
        init(startingOffset: UInt, data: Data) {
            self.startOffset = startingOffset
            self.data = data
            self.alreadySent = false
        }
        
        func containsOffset(_ offset: UInt) -> Bool {
            return startOffset <= offset && offset <= endOffset
        }
        
        func isNextSent() -> Bool {
            return next?.alreadySent ?? false
        }
        
        //FIXME: what is the offset was at the edge of the split? We will have empty data
        func splitToRight(atOffset offset: UInt) -> NetworkDataWrapper {
            let splitPoint:Int = Int(offset - startOffset)
            let leftData = data.subdata(in: 0..<splitPoint)
            let rightData = data.subdata(in: splitPoint..<data.count)
            
            data = leftData
            
            let rightWrapper:NetworkDataWrapper = NetworkDataWrapper(startingOffset: offset, data: rightData)
            rightWrapper.next = next
            next = rightWrapper
            
            return rightWrapper
        }
        
        override var description: String {
            return "startOffset:\(startOffset), endOffset:\(endOffset), dataCount:\(data.count), sent:\(alreadySent), next:\(next != nil ?"hasNext":"noNext")"
        }
    }
    
    //Init
    let url: AudioURL
    weak var delegate: AudioThrottleDelegate?
    
    private var networkData: [NetworkDataWrapper] = []
    var shouldThrottle = false
    var byteOffsetBecauseOfSeek: UInt = 0
    var totalBytesExpected: Int64? //this got sent up twice. Once at beginning of stream and second from network seek. We honor the first send
    
    required init(withRemoteUrl url: AudioURL, withDelegate delegate: AudioThrottleDelegate) {
        self.url = url
        self.delegate = delegate
        
        AudioDataManager.shared.startStream(withRemoteURL: url) { [weak self] (pto: StreamProgressPTO) in
            guard let self = self else {return}
            Log.debug("received stream data of size \(pto.getData().count) and progress: \(pto.getProgress())")
            self.delegate?.didUpdate(networkStreamProgress: pto.getProgress())
            
            if self.totalBytesExpected == nil, let totalBytesExpected = pto.getTotalBytesExpected() {
                self.totalBytesExpected = totalBytesExpected
                self.delegate?.didUpdate(totalBytesExpected: totalBytesExpected)
            }
            
            let lastItem = self.networkData.last
            let startoffset = lastItem == nil ? self.byteOffsetBecauseOfSeek : lastItem!.endOffset + 1
            let wrappedNetworkData = NetworkDataWrapper(startingOffset: startoffset, data: pto.getData())
            lastItem?.next = wrappedNetworkData
            self.networkData.append(wrappedNetworkData)
            
            if !self.shouldThrottle {
                Log.debug("sending up packet from stream untrottled at start: \(wrappedNetworkData.startOffset)")
                //NOTE: the order here matters.
                //We have to set to true before sending up to be processed because
                //tellByteOffset() is ran in a separate thread than this one
                //We got in a state where 10% of the time an episode will keep polling because
                //the first 30 buffers have not been filled
                wrappedNetworkData.alreadySent = true
                delegate.shouldProcess(networkData: wrappedNetworkData.data)
            }
        }
    }
    
    func tellAudioFormatFound() {
        shouldThrottle = true //the above layer has enough info that we can throttle
    }
    
    func tellByteOffset(offset: UInt64) {
        Log.debug("offset \(offset)")
        for wrappedNetworkData in networkData {
            if wrappedNetworkData.containsOffset(UInt(offset)) {
                Log.debug("offset within network packet of range: \(wrappedNetworkData.startOffset) to \(wrappedNetworkData.endOffset)")
                if wrappedNetworkData.alreadySent {
                    if !wrappedNetworkData.isNextSent() {
                        if let next = wrappedNetworkData.next {
                            Log.debug("Sending next network packet with range: \(next.startOffset) to \(next.endOffset)")
                            next.alreadySent = true
                            delegate?.shouldProcess(networkData: next.data)
                        }
                    }
                    return
                }
                
                Log.debug("Found network packet  to send with range: \(wrappedNetworkData.startOffset) to \(wrappedNetworkData.endOffset)")
                delegate?.shouldProcess(networkData: wrappedNetworkData.data)
                wrappedNetworkData.alreadySent = true
                return
            }
        }
    }
    
    func tellSeek(offset: UInt64) {
        Log.info("seek with offset: \(offset)")
        
        if networkData.count == 0 {
            byteOffsetBecauseOfSeek = UInt(offset)
            AudioDataManager.shared.seekStream(withRemoteURL: url, toByteOffset: offset)
            
            networkData = []
            return
        }
        
        if let finalOffset = networkData.last?.endOffset, let firstOffset = networkData.first?.startOffset {
            if offset < firstOffset || offset > finalOffset {
                byteOffsetBecauseOfSeek = UInt(offset)
                AudioDataManager.shared.seekStream(withRemoteURL: url, toByteOffset: offset)
                
                networkData = []
                return
            }
        }
        
        for (i, d) in networkData.enumerated() {
            if offset > d.endOffset {
                d.alreadySent = false
                continue
            }
            
            if d.containsOffset(UInt(offset)) {
                let wrappedData = d.splitToRight(atOffset: UInt(offset))
                networkData.insert(wrappedData, at: i+1)
                
                d.alreadySent = false
                wrappedData.alreadySent = true
                Log.info("\(d) ::: \(wrappedData)")
                
                delegate?.shouldProcess(networkData: wrappedData.data)
                return
            }
        }
    }
    
    func pollRangeOfBytesAvailable() -> (UInt64, UInt64) {
        let start = networkData.first?.startOffset ?? 0
        let end = networkData.last?.endOffset ?? 0
        
        return (UInt64(start), UInt64(end))
    }
    
    func invalidate() {
        AudioDataManager.shared.deleteStream(withRemoteURL: url)
    }
}
