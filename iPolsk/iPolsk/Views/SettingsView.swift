//
//  SettingsView.swift
//  iPolsk
//
//  Created by Jesper Norberg on 2021-05-14.
//

import SwiftUI

struct SettingsView: View {
    @Binding var data: Song.SettingsViewData
    var body: some View {
        List {
            Section(header: Text("Song settings")) {
                HStack {
                    Text("Song name: ")
                    TextField("", text: $data.name)
                }
                Toggle(isOn: $data.isMajor) {
                    Text("Song in major")
                }
                HStack { // the samples will eventually stop playing outside a certain range
                    Slider(value: $data.baseNote, in: 48...72, step: 1.0) // C3-C5, and then one octave +/- that in offsets
                    Spacer()
                    Text("\(midiToLatin(data.baseNote, data.isMajor))")
                }
                Toggle(isOn: $data.useSecondVoice) {
                    Text("Play second violin")
                }
                Toggle(isOn: $data.useSecondVoiceDrone) {
                    Text("Have second violin drone")
                }
                Toggle(isOn: $data.useStomps) {
                    Text("Play stomps")
                }
                Toggle(isOn: $data.useLeadingNote) {
                    Text("Use leading note")
                }
                // two sliders in same view doesn't seem to work out of the box at least
                /*
                HStack {
                    Slider(value: $data.bpm, in: 50...150, step: 1.0)
                    Spacer()
                    Text("\(Int(data.baseNote.rounded())) bpm")
                }
                */
            }
        }
        .listStyle(InsetGroupedListStyle())
        // .navigation items are appended in song view
    }
    private func midiToLatin(_ baseNoteDouble: Double, _ isMajor: Bool) -> String {
        let baseNote = Int(baseNoteDouble.rounded())
        let octaveDigit = (baseNote / 12) - 1 // C4 == 60
        var key = ""
        switch (baseNote % 12) {
        case 0:
            key = "C"
        case 1:
            key = isMajor ? "C♯" : "D♭"
        case 2:
            key = "D"
        case 3:
            key = isMajor ? "D♯" : "E♭"
        case 4:
            key = "E"
        case 5:
            key = "F"
        case 6:
            key = isMajor ? "F♯" : "G♭"
        case 7:
            key = "G"
        case 8:
            key = isMajor ? "G♯" : "A♭"
        case 9:
            key = "A"
        case 10:
            key = isMajor ? "A♯" : "B♭"
        case 11:
            key = "B"
        default:
            fatalError("But it's already exhaustive")
        }
        return key + String(octaveDigit)
    }
}
