//
//  Bar.swift
//  iPolsk
//
//  Created by Jesper Norberg on 2021-05-14.
//

import Foundation
import SwiftUI

struct Bar: Identifiable, Codable {
    let id: UUID
    var chordId : UUID
    var pattern : Pattern?
    
    init(_ chord: Chord){
        self.id = UUID()
        self.chordId = chord.id
        self.pattern = nil
    }
}

extension Bar {
    struct ViewData {
        var chordId : UUID = UUID()
        var patterns : [Pattern] = [] // array despite just one element so we can use ForEach removal
    }
    
    var viewData: ViewData {
        return ViewData(chordId: chordId, patterns: pattern != nil ? [pattern!] : [])
    }
    
    mutating func update(_ data: ViewData) {
        chordId = data.chordId
        pattern = data.patterns.count != 0 ? data.patterns[0] : nil
    }
}
