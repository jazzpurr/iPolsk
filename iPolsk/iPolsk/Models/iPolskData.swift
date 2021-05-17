//
//  iPolskData.swift
//  iPolsk
//
//  Created by Jesper Norberg on 2021-05-14.
//

import Foundation

class iPolskData: ObservableObject {
    private static var documentsFolder: URL {
        do {
            return try FileManager.default.url(for: .documentDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: false)
        } catch {
            fatalError("Can't find documents directory.")
        }
    }
    private static var fileURL: URL {
        return documentsFolder.appendingPathComponent("songs.data")
    }
    @Published var songs: [Song] = [Song("Default")] // the beginnings of file handling
    
    func load() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let data = try? Data(contentsOf: Self.fileURL) else {
                return // no saved data
            }
            guard let songs = try? JSONDecoder().decode([Song].self, from: data) else {
                fatalError("Can't decode saved data.")
            }
            DispatchQueue.main.async {
                self?.songs = songs
            }
        }
    }
    
    func save() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let songs = self?.songs else { fatalError("Self out of scope") }
            guard let data = try? JSONEncoder().encode(songs) else { fatalError("Error encoding data") }
            do {
                let outfile = Self.fileURL
                try data.write(to: outfile)
            } catch {
                fatalError("Can't write to file")
            }
        }
    }
}
