import SwiftUI
import Lottie
import AVFoundation

struct PrincipalView: View {
    @EnvironmentObject var dataController: AppDataController
    @EnvironmentObject var radioPlayer: RadioPlayer
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var locManager: LocationManager
    @EnvironmentObject var weatherSvc: WeatherService
    @EnvironmentObject private var linkHandler: LinkHandler
    @EnvironmentObject var launchTracker: LaunchTracker
    
    @StateObject private var banner = Banner(radio: "11069")
    
    @State private var showingPlaylistPicker = false
    @State private var socialPlatformToShow: Platform? = nil
    @State private var showSocialFeed = false
    @State var radio: RadioModel
    @State private var showCompartilhar = false
    @State private var showWhatsapp = false
    @State private var showFacebook = false
    @State private var showInstagram = false
    @State private var showTiktok = false
    @State private var showYoutube = false
    @State private var showTiktokAlert = false
    
    let height = UIScreen.main.bounds.size.height
    let width = UIScreen.main.bounds.size.width
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                let isPortrait = geo.size.height > geo.size.width
                if isPortrait {
                    portrait(geo: geo)
                } else {
                    landscape(geo: geo)
                }
                
                Group {
                    ZStack{}.fullScreenCover(isPresented: $showCompartilhar) {
                        if let urlString = dataController.appData?.app.share,
                           let shareURL = URL(string: urlString) {
                            ActivityView(activityItems: [shareURL] as [Any],
                                         applicationActivities: nil)
                        } else {
                            Text("Nada para compartilhar no momento")
                                .font(.headline)
                                .padding()
                        }
                    }
                    .fullScreenCover(item: $socialPlatformToShow) { platform in
                        NavigationView {
                            SocialFeedView(apiURL: "https://redessociais.ticketss.app/imprensa.json",
                                          initialPlatform: platform)
                                .environmentObject(linkHandler)
                        }
                    }
                    .fullScreenCover(isPresented: $showSocialFeed) {
                        NavigationView {
                            SocialFeedView(apiURL: "https://redessociais.ticketss.app/imprensa.json")
                                .environmentObject(linkHandler)
                        }
                    }
                }
                
