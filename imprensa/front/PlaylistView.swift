import SwiftUI

struct PlaylistView: View {
    @EnvironmentObject private var router: NavigationRouter
    @EnvironmentObject private var playlistManager: PlaylistManager
    @EnvironmentObject private var dataController: AppDataController
    @EnvironmentObject private var ytPlayer: YouTubeBackgroundPlayer
    
    @State private var showingCreateModal = false
    @State private var selectedPlaylist: PlaylistModel? = nil
    @State private var isEditing = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Nova Playlist Button
                HStack {
                    Spacer()
                    Button(action: {
                        isEditing = false
                        showingCreateModal = true
                    }) {
                        HStack(spacing: 5) {
                            Text("NOVA PLAYLIST")
                                .font(.custom("Spartan-Bold", size: 14))
                                .foregroundColor(.gray)
                            
                            Image(systemName: "plus.square.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 10)
                }
                
                // Playlist List
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(playlistManager.playlists) { playlist in
                            PlaylistRow(playlist: playlist) {
                                selectedPlaylist = playlist
                            } onDelete: {
                                playlistManager.deletePlaylist(id: playlist.id)
                            } onEdit: {
                                selectedPlaylist = playlist
                                isEditing = true
                                showingCreateModal = true
                            }
                        }
                    }
                    .padding(.top, 20)
                }
            }
            
            // Bottom Left Back Button (as seen in image)
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        router.backTopLevel()
                    }) {
                        Image("btn_return")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100)
                    }
                    Spacer()
                }
            }
            
            // Floating "Detail View" if a playlist is selected
            if let playlist = selectedPlaylist, !showingCreateModal {
                 PlaylistDetailView(playlist: playlist) {
                     selectedPlaylist = nil
                 } onDelete: {
                     playlistManager.deletePlaylist(id: playlist.id)
                     selectedPlaylist = nil
                 } onEdit: {
                     isEditing = true
                     showingCreateModal = true
                 }
                 .transition(.move(edge: .trailing))
                 .zIndex(2)
            }
            
            // Create/Edit Modal
            if showingCreateModal {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { showingCreateModal = false }
                
                CreatePlaylistModal(isEditing: isEditing, playlistName: isEditing ? (selectedPlaylist?.name ?? "") : "") { name in
                    if isEditing, let id = selectedPlaylist?.id {
                        playlistManager.updatePlaylist(id: id, name: name)
                        // Update the local selected playlist to reflect change
                        if var updated = selectedPlaylist {
                            updated.name = name
                            selectedPlaylist = updated
                        }
                    } else {
                        playlistManager.addPlaylist(name: name, imageUrl: nil)
                    }
                    showingCreateModal = false
                } onCancel: {
                    showingCreateModal = false
                }
                .transition(.scale)
                .zIndex(3)
            }
        }
        .navigationBarHidden(true)
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Image("bg_header_title_your_playlists")
                     .resizable()
                     .scaledToFit()
                     .frame(width: 160)
                     .padding(.leading)
                
                Spacer()
                
                HeaderDateTimeView()
                    .padding(.trailing, 20)
            }
            .padding(.top, 40)
            .padding(.bottom, 10)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 20)
        }
    }
}

// MARK: - Playlist Row Component
struct PlaylistRow: View {
    var playlist: PlaylistModel
    var onTap: () -> Void
    var onDelete: () -> Void
    var onEdit: () -> Void
    
