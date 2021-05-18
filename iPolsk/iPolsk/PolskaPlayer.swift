//
//  PolskaPlayer.swift
//  iPolsk
//
//  Created by Jesper Norberg on 2021-05-14.
//

import Foundation
import AudioToolbox
import CoreAudio
import AVFoundation

enum LoopType {
    case song, bar, chord, pattern
}

/// Core Audio approch of a polyphonic midi synth largely based on http://www.rockhoppertech.com/blog/multi-timbral-avaudiounitmidiinstrument/
/// First version was based on a polyphonic AVAudioUnitMIDIInstrument,  but it didn't allow for the granular control I needed.
/// Could've had this as a singleton instead of passing it around, a matter of taste I suppose.
class PolskaPlayer: NSObject {
    var processingGraph: AUGraph?
    var midisynthNode = AUNode()
    var ioNode = AUNode()
    var midisynthUnit: AudioUnit?
    var ioUnit: AudioUnit?
    var audioEngine = AVAudioEngine()
    var stompPlayer: AVPlayer!
    var sampleRate: Float64 = 0
    var channel1 = UInt8(0)
    var channel2 = UInt8(1)
    let patch1 = UInt8(41) // violin
    let patch2 = UInt8(41) // 42 is viola, but it didn't have enough attack so going with violin again :)
    
    var counter = 0
    var timer = Timer()
    var loopType = LoopType.song
    var playing = false
    var latestSong: Song!
    var latestBarData: Bar.ViewData! // using view data for smooth in-view updates
    var latestChordData: Chord.ViewData!
    var latestPattern: Pattern!
    
    override init() {
        super.init()
        
        auGraphSetup()
        loadSoundFont()
        initializeGraph()
        initializePlayers()
        startGraph()
        setSessionPlayback()
    }
    
    func auGraphSetup() {
        var status = NewAUGraph(&processingGraph)
        guard status == noErr else {
            fatalError("error creating augraph \(status)")
        }
        
        var componentDescription = AudioComponentDescription(
            componentType: OSType(kAudioUnitType_Output),
            componentSubType: OSType(kAudioUnitSubType_RemoteIO),
            componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
            componentFlags: 0, componentFlagsMask: 0)
        status = AUGraphAddNode(self.processingGraph!, &componentDescription, &ioNode)
        guard status == noErr else {
            fatalError("Error adding io node to augraph \(status)")
        }
        
        componentDescription = AudioComponentDescription(
            componentType: OSType(kAudioUnitType_MusicDevice),
            componentSubType: OSType(kAudioUnitSubType_MIDISynth),
            componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
            componentFlags: 0, componentFlagsMask: 0)
        status = AUGraphAddNode(self.processingGraph!, &componentDescription, &midisynthNode)
        guard status == OSStatus(noErr) else {
            fatalError("Error adding synth node to augraph \(status)")
        }
        
        status = AUGraphOpen(self.processingGraph!)
        guard status == noErr else {
            fatalError("error opening augraph \(status)")
        }
        status = AUGraphNodeInfo(self.processingGraph!, self.midisynthNode, nil, &midisynthUnit)
        guard status == noErr else {
            fatalError("error setting up augraph synth wiring \(status)")
        }
        status = AUGraphNodeInfo(self.processingGraph!, self.ioNode, nil, &ioUnit)
        guard status == noErr else {
            fatalError("error setting up augraph io wiring \(status)")
        }
        
        let synthOutputElement: AudioUnitElement = 0
        let ioUnitInputElement: AudioUnitElement = 0
        
        status = AUGraphConnectNodeInput(self.processingGraph!, self.midisynthNode, synthOutputElement,  self.ioNode, ioUnitInputElement)
        guard status == noErr else {
            fatalError("error connecting synth to io \(status)")
        }
    }
    func loadSoundFont() {
        if var bankURL = Bundle.main.url(forResource: "040_Florestan_String_Quartet", withExtension: "sf2") {
            let status = AudioUnitSetProperty(
                self.midisynthUnit!,
                AudioUnitPropertyID(kMusicDeviceProperty_SoundBankURL),
                AudioUnitScope(kAudioUnitScope_Global),
                0,
                &bankURL,
                UInt32(MemoryLayout<URL>.size))
            guard status == noErr else {
                fatalError("error loading sound font \(status)")
            }
        }
        else {
            fatalError("couldn't find sound font")
        }
    }
    
