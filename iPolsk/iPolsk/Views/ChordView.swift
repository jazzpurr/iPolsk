//
//  ChordView.swift
//  iPolsk
//
//  Created by Jesper Norberg on 2021-05-14.
//

import SwiftUI
import Combine

struct ChordView: View {
    @Binding var chord: Chord
    var player : PolskaPlayer
    
    @State private var playing = false
    @State private var data = Chord.ViewData()
    @State private var sliderValue : Double = 0
    @State private var showingAlert = false
    
    var body: some View {
        List {
            Section(header: Text("Patterns")) {
                ForEach(data.patterns.indices, id:\.self) { i in
                    NavigationLink(destination: PatternView(pattern: $data.patterns[i], player: player)) {
                        Label(getPatternNameSafely(i), systemImage: "smallcircle.circle")
                            .font(.system(size: 25, design: .monospaced))
                    }
                }
                .onDelete { index in
                    data.patterns.remove(atOffsets: index)
                    if data.patterns.count == 0 {
                        data.patterns.append(Pattern()) // won't allow empty list
                    }
                    player.prepareChordLoop(data)
                }
                
                HStack {
                    Text("Add new pattern")
                    Button(action: {
                        data.patterns.append(Pattern())
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }.padding()
                }
            }
            Section(header: Text("Chords")) {
                Text("Chord name: \(data.name)")
                HStack {
                    Text("Origin note: \(Int(self.sliderValue.rounded()))")
                    Spacer()
                    Slider(value: $sliderValue, in: -7...7, step: 1.0, onEditingChanged: { _ in
                        data.scaleIndex = Int(sliderValue.rounded())+7
                        player.prepareChordLoop(data)
                    })
                }
            }
            Section(header: Text("Color")) {
                ColorPicker("Color", selection: $data.color)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .onAppear {
            data = chord.viewData
            sliderValue = Double(data.scaleIndex-7)
            playing = player.isPlaying()
            player.prepareChordLoop(data)
        }
        .onDisappear {
            chord.update(data)
        }
        .navigationTitle("Chord \(data.name)")
        .navigationBarItems(
            trailing: HStack {
                Button("Help") {
                    showingAlert = true
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("T H E    C H O R D"), message: Text("In this view you control which patterns belong to the chord. The same chord can be used by multiple bars. Try to get a feel for the function of the chord, eg. a IV chord's primary function is to lead to the V. You can also change the origin note of the chord as well as the overview color."), dismissButton: .default(Text("Got it!")))
                }
                Button(action: {
                    player.prepareChordLoop(data)
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
    
    private func getPatternNameSafely(_ i: Int) -> String {
        // so after removal retrieval at index can fail
        if i >= self.data.patterns.count {
            return "" // safeguard for intermediate state
        }
        else {
            return data.patterns[i].name
        }
    }
}