    @State private var offset: CGFloat = 0
    private let actionWidth: CGFloat = 120
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Action Buttons (Reveal on swipe)
            HStack(spacing: 0) {
                Button(action: onEdit) {
                    ZStack {
                        Rectangle().fill(Color.gray)
                        Image(systemName: "pencil")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
                .frame(width: 60)
                
                Button(action: onDelete) {
                    ZStack {
                        Rectangle().fill(Color.red)
                        Image(systemName: "trash.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
                .frame(width: 60)
            }
            .frame(height: 90)
            
            // Main Card
            HStack(spacing: 0) {
                // Blue Tip on the far left
                Rectangle()
                    .fill(Color(red: 26/255, green: 60/255, blue: 104/255))
                    .frame(width: 5)
                
                // Slanted Image Part
                ZStack {
                    Image("img_song_cover") // Placeholder or playlist image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 90)
                        .clipped()
                    
                    // Slant Overlay to transition to the blue title part
                    SlantShape()
                        .fill(Color(red: 26/255, green: 60/255, blue: 104/255))
                        .frame(width: 40)
                        .offset(x: 40)
                }
                .frame(width: 100, height: 90)
                .clipped()
                .zIndex(1)
                
                // Title and Controls
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(playlist.name)
                            .font(.custom("Spartan-Bold", size: 18))
                            .foregroundColor(.white)
                        Text(playlist.date)
                            .font(.custom("Spartan-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.leading, 15)
                    
                    Spacer()
                    
                    Button(action: onTap) {
                        Image(systemName: "play.fill")
                            .resizable()
                            .frame(width: 25, height: 30)
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 10)
                    
                    Button(action: {
                        withAnimation {
                            offset = offset == 0 ? -actionWidth : 0
                        }
                    }) {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    .padding(.trailing, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: 90)
                .background(Color(red: 26/255, green: 60/255, blue: 104/255))
                .padding(.leading, -20)
            }
            .offset(x: offset)
            .onTapGesture {
                if offset != 0 {
                    withAnimation { offset = 0 }
                } else {
                    onTap()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        withAnimation {
                            if value.translation.width < -60 {
                                offset = -actionWidth
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
        }
        .frame(height: 90)
        .padding(.horizontal, 20)
    }
}

struct SlantShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Detail View Component
struct PlaylistDetailView: View {
    @EnvironmentObject private var playlistManager: PlaylistManager
    @EnvironmentObject private var ytPlayer: YouTubeBackgroundPlayer
    var playlist: PlaylistModel
    var onBack: () -> Void
    var onDelete: () -> Void
    var onEdit: () -> Void
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with Image
                ZStack(alignment: .bottomLeading) {
                    Image("img_song_cover") // Main playlist image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 300)
                        .clipped()
                    
                    // Side Controls (as seen in image vertical bar)
                    VStack(spacing: 20) {
                        detailActionButton(icon: "arrow.counterclockwise") { onBack() }
                        detailActionButton(icon: "pencil") { onEdit() }
                        detailActionButton(icon: "trash") { onDelete() }
                    }
                    .padding(.leading, 20)
                    .padding(.bottom, 120)
                    
                    // Playlist Title Card
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(playlist.name)
                                .font(.custom("Spartan-Bold", size: 22))
                                .foregroundColor(.white)
                            HStack(spacing: 5) {
                                Image(systemName: "play.fill")
                                    .resizable()
                                    .frame(width: 8, height: 8)
                                Text(playlist.date)
                                    .font(.custom("Spartan-Regular", size: 12))
                            }
                            .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.leading, 20)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "shuffle")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.white)
                                .padding(10)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white.opacity(0.5), lineWidth: 1))
                        }
                        
                        Button(action: {
                            if let firstSong = playlistManager.playlists.first(where: { $0.id == playlist.id })?.songs.first {
                                ytPlayer.play(artist: firstSong.artist, song: firstSong.title)
                            }
                        }) {
                            ZStack {
                                Image(systemName: "play.fill")
                                    .resizable()
                                    .frame(width: 30, height: 35)
                                    .foregroundColor(.white)
                                
                                if ytPlayer.isLoading {
                                    LoadingView()
                                        .scaleEffect(1.5)
                                }
                            }
                        }
                        .padding(.trailing, 20)
                    }
                    .frame(height: 100)
                    .background(Color(red: 26/255, green: 60/255, blue: 104/255))
                    .padding(.leading, 60)
                    .padding(.trailing, 20)
                    .offset(y: 50)
                }
                .ignoresSafeArea(edges: .top)
                
                // Song List
                ScrollView {
                    VStack(spacing: 0) {
                        // Get the latest songs from the manager to ensure they exist/refresh
                        if let currentPlaylist = playlistManager.playlists.first(where: { $0.id == playlist.id }) {
                            if currentPlaylist.songs.isEmpty {
                                Text("Nenhuma música na playlist")
                                    .foregroundColor(.gray)
                                    .padding(.top, 100)
                            } else {
                                ForEach(currentPlaylist.songs) { song in
                                    SongRow(song: song) {
                                        playlistManager.removeSong(from: playlist.id, songId: song.id)
                                    }
                                    Divider().padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                    .padding(.top, 60)
                }
                .background(Color(red: 240/255, green: 240/255, blue: 240/255))
                .padding(.top, 50)
            }
        }
    }
    
    @ViewBuilder
    private func detailActionButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(red: 26/255, green: 60/255, blue: 104/255))
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(width: 35, height: 35)
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white.opacity(0.3), lineWidth: 1))
        }
    }
}

