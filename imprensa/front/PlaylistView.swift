import SwiftUI
// import PhotosUI // Removed to avoid iOS 16+ dependencies if not needed elsewhere

struct PlaylistView: View {
    @EnvironmentObject private var router: NavigationRouter
    @EnvironmentObject private var playlistManager: PlaylistManager
    @EnvironmentObject private var dataController: AppDataController
    @EnvironmentObject private var ytPlayer: YouTubeBackgroundPlayer
    
    @State private var showingCreateModal = false
    @State private var selectedPlaylist: PlaylistModel? = nil
    @State private var isEditing = false
    @State private var showingSearchSheet = false
    
    var body: some View {
        ZStack {
            Color("azulEscuro")
                .edgesIgnoringSafeArea(.bottom)
            Color.white
                .edgesIgnoringSafeArea(.top)
            Color.white
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Nova Playlist Button
                HStack {
                    Button(action: {
                        showingSearchSheet = true
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.gray)
                            Text("BUSCAR")
                                .font(.custom("Spartan-Bold", size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.leading, 20)
                    .padding(.top, 10)
                    
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
                        if playlistManager.playlists.isEmpty {
                            VStack(spacing: 15) {
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray.opacity(0.5))
                                
                                Text("VOCÊ AINDA NÃO POSSUI PLAYLISTS")
                                    .font(.custom("Spartan-Bold", size: 14))
                                    .foregroundColor(.gray.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                
                                Text("Toque em 'NOVA PLAYLIST' para começar.")
                                    .font(.custom("Spartan-Regular", size: 12))
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                            .padding(.top, 100)
                        } else {
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
                
                CreatePlaylistModal(
                    isEditing: isEditing,
                    playlistName: isEditing ? (selectedPlaylist?.name ?? "") : "",
                    initialImageUrl: isEditing ? selectedPlaylist?.imageUrl : nil
                ) { name, imageUrl in
                    if let id = selectedPlaylist?.id {
                        playlistManager.updatePlaylist(id: id, name: name, imageUrl: imageUrl)
                        if var updated = selectedPlaylist {
                            updated.name = name
                            if let img = imageUrl { updated.imageUrl = img }
                            selectedPlaylist = updated
                        }
                    } else {
                        playlistManager.addPlaylist(name: name, imageUrl: imageUrl)
                    }
                    showingCreateModal = false
                } onCancel: {
                    showingCreateModal = false
                }
                .transition(.scale)
                .zIndex(3)
            }
        }
        .sheet(isPresented: $showingSearchSheet) {
            AddSongSheet(playlistId: nil) // Global search
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.light)
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
                    AlbumArtworkView(
                        artworkURL: playlist.imageUrl ?? playlist.songs.first?.imageUrl,
                        maskImageName: "Polygon 12",
                        fallbackImageName: "Polygon 12"
                    )
                    .frame(width: 100, height: 90)
                    .clipped()
                   
                }
                .frame(width: 100, height: 90)
                .clipped()
                .zIndex(1)
                
                // Title and Controls
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(playlist.name)
                            .font(.custom("Spartan-Bold", size: 16))
                            .foregroundColor(.white)
                        Text(playlist.date)
                            .font(.custom("Spartan-Regular", size: 10))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    Button(action: onTap) {
                        Image("btn_playlist_play")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 30)
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
        .preferredColorScheme(.light)
    }
}

struct PlaylistDetailView: View {
    @EnvironmentObject private var playlistManager: PlaylistManager
    @EnvironmentObject private var ytPlayer: YouTubeBackgroundPlayer
    var playlist: PlaylistModel
    var onBack: () -> Void
    var onDelete: () -> Void
    var onEdit: () -> Void
    
    @State private var showingAddSongSheet = false
    @State private var selectedSongForPicker: SongModel? = nil
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white.ignoresSafeArea()
                
                if geo.size.width > geo.size.height {
                    landscapeView(geo: geo)
                } else {
                    portraitView(geo: geo)
                }
                
                if let song = selectedSongForPicker {
                    PlaylistPickerSheet(song: song) {
                        selectedSongForPicker = nil
                    }
                    .transition(.opacity)
                    .zIndex(20)
                }
            }
        }
        .sheet(isPresented: $showingAddSongSheet) {
            AddSongSheet(playlistId: playlist.id)
        }
        .preferredColorScheme(.light)
    }
    
