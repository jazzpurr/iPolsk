//
//  Pattern.swift
//  iPolsk
//
//  Created by Jesper Norberg on 2021-05-14.
//

import Foundation
import SwiftUI

struct Pattern: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String = ""
    var scaleOffsets: [[Int]]
    
    init(){
        self.init([[0], [], [], [], [], [], [0], [], []]) // base polka form
    }
    
    init(_ scaleOffsets: [[Int]]){
        self.id = UUID()
        self.scaleOffsets = scaleOffsets
        createUnicodeName()
    }
    
    mutating func update(_ matrix: [[Bool]]){
        for col in 0..<matrix[0].count {
            scaleOffsets[col].removeAll()
            for row in 0..<matrix.count {
                if matrix[row][col] == true {
                    scaleOffsets[col].append(7 - row)
                }
            }
        }
        createUnicodeName()
    }
    
    mutating func createUnicodeName() {
        var name = ""
        for i in 0..<scaleOffsets.count {
            if scaleOffsets[i].count == 0 {
                name +=  "𑁦 "
            }
            else if scaleOffsets[i].count >= 2 {
                name += "? "
            }
            else {
                switch scaleOffsets[i][0] {
                case 0:
                    name += "𝟢 "
                case 1:
                    name += "𝟣 "
                case 2:
                    name += "𝟤 "
                case 3:
                    name += "𝟥 "
                case 4:
                    name += "𝟦 "
                case 5:
                    name += "𝟧 "
                case 6:
                    name += "𝟨 "
                case 7:
                    name += "𝟩 "
                case -1:
                    name += "𝟙 "
                case -2:
                    name += "𝟚 "
                case -3:
                    name += "𝟛 "
                case -4:
                    name += "𝟜 "
                case -5:
                    name += "𝟝 "
                case -6:
                    name += "𝟞 "
                case -7:
                    name += "𝟟 "
                default:
                    fatalError("Offset outside range")
                }
            }
        }
        self.name = name
    }
}