struct SongRow: View {
    @EnvironmentObject private var ytPlayer: YouTubeBackgroundPlayer
    var song: SongModel
    var onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Blue Bar on the left
            Rectangle()
                .fill(Color(red: 26/255, green: 60/255, blue: 104/255))
                .frame(width: 4)
                .padding(.vertical, 10)
            
            HStack(spacing: 15) {
                // Vinyl Icon or Album Art
                ZStack {
                    Circle().fill(Color.gray.opacity(0.1))
                    Image(systemName: "record.circle")
                        .resizable()
                        .frame(width: 45, height: 45)
                        .foregroundColor(.gray)
                }
                .frame(width: 60, height: 60)
                .padding(.leading, 15)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.custom("Spartan-Bold", size: 16))
                        .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                    Text(song.artist)
                        .font(.custom("Spartan-Regular", size: 14))
                        .foregroundColor(.gray)
                    Text(song.date)
                        .font(.custom("Spartan-Regular", size: 10))
                        .foregroundColor(.gray.opacity(0.6))
                }
                
                Spacer()
                
                HStack(spacing: 10) {
                    Button(action: onRemove) {
                        Image(systemName: "minus.square")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    Button(action: {}) {
                        Image(systemName: "plus.square")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    Button(action: {
                        ytPlayer.play(artist: song.artist, song: song.title)
                    }) {
                        ZStack {
                            Image(systemName: "play.fill")
                                .resizable()
                                .frame(width: 20, height: 25)
                                .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                            
                            if ytPlayer.isLoading && ytPlayer.currentKey == YouTubeBackgroundPlayer.normalizedKey(artist: song.artist, song: song.title) {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                }
                .padding(.trailing, 10)
            }
        }
        .frame(height: 90)
        .background(Color.white)
        .padding(.horizontal, 20)
    }
}

// MARK: - Create Playlist Modal
struct CreatePlaylistModal: View {
    var isEditing: Bool
    @State var playlistName: String
    var onSave: (String) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "music.note.list")
                Text(isEditing ? "EDITAR PLAYLIST" : "CRIAR PLAYLIST")
                    .font(.custom("Spartan-Bold", size: 20))
            }
            .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
            .padding(.top, 20)
            
            // Image Placeholder
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 150)
                
                Image(systemName: "photo.on.rectangle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80)
                    .foregroundColor(.gray.opacity(0.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Button(action: {}) {
                    Image(systemName: "pencil")
                        .padding(8)
                        .background(Color(red: 26/255, green: 60/255, blue: 104/255))
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
                .padding(10)
            }
            .padding(.horizontal, 20)
            
            TextField("Nome da Playlist....", text: $playlistName)
                .padding()
                .background(RoundedRectangle(cornerRadius: 5).stroke(Color.gray.opacity(0.5)))
                .padding(.horizontal, 20)
            
            HStack(spacing: 15) {
                Button(action: onCancel) {
                    Text("CANCELAR")
                        .font(.custom("Spartan-Bold", size: 14))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray.opacity(0.5)))
                }
                
                Button(action: {
                    if !playlistName.isEmpty {
                        onSave(playlistName)
                    }
                }) {
                    Text(isEditing ? "SALVAR" : "CRIAR PLAYLIST")
                        .font(.custom("Spartan-Bold", size: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 26/255, green: 60/255, blue: 104/255))
                        .cornerRadius(5)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 320)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 20)
    }
}