                if showingPlaylistPicker {
                    let currentSong = SongModel(
                        title: radioPlayer.itemMusic,
                        artist: radioPlayer.itemArtist,
                        date: {
                            let f = DateFormatter()
                            f.dateFormat = "dd/MM/yyyy"
                            return f.string(from: Date())
                        }(),
                        imageUrl: radioPlayer.currentArtworkUrl
                    )
                    PlaylistPickerSheet(song: currentSong) {
                        withAnimation { showingPlaylistPicker = false }
                    }
                    .transition(.opacity)
                    .zIndex(20)
                }
            }
        }
        .onAppear {
            dataController.parseAppData()
            fetchWeatherIfPossible()
        }
        .alert(isPresented: $showTiktokAlert) {
            Alert(
                title: Text("Aviso"),
                message: Text("No momento ainda não conteúdos disponíveis nessa plataforma"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onReceive(dataController.$appData) { appData in
            if let streaming = appData?.app.radios.first?.streaming {
                let model = RadioModel(streamUrl: streaming)
                self.radio = model
                
                if let url = URL(string: streaming) {
                    let isFirstTime = !launchTracker.didStartRadio
                    let currentURL = (radioPlayer.player?.currentItem?.asset as? AVURLAsset)?.url
                    let isDifferentURL = currentURL != url
                    
                    if isFirstTime || isDifferentURL {
                        if isFirstTime { launchTracker.didStartRadio = true }
                        
                        // Inicializa o player
                        radioPlayer.initPlayer(url: url)
                        
                        if isFirstTime {
                            if UserDefaults.autoplayEnabled {
                                radioPlayer.play(model)
                            }
                        } else if isDifferentURL {
                            radioPlayer.play(model)
                        }
                    }
                }
            }
        }
        .onChange(of: dataController.appData) { newData in
            if let firstRadio = newData?.app.radios.first {
                banner.updateRadio(firstRadio.id)
            }
        }
    }
    
    @ViewBuilder
    private func portrait(geo: GeometryProxy) -> some View {
        Color("azul")
            .edgesIgnoringSafeArea(.bottom)
        
        Color(.white)
            .edgesIgnoringSafeArea(.top)
        
        ZStack{
            Color.white
            
            ScrollView (showsIndicators: false){
                LazyVStack{
                    HStack(alignment: .bottom){
                        if dataController.minimalMode {
                            Image("logo")
                                  .resizable()
                                  .scaledToFit()
                                  .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? geo.size.width * 0.55 : geo.size.width * 0.4, height: geo.size.height * 0.12)
                                  .border(Color.yellow)
                        } else {
                            LottieView(animationName: "logotipo")
                                .scaledToFit()
                                .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? geo.size.width * 0.55 : geo.size.width * 0.4, height: geo.size.height * 0.12)
                                .scaleEffect(2.0)
                        }
                       
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 5){
                            HeaderDateTimeView()
                            
                            Button(action: {
                                showCompartilhar = true
                            }, label:{
                                Image("btn_share")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width * 0.08, height: geo.size.height * 0.05)
                            })
                        }
                    }
                    .padding(10)
                   
                    Divider()
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                    
                    HStack{
                        Image("btn_nav_home_active")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.3, height: geo.size.height * 0.05)
                        
                        Spacer()
                        
                        Button(action:{
                            router.go(to: .audio)
                        }, label:{
                            Image("btn_nav_audio_player_default")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width * 0.1, height: geo.size.height * 0.05)
                        })
                        
                        Spacer()
                        
                        Button(action:{
                            router.go(to: .config)
                        }, label:{
                            Image("btn_nav_settings_default")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width * 0.1, height: geo.size.height * 0.05)
                        })
                        
                        Spacer()
                        
                        Button(action:{
                            router.go(to: .menu)
                        }, label:{
                            Image("btn_nav_menu_default")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width * 0.1, height: geo.size.height * 0.05)
                        })
                        
                        Spacer()
                        
                        Image("bg_triangle_nav_buttons")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.07, height: geo.size.height * 0.05)
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    // espaço dos banners que ficam dentro de uamscroll horizontal
                    BannerCarouselView(geo: geo) { bannerName in
                        handleBannerTap(bannerName)
                    }
                    .padding(.top, 5)
                    
                    bannerView(webView: banner.webView)
                        .frame(width: geo.size.width * 0.8, height: UIDevice.current.userInterfaceIdiom == .phone ? geo.size.height * 0.1 : geo.size.height * 0.08)
                        .padding(UIDevice.current.userInterfaceIdiom == .phone ? 5 : 10)
                    
                    Divider()
                        .foregroundColor(.gray)
                        .padding(.vertical)
                        .padding(.horizontal, 20)
                    
                    ZStack {
                        HStack {
                            VStack (alignment: .leading){
                                VStack(alignment: .leading){
                                    Image("bg_title_playing_now")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? geo.size.width * 0.4 : geo.size.width * 0.3, height: geo.size.height * 0.03)
                                        .padding(10)
                                    
                                    VStack (alignment: .leading, spacing: 5){
                                        Text(radioPlayer.itemMusic)
                                            .font(.custom("Spartan-Bold", size: 16))
                                            .foregroundColor(Color.black)
                                        
                                        Text(radioPlayer.itemArtist)
                                            .font(.custom("Spartan-Regular", size: 16))
                                            .foregroundColor(Color.black)
                                    }
                                    .padding(10)
                                    
                                    HStack(spacing: 30){
                                        
                                        Button(action:{
                                            withAnimation { showingPlaylistPicker = true }
                                        }, label:{
                                            Image("btn_add_playlist_active_principal")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: geo.size.width * 0.08, height: geo.size.height * 0.05)
                                        })
                                        
                                        Button(action:{
                                            
                                        }, label:{
                                            Image("btn_mute")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: geo.size.width * 0.08, height: geo.size.height * 0.05)
                                        })
                                    }
                                    .padding(10)
                                    
                                    Button(action:{
                                        if radioPlayer.isPlaying {
                                            radioPlayer.stop()
                                        } else {
                                            radioPlayer.play(self.radio)
                                        }
                                    }, label:{
                                        if radioPlayer.isPlaying {
                                            ZStack {
                                                LottieView(animationName: "pause_principal")
                                                    .scaledToFit()
                                                    .frame(width: geo.size.width * 0.3, height: geo.size.height * 0.07)
                                                    .scaleEffect(2.3)
                                                
                                                if radioPlayer.isLoading {
                                                    LoadingView()
                                                        .scaleEffect(1.5)
                                                }
                                            }
                                            .padding(10)
                                        } else {
                                            ZStack {
                                                LottieView(animationName: "play_principal")
                                                    .scaledToFit()
                                                    .frame(width: geo.size.width * 0.3, height: geo.size.height * 0.07)
                                                    .scaleEffect(2.3)
                                                
                                                if radioPlayer.isLoading {
                                                    LoadingView()
                                                        .scaleEffect(1.5)
                                                }
                                            }
                                            .padding(10)
                                        }
                                        
                                    })
                                }.padding(10)
                                
                                Button(action: {
                                    showSocialFeed = true
                                }, label:{
                                    Image("btn_expand_social_media")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? geo.size.width * 0.25 : geo.size.width * 0.15, height: geo.size.height * 0.1)
                                })
                            }
                            
                            Spacer()
                            
                        }
                        HStack{
                            Spacer()
                            VStack {
                                Spacer()
                                
                                ZStack{
                                    Image("bg_main_song_cover_shadow")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: geo.size.width * 0.55, height: geo.size.height * 0.32)
                                        .scaleEffect(1.1)
                                    
                                    ZStack {
                                        AlbumArtworkView(
                                            artwork: radioPlayer.albumArtwork,
                                            maskImageName: UIDevice.current.userInterfaceIdiom == .phone ? "img_main_song_cover" : "capa_do_album"
                                        )
                                        .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? geo.size.width * 0.55 : geo.size.width * 0.45, height: geo.size.height * 0.35)
                                        .scaleEffect(1.1)
                                        .offset(y: geo.size.height * -0.02)
                                        
                                        
                                        if dataController.minimalMode {
                                           
                                        } else {
                                            LottieView(animationName: "traco_capa_de_album_principal")
                                                .scaledToFill()
                                                .frame(width: geo.size.width * 0.55, height: geo.size.height * 0.35)
                                                .scaleEffect(1.3)
                                                .offset(x: geo.size.width * 0.17, y: geo.size.height * 0.01)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func landscape(geo: GeometryProxy) -> some View {
        ZStack{
            Color.white
                .ignoresSafeArea(.all)
            
            ScrollView(showsIndicators: false) {
                LazyVStack {
                    HStack(alignment: .bottom){
                        if dataController.minimalMode {
                            Image("logo")
                                  .resizable()
                                  .scaledToFit()
                                  .frame(width: geo.size.width * 0.3, height: geo.size.height * 0.2)
                        } else {
                            LottieView(animationName: "logotipo")
                                .scaledToFit()
                                .frame(width: geo.size.width * 0.3, height: geo.size.height * 0.2)
                                .scaleEffect(2.3)
                        }
                       
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 5){
                            HeaderDateTimeView()
                        }
                    }
                    .padding(.top, 10)
                    
                    Divider()
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                    
                    HStack{
                        Image("btn_nav_home_active")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.15, height: geo.size.height * 0.1)
                            .border(Color.red)
                        
                        Spacer()
                        
                        Button(action:{
                            router.go(to: .audio)
                        }, label:{
                            Image("btn_nav_audio_player_default")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width * 0.07, height: geo.size.height * 0.1)
                                .border(Color.red)
                        })
                        
                        Spacer()
                        
                        Button(action:{
                            router.go(to: .config)
                        }, label:{
                            Image("btn_nav_settings_default")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width * 0.07, height: geo.size.height * 0.1)
                        })
                        
                        Spacer()
                        
                        Button(action:{
                            router.go(to: .menu)
                        }, label:{
                            Image("btn_nav_menu_default")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width * 0.07, height: geo.size.height * 0.1)
                        })
                        
                        Spacer()
                        
                        Button(action: {
                            showCompartilhar = true
                        }, label:{
                            Image("btn_share")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width * 0.07, height: geo.size.height * 0.1)
                        })
                        
                        Spacer()
                        
                        Image("bg_triangle_nav_buttons")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.04, height: geo.size.height * 0.08)
                    }
                    .padding(.horizontal, 20)
                    
                    BannerCarouselView(geo: geo) { bannerName in
                        handleBannerTap(bannerName)
                    }
                    .padding(.vertical, 10)
                    
                    bannerView(webView: banner.webView)
                        .frame(width: geo.size.width * 0.4, height: geo.size.height * 0.08)
                        .padding(5)
                    
                    Divider()
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                    
                    // Now Playing Section for Landscape
                    HStack(alignment: .center, spacing: 20) {
                        VStack(alignment: .leading) {
                            Image("bg_title_playing_now")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width * 0.25, height: geo.size.height * 0.05)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(radioPlayer.itemMusic)
                                    .font(.custom("Spartan-Bold", size: 18))
                                    .foregroundColor(.black)
                                
                                Text(radioPlayer.itemArtist)
                                    .font(.custom("Spartan-Regular", size: 16))
                                    .foregroundColor(.black)
                            }
                            .padding(.vertical, 5)
                            
                            HStack(spacing: 20) {
                                Button(action: { withAnimation { showingPlaylistPicker = true } }) {
                                    Image("btn_add_playlist_active_principal")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: geo.size.width * 0.06, height: geo.size.height * 0.1)
                                }
                                
                                Button(action: { }) {
                                    Image("btn_mute")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: geo.size.width * 0.06, height: geo.size.height * 0.1)
                                }
                                
                                Button(action: {
                                    if radioPlayer.isPlaying { radioPlayer.stop() }
                                    else { radioPlayer.play(self.radio) }
                                }) {
                                    ZStack {
                                        if radioPlayer.isPlaying {
                                            LottieView(animationName: "pause_principal")
                                                .scaledToFit()
                                                .frame(width: geo.size.width * 0.2, height: geo.size.height * 0.15)
                                                .scaleEffect(1.8)
                                        } else {
                                            LottieView(animationName: "play_principal")
                                                .scaledToFit()
                                                .frame(width: geo.size.width * 0.2, height: geo.size.height * 0.15)
                                                .scaleEffect(1.8)
                                        }
                                        
                                        if radioPlayer.isLoading {
                                            LoadingView()
                                                .scaleEffect(1.2)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.leading, 30)
                        
                        Spacer()
                        
                       
                    }
                    HStack {
                        
                        Button(action: {
                            showSocialFeed = true
                        }) {
                            Image("btn_expand_social_media")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width * 0.2, height: geo.size.height * 0.2)
                        }
                        .offset(y: geo.size.height * 0.1)
                        
                        Spacer()
                        ZStack{
                            Image("bg_main_song_cover_shadow")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width * 0.35, height: geo.size.height * 0.5)
                                .scaleEffect(1.1)
                                .border(Color.green)
                                .offset(x: geo.size.width * 0.1)
                            
                            ZStack {
                                AlbumArtworkView(
                                    artwork: radioPlayer.albumArtwork,
                                    maskImageName: UIDevice.current.userInterfaceIdiom == .phone ? "img_main_song_cover" : "capa_do_album"
                                )
                                .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? geo.size.width * 0.35 : geo.size.width * 0.45, height: geo.size.height * 0.55)
                                .scaleEffect(1.1)
                                .border(Color.blue)
                                .offset(x: geo.size.width * 0.1, y: geo.size.height * -0.01)
                                
                                
                                if dataController.minimalMode {
                                   
                                } else {
                                    LottieView(animationName: "traco_capa_de_album_principal")
                                        .scaledToFill()
                                        .frame(width: geo.size.width * 0.35, height: geo.size.height * 0.55)
                                        .scaleEffect(1.3)
                                        .offset(x: geo.size.width * 0.17, y: geo.size.height * 0.01)
                                }
                            }
                        }
                    }
                    
                    
                }
            }
        }
    }
    
    private func getSocial(for rotulo: String) -> Social? {
        guard let appData = dataController.appData else {
            return nil
        }

        for radio in appData.app.radios {
            if let social = radio.sociais.first(where: { $0.rotulo == rotulo }) {
                return social
            }
        }

        return nil
    }

    private func openWhatsapp() {
        linkHandler.openSocial("whatsapp")
    }

    private func openInstagram() {
        linkHandler.openSocial("instagram")
    }

    private func openFacebook() {
        linkHandler.openSocial("facebook")
    }

    private func openYoutube() {
        linkHandler.openSocial("youtube")
    }

    private func handleBannerTap(_ name: String) {
        switch name {
        case "weather_card":
            router.go(to: .clima)
        case "card_view_your_playlists_main":
            router.go(to: .playlist)
        case "card_view_whatsapp_main":
            linkHandler.openSocial("whatsapp")
        case "card_view_facebook_main":
            linkHandler.openSocial("facebook")
        case "card_view_instagram_main":
            linkHandler.openSocial("instagram")
        case "card_view_tiktok_main":
            linkHandler.openSocial("tiktok")
        case "card_view_youtube_main":
            linkHandler.openSocial("youtube")
        default:
            print("Banner sem ação definida: \(name)")
        }
    }

    private func fetchWeatherIfPossible() {
        if let loc = locManager.lastLocation {
            weatherSvc.fetchWeather(
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude
            )
        } else {
            // Se não tem localização, tenta Salvador como fallback
            weatherSvc.fetchWeather()
            locManager.startOnceIfAuthorized()
        }
    }
}
