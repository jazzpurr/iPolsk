//
//  PatternView.swift
//  iPolsk
//
//  Created by Jesper Norberg on 2021-05-14.
//


import SwiftUI

struct PatternView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var pattern: Pattern
    var player : PolskaPlayer
    
    @State private var playing = false
    @State private var data : [[Bool]] = Array.init(repeating: Array.init(repeating: false, count: 9), count: 15)
    @State private var showingAlert = false
    
    var columns: [GridItem] = Array.init(repeating: GridItem(spacing: 6), count: 9)
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: columns,
                alignment: .center,
                spacing: 6,
                pinnedViews: [.sectionHeaders]
            ) {
                ForEach(0..<15) { row in
                    // first column is reserved
                    Image(systemName: getFirstColSymbolName(row))
                        .foregroundColor(row == 7 ? Color.red : Color.blue)
                        .font(.largeTitle)
                        .frame(height: 30)
                    ForEach(1..<9) { col in
                        Button(action: {}){
                            Image(systemName: (data[row][col] ? "smallcircle.circle.fill" : "smallcircle.circle"))
                                .foregroundColor(data[row][col] ? Color.red : Color.blue)
                                .font(.largeTitle)
                                .frame(height: 30)
                                .onTapGesture {
                                    self.touchAction(row, col)
                                }
                        }
                    }
                }
            }
        }
        .onAppear {
            playing = player.isPlaying()
            player.preparePatternLoop(pattern)
            
            for col in 0..<pattern.scaleOffsets.count {
                for scaleOffset in pattern.scaleOffsets[col] {
                    let row = 7 - scaleOffset
                    data[row][col] = true
                }
            }
        }
        .onDisappear {
            pattern.update(data)
        }
        .navigationTitle("Pattern")
        .navigationBarItems(
            trailing: HStack {
                Button("Help") {
                    showingAlert = true
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("T H E    P A T T E R N"), message: Text("In this view you specify what the individual pattern should look like. You can choose between the scale tones one octave up/down from where you are now. You can't edit the first note in the bar. The polska is automatically emphasized at the right places, namely beat 1 and 7 (and sometimes 8, can you tell when?) If you have two cells active in the same column, the pattern will take one at random each time it runs. Since patterns are randomly chosen by the chord, try to make one that's not overly situational."), dismissButton: .default(Text("Got it!")))
                }
                Button(action: {
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
    private func getFirstColSymbolName(_ row: Int) -> String {
        switch(row){
        case 7: return "smallcircle.circle.fill"
        case 0...7: return String(7-row) + (colorScheme == .dark ? ".circle.fill" : ".circle")
        default: return String(row-7) + (colorScheme == .dark ? ".circle" : ".circle.fill")
        }
    }
    
    private func touchAction(_ row: Int, _ col: Int) {
        data[row][col] = !data[row][col]
        
        var playbackPattern = Pattern()
        playbackPattern.update(data)
        player.preparePatternLoop(playbackPattern)
    }
}
