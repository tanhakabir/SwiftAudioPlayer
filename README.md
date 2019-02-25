# SwiftAudioPlayer

[![CI Status](https://img.shields.io/travis/tanhakabir/SwiftAudioPlayer.svg?style=flat)](https://travis-ci.org/tanhakabir/SwiftAudioPlayer)
[![Version](https://img.shields.io/cocoapods/v/SwiftAudioPlayer.svg?style=flat)](https://cocoapods.org/pods/SwiftAudioPlayer)
[![License](https://img.shields.io/cocoapods/l/SwiftAudioPlayer.svg?style=flat)](https://cocoapods.org/pods/SwiftAudioPlayer)
[![Platform](https://img.shields.io/cocoapods/p/SwiftAudioPlayer.svg?style=flat)](https://cocoapods.org/pods/SwiftAudioPlayer)

Swift based audio player that is able to both stream remote audio and play locally saved audio, while performing audio manipulations in real-time. Underlying using AVAudioEngine, and you can change the rate of audio (up to 32x), change pitch, and [other audio enhancements](https://developer.apple.com/documentation/avfoundation/audio_track_engineering/audio_engine_building_blocks/audio_enhancements).

This player was originally developed to be used in a [podcast player](https://chameleonpodcast.com/). We had originally used AVPlayer for playing audio but we wanted to manipulate audio that was being streamed. We set up AVAudioEngine at first just to play a file saved on the phone and it worked great, but AVAudioEngine on its own doesn't support streaming audio as easily as AVPlayer.

Thus, using [AudioToolbox](https://developer.apple.com/documentation/audiotoolbox), we are able to stream audio and convert the downloaded data into usable data for the AVAudioEngine to play. For an overview of our solution check out our [blog post](https://medium.com/chameleon-podcast/creating-an-advanced-streaming-audio-engine-for-ios-9fbc7aef4115).

### Requirements

SwiftAudioPlayer is only available for iOS 10.0 and higher.

## Getting Started

### Example Project

To run the example project, clone the repo, and run `pod install` from the Example directory first.

### Installation

SwiftAudioPlayer is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SwiftAudioPlayer'
```

### Usage

To play remote audio:
```
let url = URL(string: "https://randomwebsite.com/audio.mp3")!
SAPlayer.shared.initializeAudio(withRemoteUrl: url)
SAPlayer.shared.play()
```

To set the display information for the lockscreen:
```
let info = SALockScreenInfo(title: "Random audio", artist: "Foo", artwork: UIImage(), releaseDate: 123456789)
SAPlayer.shared.mediaInfo = info
```

To receive streaming progress:
```
@IBOutlet weak var bufferProgress: UIProgressView!

override func viewDidLoad() {
    super.viewDidLoad()
    
    _ = SAPlayer.Updates.StreamingBuffer.subscribe{ [weak self] (url, buffer) in
        guard let self = self else { return }
        guard url == self.selectedAudioUrl else { return }

        let progress = Float((buffer.totalDurationBuffered + buffer.startingBufferTimePositon) / self.duration)

        self.bufferProgress.progress = progress

        self.isPlayable = buffer.isReadyForPlaying
    }
}
```


## Contact

### Issues

Submit any issues or requests [on the Github repo](https://github.com/tanhakabir/SwiftAudioPlayer/issues).

### Any questions?

Feel free to reach out to either of us:

[tanhakabir](https://github.com/tanhakabir), tanhakabir.ca@gmail.com
[JonMercer](https://github.com/JonMercer), mercer.jon@gmail.com

## License

SwiftAudioPlayer is available under the MIT license. See the LICENSE file for more info.
