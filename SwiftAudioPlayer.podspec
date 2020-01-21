#
# Be sure to run `pod lib lint SwiftAudioPlayer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftAudioPlayer'
  s.version          = '2.8.2'
  s.summary          = 'SwiftAudioPlayer is a Swift based audio player that can handle streaming from a remote location and audio manipulation.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
SwiftAudioPlayer is a Swift based audio player that can handle streaming from a remote location and audio manipulation. It can perform actions like playing audio up to 32x playback rate on streamed audio.
                       DESC

  s.homepage         = 'https://github.com/tanhakabir/SwiftAudioPlayer'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tanhakabir' => 'tanhakabir.ca@gmail.com', 'JonMercer' => 'mercer.jon@gmail.com' }
  s.source           = { :git => 'https://github.com/tanhakabir/SwiftAudioPlayer.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'Source/**/*'
  s.swift_version = '5.0'
  
  # s.resource_bundles = {
  #   'SwiftAudioPlayer' => ['SwiftAudioPlayer/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
