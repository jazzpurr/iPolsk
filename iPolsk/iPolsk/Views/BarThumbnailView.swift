//
//  BarThumbnailView.swift
//  iPolsk
//
//  Created by Jesper Norberg on 2021-05-14.
//

import SwiftUI

struct BarThumbnailView: View {
    @Binding var chord: Chord
    @Binding var pattern: Pattern?
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(pattern == nil ? chord.color : Color.white)
            .frame(height: 50)
            .overlay(
                VStack {
                    Text(pattern == nil ? chord.name : "Fixed")
                        .font(.headline)
                        .lineLimit(1)
                    Text("Start: \(chord.scaleIndex - 7)")
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundColor(pattern == nil ? Color.white : Color.black)
            )
            .shadow(radius: 8)
    }
}
