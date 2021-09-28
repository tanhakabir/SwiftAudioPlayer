# SwiftAudioPlayer

[![Version](https://img.shields.io/cocoapods/v/SwiftAudioPlayer.svg?style=flat)](https://cocoapods.org/pods/SwiftAudioPlayer)
[![License](https://img.shields.io/cocoapods/l/SwiftAudioPlayer.svg?style=flat)](https://cocoapods.org/pods/SwiftAudioPlayer)
[![Platform](https://img.shields.io/cocoapods/p/SwiftAudioPlayer.svg?style=flat)](https://cocoapods.org/pods/SwiftAudioPlayer)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Swift-based audio player with AVAudioEngine as its base. Allows for: streaming online audio, playing local file, changing audio speed (3.5X, 4X, 32X), pitch, and real-time audio manipulation using custom [audio enhancements](https://developer.apple.com/documentation/avfoundation/audio_track_engineering/audio_engine_building_blocks/audio_enhancements).

This player was built for [podcasting](https://chameleonpodcast.com/). We originally used AVPlayer for playing audio but we wanted to manipulate audio that was being streamed. We set up AVAudioEngine at first just to play a file saved on the phone and it worked great, but AVAudioEngine on its own doesn't support streaming audio as easily as AVPlayer.

Thus, using [AudioToolbox](https://developer.apple.com/documentation/audiotoolbox), we are able to stream audio and convert the downloaded data into usable data for the AVAudioEngine to play. For an overview of our solution check out our [blog post](https://medium.com/chameleon-podcast/creating-an-advanced-streaming-audio-engine-for-ios-9fbc7aef4115).

### Basic Features

1. Realtime audio manipulation that includes going up to 10x speed, using [equalizers and other manipulations](https://developer.apple.com/documentation/avfaudio/avaudiouniteq)
1. Stream online audio using AVAudioEngine
1. Stream radio
1. Play locally saved audio with the same API
1. Download audio
1. Queue up downloaded and streamed audio for autoplay
1. Uses only 1-2% CPU for optimal performance for the rest of your app
1. You're able to install taps and any other AVAudioEngine features to do cool things like skipping silences

### Special Features
These are community supported audio manipulation features using this audio engine. You can implement your own version of these features and you can look at [SAPlayerFeatures](https://github.com/tanhakabir/SwiftAudioPlayer/blob/master/Source/SAPlayerFeatures.swift) to learn how they were implemented using the library.
1. Skip silences in audio
1. Sleep timer to stop playing audio after a delay
1. Loop audio playback for both streamed and saved audio

### Requirements

iOS 10.0 and higher.

## Getting Started

### Running the Example Project

1. Clone repo
2. CD to the `Example` folder where the Example app lives
3. Run `pod install` in terminal
4. Build and run

### Installation

SwiftAudioPlayer is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SwiftAudioPlayer'
```

### Usage

Import the player at the top:
```swift
import SwiftAudioPlayer
```

**Important:** For app in background downloading please refer to [note](#important-step-for-background-downloads).

To play remote audio:
```swift
let url = URL(string: "https://randomwebsite.com/audio.mp3")!
SAPlayer.shared.startRemoteAudio(withRemoteUrl: url)
SAPlayer.shared.play()
```

To set the display information for the lockscreen:
```swift
let info = SALockScreenInfo(title: "Random audio", artist: "Foo", artwork: UIImage(), releaseDate: 123456789)
SAPlayer.shared.mediaInfo = info
```

To receive streaming progress (for buffer progress %):
```swift
@IBOutlet weak var bufferProgress: UIProgressView!

override func viewDidLoad() {
    super.viewDidLoad()

    _ = SAPlayer.Updates.StreamingBuffer.subscribe{ [weak self] buffer in
        guard let self = self else { return }

        self.bufferProgress.progress = Float(buffer.bufferingProgress)

        self.isPlayable = buffer.isReadyForPlaying
    }
}
```
Look at the [Updates](#saplayerupdates) section to see usage details and other updates to follow.


For realtime audio manipulations, [AVAudioUnit](https://developer.apple.com/documentation/avfoundation/avaudiounit) nodes are used. For example to adjust the reverb through a slider in the UI:
```swift
@IBOutlet weak var reverbSlider: UISlider!

override func viewDidLoad() {
    super.viewDidLoad()

    let node = AVAudioUnitReverb()
    SAPlayer.shared.audioModifiers.append(node)
    node.wetDryMix = 300
}

@IBAction func reverbSliderChanged(_ sender: Any) {
    if let node = SAPlayer.shared.audioModifiers[1] as? AVAudioUnitReverb {
            node.wetDryMix = reverbSlider.value
        }
}
```
For a more detailed explanation on usage, look at the [Realtime Audio Manipulations](#realtime-audio-manipulation) section.

For more details and specifics look at the [API documentation](#api-in-detail) below.


## Contact

### Issues or questions

Submit any issues, requests, and questions [on the Github repo](https://github.com/tanhakabir/SwiftAudioPlayer/issues).

### License

SwiftAudioPlayer is available under the MIT license. See the LICENSE file for more info.

---

# API in detail

## SAPlayer

Access the player and all of its fields and functions through `SAPlayer.shared`.

### Supported file types

Known supported file types are `.mp3` and `.wav`.

### Playing Audio (Basic Commands)

To set up player with audio to play, use either:
* `startSavedAudio(withSavedUrl url: URL, mediaInfo: SALockScreenInfo?)` to play audio that is saved on the device.
* `startRemoteAudio(withRemoteUrl url: URL, bitrate: SAPlayerBitrate, mediaInfo: SALockScreenInfo?)` to play audio streamed from a remote location.

Both of these expect a URL of the location of the audio and an optional media information to display on the lockscreen.  For streamed audio you can optionally set the bitrate to be `.high` or `.low`. High is more performant but won't work well for radio streams; for radio streams you should use low. The default bitrate if you don't set it is `.high`.

For streaming remote audio, subscribe to `SAPlayer.Updates.StreamingBuffer` for updates on streaming progress.

Basic controls available:
```swift
play()
pause()
togglePlayAndPause()
seekTo(seconds: Double)
skipForward()
skipBackwards()
```

### Queuing Audio for Autoplay

You can queue either remote or locally saved audio to be played automatically next.

To queue:
```swift
SAPlayer.shared.queueSavedAudio(withSavedUrl: C://random_folder/audio.mp3) // or
SAPlayer.shared.queueRemoteAudio(withRemoteUrl: https://randomwebsite.com/audio.mp3)
```

You can also directly access and modify the queue from `SAPlayer.shared.audioQueued`.

#### Important

The engine can handle audio manipulations like speed, pitch, effects, etc. To do this, nodes for effects must be finalized before initialize is called. Look at [audio manipulation documentation](#realtime-audio-manipulation) for more information.

### LockScreen Media Player

Update and set what displays on the lockscreen's media player when the player is active.

`skipForwardSeconds` and `skipBackwardSeconds` for the intervals to skip forward and back with.

`mediaInfo` for the audio's information to display on the lockscreen. Is of type `SALockScreenInfo` which contains:
```swift
title: String
artist: String
artwork: UIImage?
releaseDate: UTC // Int
```

`playbackRateOfAudioChanged(rate: Float)` is used to update the lockscreen media player that the playback rate has changed.

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

All downloads will be paused when audio is streamed from a URL. They will automatically resume when streaming is done.

Use the following to start downloading audio in the background:

```swift
func downloadAudio(withRemoteUrl url: URL, completion: @escaping (_ savedUrl: URL) -> ())
```

It will call the completion handler you pass after successful download with the location of the downloaded file on the device.

Subscribe to `SAPlayer.Updates.AudioDownloading` for downloading progress updates.

And use the following to stop any active or prevent future downloads of the corresponding remote URL:

```swift
func cancelDownload(withRemoteUrl url: URL)
```

By default downloading will be allowed on cellular data. If you would like to turn this off set:
```swift
SAPlayer.Downloader.allowUsingCellularData = false
```
You can also retrieve what preference you have set for cellular downloads through `allowUsingCellularData`.

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

**NOTE:** You're in charge or clearing downloads when your don't need them anymore

## SAPlayer.Updates

Receive updates for changing values from the player, such as the duration, elapsed time of playing audio, download progress, and etc.

All subscription functions for updates take the form of:
```swift
func subscribe(_ closure: @escaping (_ payload:  <Payload>) -> ()) -> UInt
```

- `closure`: The closure that will receive the updates. It's recommended to have a weak reference to a class that uses these functions.
- `payload`: The updated value.
- Returns: the id for the subscription in the case you would like to unsubscribe to updates for the closure.

Sometimes there is:
- `url`: The corresponding remote URL for the update. In the case there might be multiple files observed, such as downloading many files at once.

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

Changes in the duration of the current initialized audio. Especially helpful for audio that is being streamed and can change with more data. The engine makes a best effort guess as to the duration of the audio. The guess gets better with more bytes streamed from the web.

### PlayingStatus
Payload = `SAPlayingStatus`

Changes in the playing status of the player. Can be one of the following 4: `playing`, `paused`, `buffering`, `ended` (audio ended).

### StreamingBuffer
Payload = `SAAudioAvailabilityRange`

Changes in the progress of downloading audio for streaming. Information about range of audio available and if the audio is playable. Look at SAAudioAvailabilityRange for more information.

For progress of downloading audio that saves to the phone for playback later, look at AudioDownloading instead.

### AudioDownloading
Payload = `Double`

Changes in the progress of downloading audio in the background. This does not correspond to progress in streaming downloads, look at StreamingBuffer for streaming progress.

### AudioQueue
Payload = `URL`

Notification of the URL of the upcoming audio to be played. This URL may be remote or locally saved.

## Audio Effects

### Realtime Audio Manipulation

All audio effects on the player is done through [AVAudioUnit](https://developer.apple.com/documentation/avfoundation/avaudiounit) nodes. These include adding reverb, changing pitch and playback rate, and adding distortion. Full list of effects available [here](https://developer.apple.com/documentation/avfoundation/audio_track_engineering/audio_engine_building_blocks/audio_enhancements).

The effects intended to use are stored in `audioModifiers` as a list of nodes. These nodes are in the order that the engine will attach them to one another.

**Note:** By default `SAPlayer` starts off with one node, an [AVAudioUnitTimePitch](https://developer.apple.com/documentation/avfoundation/avaudiounittimepitch) node, that is set to change the rate of audio without changing the pitch of the audio (intended for changing the rate of spoken word).

#### Important
All the nodes intended to be used on the playing audio must be finalized before calling `initializeSavedAudio(...)` or `initializeRemoteAudio(...)`. Any changes to list of nodes after initialize is called for a given audio file will not be reflected in playback.

Once all nodes are added to `audioModifiers` and the player has been initialized, any manipulations done with the nodes are performed in realtime. The example app shows manipulating the playback rate in realtime:

```swift
let speed = rateSlider.value
if let node = SAPlayer.shared.audioModifiers[0] as? AVAudioUnitTimePitch {
    node.rate = speed
    SAPlayer.shared.playbackRateOfAudioChanged(rate: speed)
}
```

**Note:** if the rate of the audio is changed, `playbackRateOfAudioChanged` should also be called to update the lockscreen's media player.

