//
//  iPolskApp.swift
//  iPolsk
//
//  Created by Jesper Norberg on 2021-05-14.
//

import SwiftUI

@main
struct iPolskApp: App {
    init() {
        // this looked pretty bad with lazy grid views imo
        UIScrollView.appearance().bounces = false
    }
    
    @ObservedObject private var data = iPolskData()
    var player = PolskaPlayer()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                SongView(song: $data.songs[0], player: player) {
                    data.save()
                }
            }
            .onAppear {
                data.load()
            }
        }
    }
}