    @ViewBuilder
    private func portraitView(geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Header with Image
            ZStack(alignment: .bottomLeading) {
                AlbumArtworkView(
                    artworkURL: playlist.imageUrl ?? playlist.songs.first?.imageUrl,
                    maskImageName: "img_playlist_cover",
                    fallbackImageName: "img_playlist_cover"
                )
                .frame(height: 300)
                .clipped()
                .padding(.leading, 60)
                
                // Side Controls (as seen in image vertical bar)
                VStack(spacing: 20) {
                    detailActionButton(icon: "btn_return_playlist") { onBack() }
                    detailActionButton(icon: "btn_edit_playlist") { onEdit() }
                    detailActionButton(icon: "btn_delete_playlist") { onDelete() }
                }
                .padding(.leading, 20)
                .padding(.bottom, 120)
                .offset(y: geo.size.height * 0.05)
                
                // Playlist Title Card
                ZStack {
                    Image("bg_card_playlist_info")
                        .resizable()
                        .scaledToFit()
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(playlist.name)
                                .font(.custom("Spartan-Bold", size: 22))
                                .foregroundColor(.white)
                            HStack(spacing: 5) {
                                Image("ic_triangle_playlist_date")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 8, height: 8)
                                Text(playlist.date)
                                    .font(.custom("Spartan-Regular", size: 12))
                            }
                            .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.leading, 20)
                        
                        Spacer()
                        
                        Button(action: {
                            showingAddSongSheet = true
                        }) {
                            Image("btn_add_song_to_playlist")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .padding(10)
                        }
                        
                        Button(action: {
                            if let firstSong = playlistManager.playlists.first(where: { $0.id == playlist.id })?.songs.first {
                                ytPlayer.play(artist: firstSong.artist, song: firstSong.title)
                            }
                        }) {
                            ZStack {
                                Image("btn_playlist_play")
                                    .resizable()
                                    .scaledToFit()
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
                }
                .frame(height: 100)
                .padding(.leading, 60)
                .padding(.trailing, 20)
                .offset(y: 50)
            }
            .ignoresSafeArea(edges: .top)
            
            // Song List
            ScrollView {
                VStack(spacing: 0) {
                    if let currentPlaylist = playlistManager.playlists.first(where: { $0.id == playlist.id }) {
                        if currentPlaylist.songs.isEmpty {
                            Text("Nenhuma música na playlist")
                                .foregroundColor(.gray)
                                .padding(.top, 100)
                        } else {
                            ForEach(currentPlaylist.songs) { song in
                                SongRow(song: song, onRemove: {
                                    playlistManager.removeSong(from: playlist.id, songId: song.id)
                                }, onAddToPlaylist: {
                                    withAnimation { selectedSongForPicker = song }
                                })
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

    @ViewBuilder
    private func landscapeView(geo: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            // Left Side: Image and Controls
            VStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    AlbumArtworkView(
                        artworkURL: playlist.imageUrl ?? playlist.songs.first?.imageUrl,
                        maskImageName: "img_playlist_cover",
                        fallbackImageName: "img_playlist_cover"
                    )
                    .frame(width: geo.size.width * 0.45)
                    .clipped()
                    
                    // Playlist Title Card Overlay
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(playlist.name)
                                .font(.custom("Spartan-Bold", size: 18))
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
                        
                        Spacer()
                        
                        Image(systemName: "music.note.list")
                            .foregroundColor(.white)
                            .font(.title2)
                        
                        Image(systemName: "play.fill")
                            .resizable()
                            .frame(width: 20, height: 25)
                            .foregroundColor(.white)
                            .padding(.leading, 10)
                    }
                    .padding()
                    .frame(height: 80)
                    .background(Color(red: 26/255, green: 104/255, blue: 130/255).opacity(0.9)) // Lighter blue/teal as in art? No, it's dark blue.
                    .background(Color(red: 26/255, green: 60/255, blue: 104/255))
                    .padding(.horizontal, 10)
                    .offset(y: 20)
                }
                .frame(height: geo.size.height * 0.75)
                
                Spacer()
                
                // Bottom row buttons
                HStack(spacing: 30) {
                    detailActionButton(icon: "btn_return_playlist") { onBack() }
                    detailActionButton(icon: "btn_edit_playlist") { onEdit() }
                    detailActionButton(icon: "btn_delete_playlist") { onDelete() }
                }
                .padding(.bottom, 20)
            }
            .frame(width: geo.size.width * 0.45)
            
            // Right Side: Song List
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 1) {
                        if let currentPlaylist = playlistManager.playlists.first(where: { $0.id == playlist.id }) {
                            ForEach(currentPlaylist.songs) { song in
                                SongRow(song: song, onRemove: {
                                    playlistManager.removeSong(from: playlist.id, songId: song.id)
                                }, onAddToPlaylist: {
                                    withAnimation { selectedSongForPicker = song }
                                })
                                Divider().padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color(red: 245/255, green: 245/255, blue: 245/255))
        }
    }
    
    @ViewBuilder
    private func detailActionButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 35, height: 35)
        }
    }
}

struct SongRow: View {
    @EnvironmentObject private var ytPlayer: YouTubeBackgroundPlayer
    var song: SongModel
    var onRemove: () -> Void
    var onAddToPlaylist: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Blue Bar on the left
            Rectangle()
                .fill(Color(red: 26/255, green: 60/255, blue: 104/255))
                .frame(width: 4)
                .padding(.vertical, 8)
            
