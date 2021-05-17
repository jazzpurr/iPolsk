//
//  Song.swift
//  iPolsk
//
//  Created by Jesper Norberg on 2021-05-14.
//

import Foundation
import SwiftUI

struct Song: Identifiable, Codable {
    let id: UUID
    var name : String
    var isMajor : Bool = true
    var useSecondVoice : Bool = true
    var useSecondVoiceDrone : Bool = false
    var useStomps : Bool = true
    var useLeadingNote : Bool = true
    
    var bpm : Double = 120.0
    var baseNote = 12*5 //C4
    static let subBeatsInBar = 9
    static let majorScale = [-12, -10, -8, -7, -5, -3, -1, 0, 2, 4, 5, 7, 9, 11, 12]
    static let minorScale = [-12, -10, -9, -7, -5, -4, -2, 0, 2, 3, 5, 7, 8, 10, 12]
    var chordDictionary: Dictionary<UUID, Chord> = [:] // since we can't get updates when propagating chord as a class
    var bars : [Bar]
    var chordIdForNewBars : UUID
    
    init(_ name: String){
        self.name = name
        id = UUID()
        
        var chords = [Chord("Ⅰ", 0+7), Chord("Ⅱ", 1+7), Chord("Ⅲ", 2+7), Chord("Ⅳ", 3+7), Chord("Ⅴ", 4+7), Chord("Ⅵ", 5+7), Chord("Ⅶ", 6+7)]
        chords[0].addPattern(Pattern([[0], [], [], [],   [], [0],  [1],  [],   [0]]))
        chords[0].addPattern(Pattern([[0], [], [], [2],  [], [0],  [1],  [3],  []]))
        chords[0].addPattern(Pattern([[0], [], [], [2],  [], [0],  [1],  [],   [3]]))
        chords[0].addPattern(Pattern([[0], [], [], [2],  [], [0],  [1],  [],   [2]]))
        chords[2].addPattern(Pattern([[0], [], [], [0],  [], [-2], [2],  [],   [0]]))
        chords[2].addPattern(Pattern([[0], [], [], [0],  [], [1],  [0],  [],   [1]]))
        chords[3].addPattern(Pattern([[0], [], [], [0],  [], [-2], [2],  [],   [0]]))
        chords[3].addPattern(Pattern([[0], [], [], [0],  [], [1],  [0],  [],   [1]]))
        chords[3].addPattern(Pattern([[0], [], [], [2],  [], [0],  [1],  [2],  []]))
        chords[3].addPattern(Pattern([[0], [], [], [2],  [], [1],  [0],  [],   [-1]]))
        chords[4].addPattern(Pattern([[0], [], [], [0],  [], [-1], [-2], [],   []]))
        chords[4].addPattern(Pattern([[0], [], [], [1],  [], [0],  [-1], [-2], []]))
        chords[4].addPattern(Pattern([[0], [], [], [-1], [], [-2], [-1], [1],  []]))
        chords[4].addPattern(Pattern([[0], [], [], [0],  [], [-1], [-3], [],   [-2]]))
        chords[4].addPattern(Pattern([[0], [], [], [0],  [], [-2], [1],  [],   [0]]))
        chords[4].addPattern(Pattern([[0], [], [], [1],  [], [0],  [-1], [0],  []]))
        // these are leading chords, so empty by comparison
        chords[1].addPattern(Pattern([[0], [], [], [0],  [], [-2], [-4], [],   []]))
        chords[5].addPattern(Pattern([[0], [], [], [3],  [], [1],  [-1], [-2], []]))
        chords[5].addPattern(Pattern([[0], [], [], [4],  [], [2],  [0],  [-1], []]))
        chords[6].addPattern(Pattern([[0], [], [], [0],  [], [-1], [-2], [],   [-3]]))
        
        let increment = 1.0/7.0
        for i in 0..<chords.count {
            chords[i].color = Color(red: 1.0 - Double(i)*increment, green: 0.0, blue: Double(i)*increment)
        }
        
        chordIdForNewBars = chords[0].id
        for chord in chords {
            chordDictionary[chord.id] = chord
        }
        
        bars = [  Bar(chords[0]), Bar(chords[2]), Bar(chords[4]), Bar(chords[0])
                , Bar(chords[0]), Bar(chords[4]), Bar(chords[4]), Bar(chords[0])
                , Bar(chords[4]), Bar(chords[3]), Bar(chords[4]), Bar(chords[3])
                , Bar(chords[0]), Bar(chords[2]), Bar(chords[4]), Bar(chords[0])
                , Bar(chords[0]), Bar(chords[2]), Bar(chords[4]), Bar(chords[0])
                , Bar(chords[0]), Bar(chords[4]), Bar(chords[4]), Bar(chords[0])
                , Bar(chords[4]), Bar(chords[3]), Bar(chords[4]), Bar(chords[3])
                , Bar(chords[0]), Bar(chords[2]), Bar(chords[4]), Bar(chords[0])]
    }
}

extension Song {
    struct SettingsViewData {
        var name : String = ""
        var isMajor : Bool = true
        var useSecondVoice : Bool = true
        var useSecondVoiceDrone : Bool = true
        var useStomps : Bool = true
        var useLeadingNote : Bool = true
        var bpm : String = "120" // string because double slider didn't work
        var baseNote : Double = 12*5
    }
    
    var settingsViewData: SettingsViewData {
        return SettingsViewData(name: name, isMajor: isMajor, useSecondVoice: useSecondVoice, useSecondVoiceDrone: useSecondVoiceDrone, useStomps: useStomps, useLeadingNote: useLeadingNote, bpm: String(Int(bpm.rounded())), baseNote: Double(baseNote))
    }
    
    mutating func update(_ data: SettingsViewData) {
        name = data.name
        isMajor = data.isMajor
        useSecondVoice = data.useSecondVoice
        useSecondVoiceDrone = data.useSecondVoiceDrone
        useStomps = data.useStomps
        useLeadingNote = data.useLeadingNote
        bpm = Double(Int(data.bpm) ?? 120)
        baseNote = Int(data.baseNote.rounded())
    }
}