    func initializeGraph() {
        let status = AUGraphInitialize(self.processingGraph!)
        guard status == noErr else {
            fatalError("error initializing au graph \(status)")
        }
    }
    
    func initializePlayers() {
        // We can't skip this step even if we don't make calls directly to it
        var dummyMusicSequence: MusicSequence?
        var status = NewMusicSequence(&dummyMusicSequence)
        guard status == noErr else {
            fatalError("error creating dummy sequence \(status)")
        }
        
        var track1: MusicTrack?
        var track2: MusicTrack?
        status = MusicSequenceNewTrack(dummyMusicSequence!, &track1)
        guard status == noErr else {
            fatalError("error creating dummy track1 \(status)")
        }
        status = MusicSequenceNewTrack(dummyMusicSequence!, &track2)
        guard status == noErr else {
            fatalError("error creating dummy track2 \(status)")
        }
        
        var bankSelectMSBMessage = MIDIChannelMessage(status: 0xB0 | channel1, data1: 0, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track1!, 0, &bankSelectMSBMessage)
        guard status == noErr else {
            fatalError("error performing bank select msb 1 \(status)")
        }
        bankSelectMSBMessage = MIDIChannelMessage(status: 0xB0 | channel2, data1: 0, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track2!, 0, &bankSelectMSBMessage)
        guard status == noErr else {
            fatalError("error performing bank select msb 2 \(status)")
        }
        
        var bankSelectLSBMessage = MIDIChannelMessage(status: 0xB0 | channel1, data1: 32, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track1!, 0, &bankSelectLSBMessage)
        guard status == noErr else {
            fatalError("error performing bank select lsb 1 \(status)")
        }
        bankSelectLSBMessage = MIDIChannelMessage(status: 0xB0 | channel2, data1: 32, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track2!, 0, &bankSelectLSBMessage)
        guard status == noErr else {
            fatalError("error performing bank select lsb 2 \(status)")
        }
        
        var programChangeMessage = MIDIChannelMessage(status: 0xC0 | channel1, data1: patch1, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track1!, 0, &programChangeMessage)
        guard status == noErr else {
            fatalError("error setting patch 1 \(status)")
        }
        programChangeMessage = MIDIChannelMessage(status: 0xC0 | channel2, data1: patch2, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track2!, 0, &programChangeMessage)
        guard status == noErr else {
            fatalError("error setting patch 2 \(status)")
        }
        
        status = MusicSequenceSetAUGraph(dummyMusicSequence!, self.processingGraph)
        guard status == noErr else {
            fatalError("error associating augraph with sequence \(status)")
        }
        
        var musicPlayer: MusicPlayer?
        
        status = NewMusicPlayer(&musicPlayer)
        guard status == OSStatus(noErr) else {
            fatalError("error creating music player \(status)")
        }
        status = MusicPlayerSetSequence(musicPlayer!, dummyMusicSequence)
        guard status == OSStatus(noErr) else {
            fatalError("error setting sequence \(status)")
        }
        status = MusicPlayerPreroll(musicPlayer!)
        if status != OSStatus(noErr) {
            fatalError("error prerolling player \(status)")
        }
        
        guard let stompURL = Bundle.main.url(forResource: "stomp", withExtension: "wav") else {
            fatalError("Failed to find stomp sound file")
        }
        stompPlayer = AVPlayer(url: stompURL)
        stompPlayer.automaticallyWaitsToMinimizeStalling = false;
    }
    
    func startGraph() {
        let status = AUGraphStart(self.processingGraph!)
        guard status == noErr else {
            fatalError("error starting augraph \(status)")
        }
    }
    
    ///  We're not using the AVAudioEngine, but we still have an audio session
    ///  Slight glitching when leaving the app, didn't find a solution for that
    func setSessionPlayback() {
        let audioSession = AVAudioSession.sharedInstance()
        do {    // this is what makes the music keep playing when you tab out
            try audioSession.setCategory(AVAudioSession.Category.playback, options: [.mixWithOthers, .allowAirPlay])
        } catch {
            print("couldn't set session category \(error)")
            return
        }
        
        do {
            try audioSession.setActive(true)
        } catch {
            print("couldn't set session active \(error)")
            return
        }
    }
    
