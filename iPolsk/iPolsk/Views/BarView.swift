//
//  BarView.swift
//  iPolsk
//
//  Created by Jesper Norberg on 2021-05-14.
//

import SwiftUI

struct BarView: View {
    @Binding var song: Song
    @Binding var bar: Bar
    var index: Int
    var player : PolskaPlayer
    
    @State private var playing = false
    @State private var data = Bar.ViewData()
    @State private var chordName = ""
    @State private var presentAllChordsView = false
    @State private var showingAlert = false
    
    var body: some View {
        List {
            Section(header: Text("Chord")) {
                NavigationLink(
                    destination: ChordView(chord: binding(bar.chordId), player: player)) {
                    Label("Edit bar chord \(chordName)", systemImage: "music.note.list")
                        .font(.headline)
                }
                HStack {
                    Text("Choose new chord")
                    Button(action: {
                        presentAllChordsView = true
                    }) {
                        Image(systemName: "music.note.list")
                    }.padding()
                }
            }
            Section(header: Text("Fixed pattern")) {
                if data.patterns.count != 0 {
                    ForEach(data.patterns, id:\.self) { pattern in // we only have 1, this is for consistent list removal
                        NavigationLink(destination: PatternView(pattern: $data.patterns[0], player: player)) {
                            Label(pattern.name, systemImage: "smallcircle.circle")
                                .font(.system(size: 25, design: .monospaced))
                        }
                    }
                    .onDelete { _ in
                        data.patterns = []
                        bar.update(data)
                        player.prepareBarLoop(data)
                    }
                }
                else {
                    HStack {
                        Text("Add fixed pattern for bar")
                        Spacer()
                        Button(action: {
                            data.patterns = [Pattern()]
                            bar.update(data)
                            player.prepareBarLoop(data)
                        }) {
                            Image(systemName: "plus.circle.fill")
                        }.padding()
                    }
                }
            }
        }
        .onAppear {
            data = bar.viewData
            chordName = song.chordDictionary[data.chordId]!.name
            playing = player.isPlaying()
            player.prepareBarLoop(data)
        }
        .onDisappear {
            bar.update(data)
        }
        .fullScreenCover(isPresented: $presentAllChordsView) {
            NavigationView {
                AllChordsView(song: $song, chosenChordId: $data.chordId, presentAllChordsView: $presentAllChordsView, barData: $data, player: player)
                    .navigationTitle("Choose new chord")
                    .navigationBarItems(leading: Button("Cancel") {
                        presentAllChordsView = false
                        player.prepareBarLoop(data)
                    },
                    trailing: Button(action: {
                        player.prepareBarLoop(data)
                        player.togglePlaying()
                        playing = !playing
                    }) {
                        if playing {
                            Image(systemName: "stop")
                        }
                        else {
                            Image(systemName: "play")
                        }
                    })
                    .onDisappear {
                        chordName = song.chordDictionary[data.chordId]!.name
                    }
                
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Bar " + String(index))
        .navigationBarItems(
            trailing: HStack {
                Button("Help") {
                    showingAlert = true
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("T H E    B A R"), message: Text("In this view you can choose which chord the bar should use. A chord consists of patterns, so the bar will randomly pick one of the patterns in the chord. If you have something specific in mind you can set a fixed pattern instead, which the bar will then always play. It keeps the base note of the chord however."), dismissButton: .default(Text("Got it!")))
                }
                Button(action: {
                    player.prepareBarLoop(data)
                    player.togglePlaying()
                    playing = !playing
                })
                {
                    if playing {
                        Image(systemName: "stop")
                    }
                    else {
                        Image(systemName: "play")
                    }
                }
            }
        )
    }
    
    private func binding(_ key: UUID) -> Binding<Chord> {
        return .init(
            get: { self.song.chordDictionary[key, default: Chord("", 0)] },
            set: { self.song.chordDictionary[key] = $0 })
    }
}
