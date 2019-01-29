//
//  AudioConverterErrors.swift
//  Pods-SwiftAudioPlayer_Example
//
//  Created by Tanha Kabir on 2019-01-29.
//

import Foundation
import AVFoundation
import AudioToolbox


let ReaderReachedEndOfDataError: OSStatus = 932332581
let ReaderNotEnoughDataError: OSStatus = 932332582
let ReaderMissingSourceFormatError: OSStatus = 932332583
let ReaderMissingParserError: OSStatus = 932332584
let ReaderShouldNotHappenError: OSStatus = 932332585

public enum ConverterError: LocalizedError {
    case cannotLockQueue
    case converterFailed(OSStatus)
    case cannotCreatePCMBufferWithoutConverter
    case failedToCreateDestinationFormat
    case failedToCreatePCMBuffer
    case notEnoughData
    case parserMissingDataFormat
    case reachedEndOfFile
    case unableToCreateConverter(OSStatus)
    case superConcerningShouldNeverHappen
    case throttleParsingBuffersForEngine
    case failedToCreateParser
    
    public var errorDescription: String? {
        switch self {
        case .cannotLockQueue:
            return "Failed to lock queue"
        case .converterFailed(let status):
            return localizedDescriptionFromConverterError(status)
        case .failedToCreateDestinationFormat:
            return "Failed to create a destination (processing) format"
        case .failedToCreatePCMBuffer:
            return "Failed to create PCM buffer for reading data"
        case .notEnoughData:
            return "Not enough data for read-conversion operation"
        case .parserMissingDataFormat:
            return "Parser is missing a valid data format"
        case .reachedEndOfFile:
            return "Reached the end of the file"
        case .unableToCreateConverter(let status):
            return localizedDescriptionFromConverterError(status)
        case .superConcerningShouldNeverHappen:
            return "Weird unexpected reader error. Should not have happened"
        case .cannotCreatePCMBufferWithoutConverter:
            return "Could not create a PCM Buffer because reader does not have a converter yet"
        case .throttleParsingBuffersForEngine:
            return "Preventing the reader from creating more PCM buffers since the player has more than 60 seconds of audio already to play"
        case .failedToCreateParser:
            return "Could not create a parser"
        }
    }
    
    func localizedDescriptionFromConverterError(_ status: OSStatus) -> String {
        switch status {
        case kAudioConverterErr_FormatNotSupported:
            return "Format not supported"
        case kAudioConverterErr_OperationNotSupported:
            return "Operation not supported"
        case kAudioConverterErr_PropertyNotSupported:
            return "Property not supported"
        case kAudioConverterErr_InvalidInputSize:
            return "Invalid input size"
        case kAudioConverterErr_InvalidOutputSize:
            return "Invalid output size"
        case kAudioConverterErr_BadPropertySizeError:
            return "Bad property size error"
        case kAudioConverterErr_RequiresPacketDescriptionsError:
            return "Requires packet descriptions"
        case kAudioConverterErr_InputSampleRateOutOfRange:
            return "Input sample rate out of range"
        case kAudioConverterErr_OutputSampleRateOutOfRange:
            return "Output sample rate out of range"
        case kAudioConverterErr_HardwareInUse:
            return "Hardware is in use"
        case kAudioConverterErr_NoHardwarePermission:
            return "No hardware permission"
        default:
            return "Unspecified error"
        }
    }
}
