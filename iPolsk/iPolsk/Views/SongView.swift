//
//  SongView.swift
//  iPolsk
//
//  Created by Jesper Norberg on 2021-05-14.
//

import SwiftUI

struct SongView: View {
    @Binding var song: Song
    var player: PolskaPlayer
    @State private var playing = false
    @State private var showingSettings = false
    @State private var settingsViewData = Song.SettingsViewData()
    @State private var showingAlert = false
    
    @Environment(\.scenePhase) private var scenePhase
    let saveAction: () -> Void  // save when we tab out
    
    var columns: [GridItem] = Array.init(repeating: GridItem(spacing: 6), count: 4)
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: columns,
                alignment: .center,
                spacing: 6,
                pinnedViews: [.sectionFooters]
            ) {
                ForEach(song.bars.indices) { i in
                    NavigationLink(destination: BarView(song: self.$song, bar: $song.bars[i], index: i+1, player: player)) {
                        BarThumbnailView(chord: binding(song.bars[i].chordId), pattern: $song.bars[i].pattern)
                    }
                }
            }
        }
        .onAppear(){ // this sometimes triggers while entering other views, not sure why
                     // this causes entire song to play when going to eg. a chord
                     // it also sometimes doesn't run when coming back from bar view
                     // I added a workaround so it only happens when entering bar view
                     // you can also normally stop/play to fix it
            playing = player.isPlaying()
            player.prepareSongLoop(song)
            settingsViewData = song.settingsViewData
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                SettingsView(data: $settingsViewData)
                    .navigationBarItems(
                        leading: Button("Dismiss") {
                            showingSettings = false
                        },
                        trailing: Button("Save") {
                            song.update(settingsViewData)
                            player.prepareSongLoop(song)
                            showingSettings = false
                        })
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .inactive { saveAction() }
        }
        .navigationTitle("Polska overview")
        .navigationBarItems(
            leading:
                Button("Help") {
                    showingAlert = true
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("Greetings from iPolsk!"), message: Text("This app generates a polska melody based on your configuration. The song contains a series of bars, which in turn each contain a chord, which in turn contains configurable note patterns. The music will (mostly) adapt based on which view you're in. Here in the overview, the music will sequencially process each bar. Press play to start! PS: Don't miss out on the cool settings!!"), dismissButton: .default(Text("Got it!")))
                },
            trailing: HStack {
                Button(action: {
                    settingsViewData = song.settingsViewData // extra update since onAppear is a bit temperamental
                    showingSettings = true
                })
                {
                    Image(systemName: "helm")
                }
                Button(action: {
                    player.prepareSongLoop(song)
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
