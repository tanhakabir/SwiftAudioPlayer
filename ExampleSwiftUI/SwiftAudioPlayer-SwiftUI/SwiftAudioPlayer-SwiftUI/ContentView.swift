//
//  ContentView.swift
//  SwiftAudioPlayer-SwiftUI
//
//  Created by Ran on 4/21/21.
//

import SwiftUI

struct ContentView: View {
    
    //If you're going to use saUpdates in multiple views, consider moving this to your App file and inject it into each view. For each view save it as @ObservedObject instead of @StateObject
    @StateObject var saUpdates = SAPlayer.SAPlayerCombine.shared
    
    var body: some View {
        VStack {
            Text(saUpdates.update.elapsedTime == nil ? "Hit the play button" : "playing audio at: \(saUpdates.update.elapsedTime!)")
                .padding()
            Button(action: {
                guard let status = saUpdates.update.playingStatus else {
                    //Consider moving this stuff out of the view layer to be more scalable
                    let url = URL(string: "https://chtbl.com/track/18338/traffic.libsyn.com/secure/acquired/Acquired_-_Rec_Room_-_Final.mp3")!
                    SAPlayer.shared.startRemoteAudio(withRemoteUrl: url)
                    SAPlayer.shared.play()
                    return
                }
                
                if status == .playing {
                    SAPlayer.shared.pause()
                } else if status == .paused {
                    SAPlayer.shared.play()
                } else {
                    print("you're probably still buffering, chill...")
                }
            }, label: {
                Image(systemName: saUpdates.update.playingStatus == nil ? "play.circle.fill" : saUpdates.update.playingStatus! == .playing ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100, alignment: .center)
            })
            
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
 
