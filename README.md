# SwiftAudioPlayer

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
```swift
let url = URL(string: "https://randomwebsite.com/audio.mp3")!
SAPlayer.shared.initializeAudio(withRemoteUrl: url)
SAPlayer.shared.play()
```

To set the display information for the lockscreen:
```swift
let info = SALockScreenInfo(title: "Random audio", artist: "Foo", artwork: UIImage(), releaseDate: 123456789)
SAPlayer.shared.mediaInfo = info
```

To receive streaming progress:
```swift
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
Look at the [Updates](#SAPlayer.Updates) section to see usage details and other updates to follow.

**Important:** For app in background downloading please refer to [note](#important-step-for-background-downloads).

For more details and specifics look at the [API documentation](#api-in-detail) below.

## Contact

### Issues

Submit any issues or requests [on the Github repo](https://github.com/tanhakabir/SwiftAudioPlayer/issues).

### Any questions?

Feel free to reach out to either of us:

[tanhakabir](https://github.com/tanhakabir), tanhakabir.ca@gmail.com
[JonMercer](https://github.com/JonMercer), mercer.jon@gmail.com

### License

SwiftAudioPlayer is available under the MIT license. See the LICENSE file for more info.

---

# API in detail

## SAPlayer.Downloader

Use functionaity from Downloader to save audio files from remote locations for future offline playback.

Audio files are saved under custom naming scheme on device and are recoverable with original remote URL for file.

#### Important step for background downloads

To ensure that your app will keep downloading audio in the background be sure to add the following to `AppDelegate.swift`:

```swift
func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
    SAPlayer.Downloader.setBackgroundCompletionHandler(completionHandler)
}
```

### Downloading

Downloads will be held on pause when active stream is started, and will resume downloads when streaming is done.

Use the following to start downloading audio in the background:

```swift
func downloadAudio(withRemoteUrl url: URL, completion: @escaping (_ savedUrl: URL) -> ())
```

It will call the completion handler you pass after successful download with the location of the downloaded file on the device.

And use the following to stop any active or prevent future downloads of the corresponding remote URL:

```swift
func cancelDownload(withRemoteUrl url: URL)
```

### Manage Downloaded

Use the following to manage downloaded audio files.

Checks if downloaded already:
```swift
func isDownloaded(withRemoteUrl url: URL) -> Bool
```

Get URL of audio file saved on device corresponding to remote location:
```swift
func getSavedUrl(forRemoteUrl url: URL) -> URL?
```

Delete downloaded audio if it exists:
```swift
func deleteDownloaded(withSavedUrl url: URL)
```

## SAPlayer.Updates

Receive updates for changing values from the player, such as the duration, elapsed time of playing audio, download progress, and etc.

All subscription functions for updates take the form of:
```swift
func subscribe(_ closure: @escaping (_ url: URL, _ payload:  <Payload>) -> ()) -> UInt
```

- `closure`: The closure that will receive the updates. It's recommended to have a weak reference to a class that uses these functions.
- `url`: The corresponding remote URL for the update. In the case there might be multiple files observed, such as downloading many files at once or switching over from playing one audio to another and the updates corresponding to the previous aren't silenced on switch-over.
- `payload`: The updated value.
- Returns: the id for the subscription in the case you would like to unsubscribe to updates for the closure.

Similarily unsubscribe takes the form of: 
```swift
func unsubscribe(_ id: UInt)
```

- `id`: The closure with this id will stop receiving updates.


### ElapsedTime
Payload = `Double`

Changes in the timestamp/elapsed time of the current initialized audio. Aka, where the scrubber's pointer of the audio should be at.

Subscribe to this to update views on changes in position of which part of audio is being played.

### Duration
Payload = `Double`

Changes in the duration of the current initialized audio. Especially helpful for audio that is being streamed and can change with more data.

### PlayingStatus
Payload = `SAPlayingStatus`

Changes in the playing status of the player. Can be one of the following 3: `playing`, `paused`, `buffering`.

### StreamingBuffer
Payload = `SAAudioAvailabilityRange`

Changes in the progress of downloading audio for streaming. Information about range of audio available and if the audio is playable. Look at SAAudioAvailabilityRange for more information. 

For progress of downloading audio that saves to the phone for playback later, look at AudioDownloading instead.

### AudioDownloading
Payload = `Double`

Changes in the progress of downloading audio in the background. This does not correspond to progress in streaming downloads, look at StreamingBuffer for streaming progress.