    /// I really wanted switching between loops to be fully smooth transitions, but it proved a trickier problem than time allowed for.
    /// I would need to hot swap the edited memory into the audio playback loop. Since the audio playback loop is read only, it should be possible.
    /// Might be possible to wang jangle by having two loops and switching between them otherwise
    func prepareSongLoop(_ song: Song) {
        if loopType != LoopType.song && loopType != LoopType.bar {
            return // not sure why we get extra calls here, see comment in SongView
        }
        let wasPlaying = playing
        stop()
        latestSong = song
        loopType = LoopType.song
        if wasPlaying {
            play()
        }
    }
    
    func prepareBarLoop(_ barViewData: Bar.ViewData) {
        let wasPlaying = playing
        stop()
        latestBarData = barViewData
        latestChordData = latestSong.chordDictionary[barViewData.chordId]!.viewData
        loopType = LoopType.bar
        if wasPlaying {
            play()
        }
    }
    
    func prepareChordLoop(_ chordViewData: Chord.ViewData) {
        let wasPlaying = playing
        stop()
        latestChordData = chordViewData
        loopType = LoopType.chord
        if wasPlaying {
            play()
        }
    }
    
    func preparePatternLoop(_ pattern: Pattern) {
        let wasPlaying = playing
        stop()
        latestPattern = pattern
        loopType = LoopType.pattern
        if wasPlaying {
            play()
        }
    }
    