// MARK: - Playlist Picker Sheet
struct PlaylistPickerSheet: View {
    @EnvironmentObject private var playlistManager: PlaylistManager
    var song: SongModel
    var onDismiss: () -> Void
    
    @State private var showingCreateModal = false
    
    var body: some View {
        ZStack {
            // Background dim
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "plus.square.on.square")
                        .font(.title3)
                    Text("ADICIONAR MÚSICA A...")
                        .font(.custom("Spartan-Bold", size: 18))
                }
                .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                .padding(.top, 25)
                .padding(.bottom, 20)
                
                // Playlist List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(playlistManager.playlists) { playlist in
                            PlaylistPickerRow(playlist: playlist) {
                                let alreadyHas = playlist.songs.contains(where: { $0.title == song.title && $0.artist == song.artist })
                                if !alreadyHas {
                                    playlistManager.addSong(to: playlist.id, song: song)
                                }
                                onDismiss()
                            }
                        }
                        
                        if playlistManager.playlists.isEmpty {
                            Text("Nenhuma playlist encontrada")
                                .font(.custom("Spartan-Regular", size: 14))
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: 300)
                
                // Footer Buttons
                HStack(spacing: 15) {
                    Button(action: onDismiss) {
                        Text("CANCELAR")
                            .font(.custom("Spartan-Bold", size: 14))
                            .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(red: 26/255, green: 60/255, blue: 104/255), lineWidth: 1))
                    }
                    
                    Button(action: {
                        withAnimation { showingCreateModal = true }
                    }) {
                        Text("NOVA PLAYLIST")
                            .font(.custom("Spartan-Bold", size: 14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(red: 26/255, green: 60/255, blue: 104/255))
                            .cornerRadius(5)
                    }
                }
                .padding(20)
            }
            .frame(width: 340)
            .background(Color.white)
            .cornerRadius(5)
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(red: 26/255, green: 60/255, blue: 104/255), lineWidth: 2))
            .shadow(color: .black.opacity(0.3), radius: 20)
            
            // Internal Create Modal
            if showingCreateModal {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .zIndex(2)
                
                CreatePlaylistModal(isEditing: false, playlistName: "", onSave: { name in
                    playlistManager.addPlaylist(name: name, imageUrl: nil)
                    showingCreateModal = false
                }, onCancel: {
                    showingCreateModal = false
                })
                .transition(.scale)
                .zIndex(3)
            }
        }
    }
}

struct PlaylistPickerRow: View {
    var playlist: PlaylistModel
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Image section with slant
                ZStack(alignment: .trailing) {
                    if let firstSong = playlist.songs.first, let imgUrl = firstSong.imageUrl, let url = URL(string: imgUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 70, height: 50)
                    } else {
                        Image("img_playlist_placeholder") // Use a placeholder if you have one
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 50)
                            .background(Color.gray.opacity(0.3))
                    }
                    
                    SlantShape()
                        .fill(Color(red: 26/255, green: 60/255, blue: 104/255))
                        .frame(width: 25)
                        .offset(x: 12)
                }
                .frame(width: 60, height: 50)
                .clipped()
                
                // Content section
                VStack(alignment: .leading, spacing: 2) {
                    Text(playlist.name)
                        .font(.custom("Spartan-Bold", size: 14))
                        .foregroundColor(.white)
                    Text(playlist.date)
                        .font(.custom("Spartan-Regular", size: 10))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.leading, 20)
                
                Spacer()
                
                Image(systemName: "plus.square")
                    .foregroundColor(.white)
                    .font(.title3)
                    .padding(.trailing, 10)
            }
            .frame(height: 50)
            .background(Color(red: 26/255, green: 60/255, blue: 104/255))
            .cornerRadius(5)
        }
    }
}
