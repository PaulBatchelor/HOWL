//
//  Master.swift
//  HOWL
//
//  Created by Daniel Clelland on 15/11/15.
//  Copyright © 2015 Daniel Clelland. All rights reserved.
//

import AudioKit

class Master: AKInstrument {
    
    var amplitude = AKInstrumentProperty(value: 0.0, minimum: 0.0, maximum: 1.0)
    
    var bitcrushMix = AKInstrumentProperty(value: 0.0, minimum: 0.0, maximum: 1.0)
    var reverbMix = AKInstrumentProperty(value: 0.0, minimum: 0.0, maximum: 1.0)
    
    init(withInput input: AKAudio, voices: [AKAudio]) {
        super.init()
        
        addProperty(amplitude)
        
        addProperty(bitcrushMix)
        addProperty(reverbMix)
        
        let sum = AKSum()
        
        sum.inputs = voices
        
        let balance = AKBalance(
            input: sum,
            comparatorAudioSource: input * amplitude * 0.125.ak
        )
        
        let bitcrush = AKDecimator(
            input: balance,
            bitDepth: 24.ak,
            sampleRate: 4000.ak
        )
        
        let bitcrushOutput = AKMix(
            input1: balance,
            input2: bitcrush,
            balance: bitcrushMix
        )
        
        let reverb = AKReverb(
            input: bitcrushOutput,
            feedback: 0.75.ak,
            cutoffFrequency: 16000.ak
        )
        
        let reverbLeftOutput = AKMix(
            input1: bitcrushOutput,
            input2: reverb.leftOutput,
            balance: reverbMix
        )
        
        let reverbRightOutput = AKMix(
            input1: bitcrushOutput,
            input2: reverb.rightOutput,
            balance: reverbMix
        )
        
        let output = AKStereoAudio(leftAudio: reverbLeftOutput, rightAudio: reverbRightOutput)
        
        connect(sum)
        
        setStereoAudioOutput(output)
        
        resetParameter(input)
        
        voices.forEach { self.resetParameter($0) }
    }
    
    // MARK: - Actions
    
    func mute() {
        amplitude.value = 0.0
    }
    
    func unmute() {
        amplitude.value = 1.0
    }
    
}