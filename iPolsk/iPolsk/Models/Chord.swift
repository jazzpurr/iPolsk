//
//  Chord.swift
//  iPolsk
//
//  Created by Jesper Norberg on 2021-05-14.
//

import Foundation
import SwiftUI

struct Chord: Identifiable, Codable, Equatable {
    static func == (lhs: Chord, rhs: Chord) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: UUID
    var name: String
    var scaleIndex: Int
    var patterns : [Pattern]
    var color: Color
    
    init(){
        self.init("", 7)
    }
    
    init(_ name: String){
        self.init(name, 7)
    }
    
    init(_ name: String, _ scaleIndex: Int){
        self.id = UUID()
        self.name = name
        self.scaleIndex = scaleIndex
        self.patterns = []
        self.color = Color(red: 0.1, green: 0.1, blue: 0.1)
    }
    
    mutating func addPattern(_ pattern: Pattern){
        patterns.append(pattern)
    }
}

extension Chord {
    struct ViewData: Equatable {
        var name: String = ""
        var scaleIndex: Int = 0
        var patterns : [Pattern] = [Pattern()]
        var color: Color = .black
    }
    
    var viewData: ViewData {
        return ViewData(name: name, scaleIndex: scaleIndex, patterns: patterns, color: color)
    }
    
    mutating func update(_ data: ViewData) {
        name = data.name
        scaleIndex = data.scaleIndex
        patterns = data.patterns
        color = data.color
    }
}
