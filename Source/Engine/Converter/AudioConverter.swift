//
//  AudioConverter.swift
//  Pods-SwiftAudioPlayer_Example
//
//  Created by Tanha Kabir on 2019-01-29.
//

import Foundation
import AVFoundation
import AudioToolbox

protocol AudioConvertable {
    var engineAudioFormat: AVAudioFormat {get}
    
    init(withRemoteUrl url: AudioURL, toEngineAudioFormat: AVAudioFormat) throws
    func pullBuffer(withSize size: AVAudioFrameCount) throws -> AVAudioPCMBuffer
    func pollPredictedDuration() -> Duration?
    func pollNetworkAudioAvailabilityRange() -> (Needle, Duration)
    func seek(_ needle: Needle)
    func invalidate()
}

/**
 Creates PCM Buffers for the audio engine
 
 Main Responsibilities:
 
 CREATE CONVERTER. Waits for parser to give back audio format then creates a
 converter.
 
 USE CONVERTER. The converter takes parsed audio packets and 1. transforms them
 into a format that the engine can take. 2. Fills a buffer of a certain size.
 Note that we might not need a converted if the format that the engine takes in
 is the same as what the parser outputs.
 
 KEEP AUDIO INDEX: The engine keeps trying to pull a buffer from converter. The
 converter will keep pulling from parser. The converter calculates the exact
 index that it wants to convert and keeps pulling at that index until the parser
 passes up a value.
 */
class AudioConverter: AudioConvertable {
    let queue = DispatchQueue(label: "SwiftAudioPlayer.audio_reader_queue")
    
    //From Init
    var parser: AudioParsable!
    
    //From protocol
    public var engineAudioFormat: AVAudioFormat
    
    //Field
    var converter: AudioConverterRef? //set by AudioConverterNew
    var currentAudioPacketIndex: AVAudioPacketCount = 0
    
    required init(withRemoteUrl url: AudioURL, toEngineAudioFormat: AVAudioFormat) throws {
        self.engineAudioFormat = toEngineAudioFormat
        do {
            parser = try AudioParser(withRemoteUrl: url, parsedFileAudioFormatCallback: {
                [weak self] (fileAudioFormat: AVAudioFormat) in
                guard let strongSelf = self else { return }
                
                let sourceFormat = fileAudioFormat.streamDescription
                let destinationFormat = strongSelf.engineAudioFormat.streamDescription
                let result = AudioConverterNew(sourceFormat, destinationFormat, &strongSelf.converter)
                
                guard result == noErr else {
                    Log.monitor(ConverterError.unableToCreateConverter(result).errorDescription as Any)
                    return
                }
            })
        } catch {
            throw ConverterError.failedToCreateParser
        }
    }
    
    deinit {
        guard let converter = converter else {
            Log.error("No converter n deinit!")
            return
        }
        
        guard AudioConverterDispose(converter) == noErr else {
            Log.monitor("failed to dispose audio converter")
            return
        }
    }
    
    func pullBuffer(withSize size: AVAudioFrameCount) throws -> AVAudioPCMBuffer {
        guard let converter = converter else {
            Log.debug("reader_error trying to read before converter has been created")
            throw ConverterError.cannotCreatePCMBufferWithoutConverter
        }
        
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: engineAudioFormat, frameCapacity: size) else {
            Log.monitor(ConverterError.failedToCreatePCMBuffer.errorDescription as Any)
            throw ConverterError.failedToCreatePCMBuffer
        }
        pcmBuffer.frameLength = size
        
        /**
         The whole thing is wrapped in queue.sync() because the converter listener
         needs to eventually increment the audioPatcketIndex. We don't want threads
         to mess this up
         */
        return try queue.sync { () -> AVAudioPCMBuffer in
            let framesPerPacket = engineAudioFormat.streamDescription.pointee.mFramesPerPacket
            var numberOfPacketsWeWantTheBufferToFill = size / framesPerPacket
            
            let context = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
            let status = AudioConverterFillComplexBuffer(converter, ConverterListener, context, &numberOfPacketsWeWantTheBufferToFill, pcmBuffer.mutableAudioBufferList, nil)
            
            guard status == noErr else {
                switch status {
                case ReaderMissingSourceFormatError:
                    throw ConverterError.parserMissingDataFormat
                case ReaderReachedEndOfDataError:
                    throw ConverterError.reachedEndOfFile
                case ReaderNotEnoughDataError:
                    throw ConverterError.notEnoughData
                case ReaderShouldNotHappenError:
                    throw ConverterError.superConcerningShouldNeverHappen
                default:
                    throw ConverterError.converterFailed(status)
                }
            }
            return pcmBuffer
        }
    }
    
    func seek(_ needle: Needle) {
        guard let audioPacketIndex = getPacketIndex(forNeedle: needle) else {
            return
        }
        Log.info("didSeek to packet index: \(audioPacketIndex)")
        queue.sync {
            currentAudioPacketIndex = audioPacketIndex
            parser.tellSeek(toIndex: audioPacketIndex)
        }
    }
    
    func pollPredictedDuration() -> Duration? {
        return parser.predictedDuration
    }
    
    func pollNetworkAudioAvailabilityRange() -> (Needle, Duration) {
        return parser.pollRangeOfSecondsAvailableFromNetwork()
    }
    
    func invalidate() {
        parser.invalidate()
    }
    
    private func getPacketIndex(forNeedle needle: Needle) -> AVAudioPacketCount? {
        guard let frame = frameOffset(forTime: TimeInterval(needle)) else { return nil }
        guard let framesPerPacket = parser.fileAudioFormat?.streamDescription.pointee.mFramesPerPacket else { return nil }
        return AVAudioPacketCount(frame) / AVAudioPacketCount(framesPerPacket)
    }
    
    private func frameOffset(forTime time: TimeInterval) -> AVAudioFramePosition? {
        guard let _ = parser.fileAudioFormat?.streamDescription.pointee, let frameCount = parser.totalPredictedAudioFrameCount, let duration = parser.predictedDuration else { return nil }
        let ratio = time / duration
        return AVAudioFramePosition(Double(frameCount) * ratio)
    }
}
