//
//  DirectorThreadSafeClosures.swift
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

enum DirectorError: Error {
    case closureIsDead
}

/**
 P for payload
 */
class DirectorThreadSafeClosures<P>  {
    typealias TypeClosure = (P) throws -> Void
    fileprivate var queue: DispatchQueue = DispatchQueue(label: "SwiftAudioPlayer.thread_safe_map", attributes: .concurrent)
    fileprivate var map: [String: TypeClosure] = [:]
    
    func broadcast(payload: P) {
        queue.sync {
            var iterator = self.map.makeIterator()
            while let element = iterator.next() {
                do {
                    try element.value(payload)
                } catch {
                    helperRemove(withKey: element.key)
                }
            }
        }
    }
    
    //UInt is actually 64-bits on modern devices
    func attach(closure: @escaping TypeClosure, payload: P?) -> UInt {
        let id: UInt = Date.getUTC64()
        
        //The director may not yet have the status yet. We should only call the closure if we have it
        if let p = payload {
            //Let the caller know the immediate value. If it's dead already then stop
            do {
                try closure(p)
            } catch {
                return id
            }
        }
        
        //Replace what's in the map with the new closure
        helperInsert(withKey: "\(id)", closure: closure)
        
        return id
    }
    
    func attach(id: String, closure: @escaping TypeClosure, payload: P?) {
        
        //Check if ID already exists. If it exists keep going and replace what's already there
        queue.sync {
            if map[id] != nil {
                Log.warn("Trying to attach with same id twice! id: \(id)")
            }
        }
        
        //The director may not yet have the status yet. We should only call the closure if we have it
        if let p = payload {
            //Let the caller know the immediate value. If it's dead already then stop
            do {
                try closure(p)
            } catch {
                return
            }
        }
        
        //Replace what's in the map with the new closure
        helperInsert(withKey: id, closure: closure)
    }
    
    func detach(id: UInt) {
        helperRemove(withKey: "\(id)")
    }
    
    func detach(id: String) {
        helperRemove(withKey: id)
    }
    
    func clear() {
        queue.async(flags: .barrier) {
            self.map.removeAll()
        }
    }
    
    private func helperRemove(withKey key: String) {
        queue.async(flags: .barrier) {
            self.map[key] = nil
        }
    }
    
    private func helperInsert(withKey key: String, closure: @escaping TypeClosure) {
        queue.async(flags: .barrier) {
            self.map[key] = closure
        }
    }
}