    func play() {
        counter = counter % Song.subBeatsInBar // maintain note index
        let subBeatsPerSecond = 3.0 * (latestSong.bpm / 60.0)
        let sampleRate = 44100 // ideally I'd like to get this dynamically
        let samplesPerSubBeat = UInt32(Double(sampleRate) / subBeatsPerSecond)
        let updateInterval = 1.0 / subBeatsPerSecond
        
        // variables get invalidated quite easily, it doesn't ever seem safe to force unwrap
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            guard let latestSong = self.latestSong else { return }
            
            let noteIndex = self.counter % Song.subBeatsInBar
            
            if latestSong.useStomps && (noteIndex == 0 || noteIndex == 6) {
                // first stomp extra loud for some reason, unaffected by player volume
                self.stompPlayer.seek(to: .zero)
                self.stompPlayer.playImmediately(atRate: 1.0)
            }
            
            if noteIndex == 0 {
                switch(self.loopType) {
                case LoopType.song:
                    let barIndex = (self.counter / Song.subBeatsInBar) % latestSong.bars.count
                    self.latestBarData = latestSong.bars[barIndex].viewData
                    fallthrough
                case LoopType.bar:
                    guard let latestBarData = self.latestBarData else { return }
                    self.latestChordData = self.latestSong.chordDictionary[self.latestBarData.chordId]?.viewData
                    guard let latestChordData = self.latestChordData else { return }
                    self.latestPattern = (latestBarData.patterns.count == 0 ? latestChordData.patterns.randomElement() : latestBarData.patterns[0])
                case LoopType.chord:
                    guard let latestChordData = self.latestChordData else { return }
                    self.latestPattern = latestChordData.patterns.randomElement()
                case LoopType.pattern:
                    break
                }
            }
            
            guard let latestChordData = self.latestChordData else { return }
            guard let latestPattern = self.latestPattern else { return }
            
            if latestPattern.scaleOffsets[noteIndex].count != 0 {
                var nextScaleIndex: Int? = nil
                if latestSong.useLeadingNote && self.loopType == LoopType.song && noteIndex == 8 {
                    let nextBarIndex = (self.counter / Song.subBeatsInBar) % latestSong.bars.count
                    let nextChordId = latestSong.bars[nextBarIndex].chordId
                    nextScaleIndex = latestSong.chordDictionary[nextChordId]?.scaleIndex ?? 0
                }
                
                self.playMIDINotes(latestPattern, noteIndex, latestChordData.scaleIndex, samplesPerSubBeat, nextScaleIndex)
            }
            
            self.counter = self.counter + 1
        }
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common) // otherwise lag on scroll
        playing = true
    }
    
    func stop() {
        timer.invalidate()
        timer = Timer()
        playing = false
    }
    
    func isPlaying() -> Bool {
        return playing
    }
    
    func togglePlaying() {
        if playing {
            stop()
        }
        else {
            play()
        }
    }
    
    func playMIDINotes(_ pattern: Pattern, _ noteIndex: Int, _ chordScaleIndex: Int, _ samplesPerSubBeat: UInt32, _ nextScaleIndex: Int?) {
        let patternOffset = pattern.scaleOffsets[noteIndex].randomElement()!
        var scaleIndex1 = min(max(latestChordData.scaleIndex + patternOffset, 0), Song.majorScale.count-1)
        if let nextIndex = nextScaleIndex {
            // this is a way to create more cohesion between the bars
            // I also had an idea about categorizing patterns as either up/down and prioritizing
            // selection based on this.
            scaleIndex1 = scaleIndex1 < nextIndex ? nextIndex-1 : nextIndex+1
        }
        
        let midiNote1 = UInt32(latestSong.baseNote + (latestSong.isMajor ? Song.majorScale[scaleIndex1] : Song.minorScale[scaleIndex1]))
        
        var midiVelocity1: UInt32 = 55
        if noteIndex == 0
            || (noteIndex == 6 && (latestPattern!.scaleOffsets[7].count == 0 || latestPattern!.scaleOffsets[8].count != 0))
            || (noteIndex == 7 && latestPattern!.scaleOffsets[8].count == 0)
        {
            // normally emphasis on 0 and 6, but if beat on 7 and not 8, emphasis on 7 instead of 6
            midiVelocity1 = 70
        }
        
        var numNilsUntilNextNote : UInt32 = 0
        for i in (noteIndex+1)..<Song.subBeatsInBar {
            if latestPattern!.scaleOffsets[i].count == 0 {
                numNilsUntilNextNote += 1
            }
            else {
                break
            }
        }
        let durationInSamples = samplesPerSubBeat * (numNilsUntilNextNote + 1)
        
        let playStatus = MusicDeviceMIDIEvent(self.midisynthUnit!, UInt32(0x90 | self.channel1), midiNote1, midiVelocity1, 0)
        let stopStatus = MusicDeviceMIDIEvent(self.midisynthUnit!, UInt32(0x80 | self.channel1), midiNote1, 0, durationInSamples)
        if playStatus != noErr || stopStatus != noErr {
            print("error playing note 1") // not fatal
        }
        
        if latestSong.useSecondVoice {
            let scaleIndex2 = latestSong.useSecondVoiceDrone ? 0 : PolskaPlayer.findNoteForSecondVoice(scaleIndex1, latestSong.isMajor)
            let midiNote2 = UInt32(latestSong.baseNote + (latestSong.isMajor ? Song.majorScale[scaleIndex2] : Song.minorScale[scaleIndex2]))
            
            let midiVelocity2: UInt32 = midiVelocity1 - 10 // otherwise it overpowers a bit
            let playStatus = MusicDeviceMIDIEvent(self.midisynthUnit!, UInt32(0x90 | self.channel2), midiNote2, midiVelocity2-10, 0)
            let stopStatus = MusicDeviceMIDIEvent(self.midisynthUnit!, UInt32(0x80 | self.channel2), midiNote2, 0, durationInSamples)
            if playStatus != noErr || stopStatus != noErr {
                print("error playing note 2") // not fatal
            }
        }
    }
    
    // could be more advanced melodically as well as deviating on rhythm too
    static func findNoteForSecondVoice(_ scaleIndex1: Int, _ isMajor: Bool) -> Int {
        switch scaleIndex1 {
        case 0:
            return 2
        case 1:
            return 3
        case 2:
            return 0
        case 3:
            return 1
        case 4:
            return 2
        case 5:
            return 3
        case 6:
            return isMajor ? 1 : 2
        case 7:
            return 4
        case 1+7:
            return 6
        case 2+7:
            return 7
        case 3+7:
            return 1+7
        case 4+7:
            return 2+7
        case 5+7:
            return 3+7
        case 6+7:
            return isMajor ? 1+7 : 2+7
        case 7+7:
            return 4+7
        default:
            fatalError("scale index out of bounds")
        }
    }
    
}
