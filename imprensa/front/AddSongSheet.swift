import SwiftUI
import Shimmer

struct AddSongSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var searchService = YouTubeSearchService()
    @State private var searchText = ""
    
    var playlistId: UUID? // Optional: if nil, let user pick playlist after selecting song
    @EnvironmentObject private var playlistManager: PlaylistManager
    @State private var selectedSongToPickPlaylist: SongModel? = nil
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                ZStack {
                    HStack {
                        Spacer()
                        Text("BUSCAR MÚSICAS")
                            .font(.custom("Spartan-Bold", size: 18))
                            .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                        Spacer()
                    }
                    
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255).opacity(0.8))
                        }
                        .padding(.trailing)
                    }
                }
                .padding(.vertical, 20)
                .background(Color.white)
                
                Divider()
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                    
                    TextField("Nome da música ou artista...", text: $searchText)
                        .font(.custom("Spartan-Regular", size: 15))
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await searchService.search(query: searchText) }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: { 
                            searchText = ""
                            searchService.results = []
                            searchService.errorMessage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.vertical, 15)
                
                // Results List
                ScrollView {
                    VStack(spacing: 0) {
                        if searchService.isSearching {
                            ForEach(0..<6) { _ in
                                SearchResultSkeleton()
                                    .padding(.horizontal)
                                    .shimmering()
                                Divider().padding(.horizontal)
                            }
                        } else if let error = searchService.errorMessage {
                            VStack(spacing: 15) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text(error)
                                    .font(.custom("Spartan-Regular", size: 14))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 60)
                            .padding(.horizontal)
                        } else if searchService.results.isEmpty && !searchText.isEmpty {
                            VStack(spacing: 15) {
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("Nenhum resultado encontrado para \"\(searchText)\"")
                                    .font(.custom("Spartan-Regular", size: 14))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 60)
                            .padding(.horizontal)
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(searchService.results) { song in
                                    SearchResultRow(song: song) {
                                        if let pId = playlistId {
                                            playlistManager.addSong(to: pId, song: song)
                                            dismiss()
                                        } else {
                                            // Se não tiver playlist fixa, abre o picker
                                            selectedSongToPickPlaylist = song
                                        }
                                    }
                                    Divider().padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            
            // Picker Overlay if needed
            if let song = selectedSongToPickPlaylist {
                PlaylistPickerSheet(song: song) {
                    selectedSongToPickPlaylist = nil
                    dismiss()
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .preferredColorScheme(.light)
    }
}

struct SearchResultRow: View {
    var song: SongModel
    var onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 0) {
                // Blue Tip (Consistent with PlaylistView)
                Rectangle()
                    .fill(Color(red: 26/255, green: 60/255, blue: 104/255))
                    .frame(width: 4)
                    .padding(.vertical, 8)
                
                HStack(spacing: 15) {
                    AlbumArtworkView(
                        artworkURL: song.imageUrl,
                        maskImageName: "img_playlist_cover",
                        fallbackImageName: "img_playlist_cover"
                    )
                    .frame(width: 55, height: 55)
                    .padding(.leading, 12)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.title)
                            .font(.custom("Spartan-Bold", size: 15))
                            .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                            .lineLimit(1)
                        Text(song.artist)
                            .font(.custom("Spartan-Regular", size: 13))
                            .foregroundColor(.black.opacity(0.8))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                        .padding(.trailing, 15)
                }
            }
            .frame(height: 75)
            .background(Color.white)
        }
    }
}

struct SearchResultSkeleton: View {
    var body: some View {
        HStack(spacing: 15) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 55, height: 55)
            
            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 150, height: 12)
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 10)
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }
}
