//
//  PhonemeboardViewController.swift
//  HOWL
//
//  Created by Daniel Clelland on 14/11/15.
//  Copyright © 2015 Daniel Clelland. All rights reserved.
//

import UIKit

class PhonemeboardViewController: UIViewController {
    
    @IBOutlet weak var phonemeboardView: PhonemeboardView?
    
    @IBOutlet weak var multitouchGestureRecognizer: MultitouchGestureRecognizer?
    
    @IBOutlet weak var holdButton: ToolbarButton? {
        didSet { holdButton?.selected = Settings.phonemeboardSustain.value }
    }
    
    let phonemeboard = Phonemeboard()
    
    // MARK: - Life cycle
    
    func refreshView() {
        guard let touches = multitouchGestureRecognizer?.touches else {
            return
        }
        
        phonemeboardView?.state = stateForTouches(touches)
        
        if let hue = hueForTouches(touches), let saturation = saturationForTouches(touches) {
            phonemeboardView?.hue = hue
            phonemeboardView?.saturation = saturation
        }
    }
    
    func refreshAudio() {
        guard let touches = multitouchGestureRecognizer?.touches else {
            return
        }
        
        if touches.count == 0 {
            Audio.master.mute()
        } else {
            Audio.master.unmute()
        }
        
        if let (soprano, alto, tenor, bass) = phonemesForTouches(touches) {
            Audio.sopranoVocoder.updateWithPhoneme(soprano)
            Audio.altoVocoder.updateWithPhoneme(alto)
            Audio.tenorVocoder.updateWithPhoneme(tenor)
            Audio.bassVocoder.updateWithPhoneme(bass)
        }
        
    }
    
    // MARK: - Button events
    
    @IBAction func flipButtonTapped(button: ToolbarButton) {
        flipViewController?.flip()
    }
    
    @IBAction func holdButtonTapped(button: ToolbarButton) {
        Settings.phonemeboardSustain.value = !Settings.phonemeboardSustain.value
        button.selected = Settings.phonemeboardSustain.value
        
        if !button.selected {
            multitouchGestureRecognizer?.endTouches()
        }
    }
    
    // MARK: - Private Getters
    
    private func phonemesForTouches(touches: [UITouch]) -> (Phoneme, Phoneme, Phoneme, Phoneme)? {
        guard let location = locationForTouches(touches) else {
            return nil
        }
        
        let soprano = phonemeboard.sopranoPhonemeAtLocation(location)
        let alto = phonemeboard.altoPhonemeAtLocation(location)
        let tenor = phonemeboard.tenorPhonemeAtLocation(location)
        let bass = phonemeboard.bassPhonemeAtLocation(location)
        
        return (soprano, alto, tenor, bass)
    }
    
    private func stateForTouches(touches: [UITouch]) -> PhonemeboardViewState {
        if touches.count == 0 {
            return .Normal
        }
        
        let liveTouches = touches.filter { (touch) -> Bool in
            switch touch.phase {
            case .Began:
                return true
            case .Moved:
                return true
            case .Stationary:
                return true
            case .Cancelled:
                return false
            case .Ended:
                return false
            }
        }
        
        if liveTouches.count > 0 {
            return .Highlighted
        } else {
            return .Selected
        }
    }
    
    private func hueForTouches(touches: [UITouch]) -> CGFloat? {
        guard let location = locationForTouches(touches) else {
            return nil
        }
        
        let offset = CGVectorMake(location.x - 0.5, location.y - 0.5)
        let angle = atan2(offset.dx, offset.dy)
        
        return (angle + CGFloat(M_PI)) / (2.0 * CGFloat(M_PI))
    }
    
    private func saturationForTouches(touches: [UITouch]) -> CGFloat? {
        guard let location = locationForTouches(touches) else {
            return nil
        }

        let offset = CGVectorMake(location.x - 0.5, location.y - 0.5)
        let distance = hypot(offset.dx, offset.dy)

        return distance * 2.0
    }
    
    private func locationForTouches(touches: [UITouch]) -> CGPoint? {
        guard let phonemeboardView = phonemeboardView where touches.count > 0 else {
            return nil
        }
        
        let location = touches.reduce(CGPointZero) { (location, touch) -> CGPoint in
            let touchLocation = touch.locationInView(phonemeboardView)
            
            let x = location.x + touchLocation.x / CGFloat(touches.count)
            let y = location.y + touchLocation.y / CGFloat(touches.count)
            
            return CGPointMake(x, y)
        }
        
        return CGPointApplyAffineTransform(location, phonemeboardView.bounds.normalizationTransform())
    }
    
}

// MARK: - Multitouch gesture recognizer delegate

extension PhonemeboardViewController: MultitouchGestureRecognizerDelegate {
    
    func multitouchGestureRecognizerShouldSustainTouches(gestureRecognizer: MultitouchGestureRecognizer) -> Bool {
        return Settings.phonemeboardSustain.value
    }
    
    func multitouchGestureRecognizer(gestureRecognizer: MultitouchGestureRecognizer, touchDidBegin touch: UITouch) {
        refreshView()
        refreshAudio()
    }
    
    func multitouchGestureRecognizer(gestureRecognizer: MultitouchGestureRecognizer, touchDidMove touch: UITouch) {
        refreshView()
        refreshAudio()
    }
    
    func multitouchGestureRecognizer(gestureRecognizer: MultitouchGestureRecognizer, touchDidCancel touch: UITouch) {
        refreshView()
        refreshAudio()
    }
    
    func multitouchGestureRecognizer(gestureRecognizer: MultitouchGestureRecognizer, touchDidEnd touch: UITouch) {
        refreshView()
        refreshAudio()
    }
    
}