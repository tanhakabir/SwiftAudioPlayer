//
//  ViewController.swift
//  SwiftAudioPlayer
//
//  Created by tanhakabir on 01/28/2019.
//  Copyright (c) 2019 tanhakabir. All rights reserved.
//

import UIKit
import SwiftAudioPlayer

class ViewController: UIViewController {
    @IBOutlet weak var bufferProgress: UIProgressView!
    @IBOutlet weak var scrubberSlider: UISlider!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var skipBackwardButton: UIButton!
    @IBOutlet weak var skipForwardButton: UIButton!
    
    @IBOutlet weak var audioSelector: UISegmentedControl!
    @IBOutlet weak var streamButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var rateSlider: UISlider!
    
    @IBOutlet weak var rateLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        adjustSpeed()
        
        var foo = SALockScreenInfo(title: "", artist: "", artwork: UIImage(), releaseDate: 12)
        SAPlayer.shared.mediaInfo = foo
        SAPlayer.shared.initializeAudio(withRemoteUrl: URL(string: "https://traffic.megaphone.fm/TTH7630150098.mp3")!)

        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func scrubberSeeked(_ sender: Any) {
    }
    
    
    @IBAction func rateChanged(_ sender: Any) {
        adjustSpeed()
    }
    
    private func adjustSpeed() {
        let speed = rateSlider.value
        rateLabel.text = "rate: \(speed)x"
        SAPlayer.shared.rate = Double(speed)
    }
    
}

