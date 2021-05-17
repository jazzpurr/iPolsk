//
//  AllChordsView.swift
//  iPolsk
//
//  Created by Jesper Norberg on 2021-05-14.
//

import SwiftUI

struct AllChordsView: View {
    @Binding var song: Song
    @Binding var chosenChordId: UUID
    @Binding var presentAllChordsView: Bool
    @Binding var barData: Bar.ViewData
    var player : PolskaPlayer
    
    @State private var playing = false
    @State private var data: [Chord] = []
    @State private var newChordName = ""
    var body: some View {
        List {
            Section(header: Text("Chords")) {
                ForEach(data.indices, id: \.self) { i in
                    HStack {
                        Text("Chord: " + data[i].name)
                        Button(action: {
                            chosenChordId = data[i].id
                            barData.chordId = data[i].id
                            presentAllChordsView = false
                            player.prepareBarLoop(barData)
                            
                        }) {
                            Image(systemName: "music.note.list")
                        }.padding()
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .onAppear {
            playing = player.isPlaying()
            data = []
            for (_, value) in song.chordDictionary {
                data.append(value)
            }
            data.sort(by: { $0.name < $1.name })
        }
        // .navigation items are appended in bar view
    }
}
