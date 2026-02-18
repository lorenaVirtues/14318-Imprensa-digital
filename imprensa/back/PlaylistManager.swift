import Foundation
import SwiftUI

class PlaylistManager: ObservableObject {
    @Published var playlists: [PlaylistModel] = [] {
        didSet {
            save()
        }
    }
    
    private let key = "user_playlists"
    
    init() {
        load()
        if playlists.isEmpty {
            createMockData()
        }
    }
    
    func addPlaylist(name: String, imageUrl: String?) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let dateString = formatter.string(from: Date())
        
        let newPlaylist = PlaylistModel(name: name, date: dateString, imageUrl: imageUrl, songs: [])
        playlists.append(newPlaylist)
    }
    
    func deletePlaylist(id: UUID) {
        playlists.removeAll { $0.id == id }
    }
    
    func updatePlaylist(id: UUID, name: String, imageUrl: String? = nil) {
        if let index = playlists.firstIndex(where: { $0.id == id }) {
            playlists[index].name = name
            if let img = imageUrl {
                playlists[index].imageUrl = img
            }
        }
    }
    
    func saveImageToDisk(image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let fileName = "playlist_\(UUID().uuidString).jpg"
        let fileManager = FileManager.default
        
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileURL = documentsURL.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileName
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    func addSong(to playlistId: UUID, song: SongModel) {
        if let index = playlists.firstIndex(where: { $0.id == playlistId }) {
            playlists[index].songs.append(song)
        }
    }
    
    func removeSong(from playlistId: UUID, songId: UUID) {
        if let index = playlists.firstIndex(where: { $0.id == playlistId }) {
            playlists[index].songs.removeAll { $0.id == songId }
        }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([PlaylistModel].self, from: data) {
            playlists = decoded
        }
    }
    
    private func createMockData() {
        playlists = [
            PlaylistModel(name: "Viagem", date: "01/01/2025", imageUrl: nil, songs: [
                SongModel(title: "Música 1", artist: "Artista A", date: "01/01/2025"),
                SongModel(title: "Música 2", artist: "Artista B", date: "02/01/2025")
            ]),
            PlaylistModel(name: "Treino", date: "15/01/2025", imageUrl: nil, songs: [])
        ]
    }
}