            HStack(spacing: 15) {
                // Album Art
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
                    Text(song.artist)
                        .font(.custom("Spartan-Regular", size: 13))
                        .foregroundColor(.black.opacity(0.8))
                    Text(song.date)
                        .font(.custom("Spartan-Regular", size: 10))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: onRemove) {
                        Image(systemName: "minus.square")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    Button(action: onAddToPlaylist) {
                        Image(systemName: "plus.square")
                            .rotationEffect(.degrees(90))
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    Button(action: {
                        let key = YouTubeBackgroundPlayer.normalizedKey(artist: song.artist, song: song.title)
                        if ytPlayer.currentKey == key {
                            if ytPlayer.isPlaying {
                                ytPlayer.pause()
                            } else {
                                ytPlayer.resume()
                            }
                        } else {
                            ytPlayer.play(artist: song.artist, song: song.title)
                        }
                    }) {
                        ZStack {
                            Image(systemName: (ytPlayer.currentKey == YouTubeBackgroundPlayer.normalizedKey(artist: song.artist, song: song.title) && ytPlayer.isPlaying) ? "pause.fill" : "play.fill")
                                .resizable()
                                .frame(width: (ytPlayer.currentKey == YouTubeBackgroundPlayer.normalizedKey(artist: song.artist, song: song.title) && ytPlayer.isPlaying) ? 20 : 18, height: 24)
                                .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                            
                            if ytPlayer.isLoading && ytPlayer.currentKey == YouTubeBackgroundPlayer.normalizedKey(artist: song.artist, song: song.title) {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        }
                    }
                    .padding(.trailing, 10)
                }
            }
        }
        .frame(height: 85)
        .background(Color.white)
        .padding(.horizontal, 15)
        .preferredColorScheme(.light)
    }
}

// MARK: - Create Playlist Modal
struct CreatePlaylistModal: View {
    @EnvironmentObject private var playlistManager: PlaylistManager
    var isEditing: Bool
    @State var playlistName: String
    var initialImageUrl: String? = nil
    var onSave: (String, String?) -> Void
    var onCancel: () -> Void
    
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var currentImageUrl: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 10) {
                Image(systemName: "plus.square.on.square")
                    .font(.system(size: 18, weight: .bold))
                Text(isEditing ? "EDITAR PLAYLIST" : "CRIAR PLAYLIST")
                    .font(.custom("Spartan-Bold", size: 20))
            }
            .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
            .padding(.top, 25)
            
            // Image Placeholder area
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(red: 235/255, green: 235/255, blue: 235/255))
                    .frame(height: 180)
                
                if let img = selectedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipped()
                        .cornerRadius(5)
                } else if let url = currentImageUrl {
                    AlbumArtworkView(artworkURL: url, maskImageName: "img_playlist_cover", fallbackImageName: "img_playlist_cover")
                        .frame(height: 180)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)
                        .foregroundColor(Color.gray)
                        .offset(x: -90, y: -50)
                }
                
                Button(action: {
                    showingImagePicker = true
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .bold))
                        .padding(10)
                        .background(Color(red: 26/255, green: 60/255, blue: 104/255))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(10)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .onAppear {
                currentImageUrl = initialImageUrl
            }
            .padding(.horizontal, 20)
            
            TextField("Nome da Playlist....", text: $playlistName)
                .font(.custom("Spartan-Regular", size: 14))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray.opacity(0.6), lineWidth: 1.5)
                )
                .padding(.horizontal, 20)
            
            HStack(spacing: 15) {
                Button(action: onCancel) {
                    Text("CANCELAR")
                        .font(.custom("Spartan-Bold", size: 14))
                        .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color(red: 26/255, green: 60/255, blue: 104/255), lineWidth: 1.5)
                        )
                }
                
                Button(action: {
                    if !playlistName.isEmpty {
                        var savedPath: String? = currentImageUrl
                        if let img = selectedImage {
                            savedPath = playlistManager.saveImageToDisk(image: img)
                        }
                        onSave(playlistName, savedPath)
                    }
                }) {
                    Text(isEditing ? "SALVAR" : "CRIAR PLAYLIST")
                        .font(.custom("Spartan-Bold", size: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 26/255, green: 60/255, blue: 104/255))
                        .cornerRadius(5)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 25)
        }
        .frame(width: 320)
        .background(Color.white)
        .cornerRadius(1) // Reference looks very sharp, almost no corner radius on border
        .border(Color(red: 26/255, green: 60/255, blue: 104/255), width: 3)
        .shadow(color: .black.opacity(0.3), radius: 20)
        .preferredColorScheme(.light)
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
                
                CreatePlaylistModal(isEditing: false, playlistName: "", onSave: { name, imageUrl in
                    playlistManager.addPlaylist(name: name, imageUrl: imageUrl)
                    showingCreateModal = false
                }, onCancel: {
                    showingCreateModal = false
                })
                .transition(.scale)
                .zIndex(3)
            }
        }.preferredColorScheme(.light)
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
                    AlbumArtworkView(
                        artworkURL: playlist.imageUrl ?? playlist.songs.first?.imageUrl,
                        maskImageName: "Polygon 12",
                        fallbackImageName: "Polygon 12"
                    )
                    .frame(width: 70, height: 50)
                
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
        }.preferredColorScheme(.light)
    }
}

// MARK: - Legacy Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
