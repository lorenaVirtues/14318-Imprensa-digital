import Foundation

struct SongModel: Identifiable, Codable {
    var id = UUID()
    var title: String
    var artist: String
    var date: String
    var imageUrl: String?
}

struct PlaylistModel: Identifiable, Codable {
    var id = UUID()
    var name: String
    var date: String
    var imageUrl: String?
    var songs: [SongModel]
}
