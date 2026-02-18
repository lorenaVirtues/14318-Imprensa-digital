import SwiftUI
import StoreKit
import AVKit
import GoogleCast

private let reviewCountKey = "reviewCount"

struct MenuView: View {
    @EnvironmentObject var dataController: AppDataController
    @EnvironmentObject var radioPlayer: RadioPlayer
    @EnvironmentObject var router: NavigationRouter
    
    @State private var showTermos = false
    @State private var showSite = false
    @State private var showCompartilhar = false
    @State private var showWhatsapp = false
    @State private var showFacebook = false
    @State private var showInstagram = false
    @State private var showYoutube = false
    
    @AppStorage("isMinimalMode") private var isMinimalMode = false
    
    let height = UIScreen.main.bounds.size.height
    let width = UIScreen.main.bounds.size.width
    
    var body: some View {
        GeometryReader{ geo in
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
                .fullScreenCover(isPresented: $showSite) {
                    if let site = dataController.appData?.app.site {
                        let url = URL(string: site)!
                        SafariView(url: url)
                    }
                }
                .fullScreenCover(isPresented: $showTermos) {
                    if let termos = dataController.appData?.app.privacy,
                       let url = URL(string: termos) {
                        SafariView(url: url)
                    } else {
                        Text("Link de privacidade indisponível")
                            .font(.headline)
                            .padding()
                    }
                }
                .fullScreenCover(isPresented: $showWhatsapp, content: {
                    if let social = getSocial(for: "whatsapp") {
                        let url = URL(string: "https://api.whatsapp.com/send?phone=\(social.scheme)")!
                        SafariView(url: url)
                    }
                })
                .fullScreenCover(isPresented: $showInstagram) {
                    if let social = getSocial(for: "instagram") {
                        let url = URL(string: social.link)!
                        SafariView(url: url)
                    }
                }
                .fullScreenCover(isPresented: $showFacebook) {
                    if let social = getSocial(for: "facebook") {
                        let url = URL(string: social.link)!
                        SafariView(url: url)
                    }
                }
                .fullScreenCover(isPresented: $showYoutube) {
                    if let social = getSocial(for: "youtube") {
                        let url = URL(string: social.link)!
                        SafariView(url: url)
                    }
                }
            }
        }
        .onAppear{
            dataController.parseAppData()
        }
    } // fim do body
    
    @ViewBuilder
    private func portrait(geo: GeometryProxy) -> some View {
        ZStack {
            Color.white
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0){
                // Header
                HStack{
                    if isMinimalMode {
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
                    
                    HeaderDateTimeView()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
               
                Divider()
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                
                // Navigation Bar
                HStack{
                    Button(action:{
                        router.goHome()
                    }, label:{
                        Image("btn_nav_home_default")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.1, height: geo.size.height * 0.05)
                    })
                    
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
                    
                    Image("btn_nav_menu_active")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width * 0.3, height: geo.size.height * 0.05)
                        
                    
                    Spacer()
                    
                    Image("bg_triangle_nav_buttons")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width * 0.07, height: geo.size.height * 0.05)
                }
                .padding(.horizontal, 20)
                
                Divider()
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // SOBRE O APP Section
                        MenuSection(title: "SOBRE O APP") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                MenuItem(icon: "btn_menu_contact") { router.go(to: .contato) }
                                MenuItem(icon: "btn_menu_rate") { avaliarApp() }
                                MenuItem(icon: "btn_menu_about_us") { router.go(to: .sobre) }
                                MenuItem(icon: "btn_menu_terms") { showTermos = true }
                                MenuItem(icon: "btn_menu_share") { showCompartilhar = true }
                            }
                            .padding()
                        }
                        
                        Divider()
                            .foregroundColor(.gray)
                            .padding(.vertical, 10)
                        
                        // REDES SOCIAIS Section
                        MenuSection(title: "REDES SOCIAIS") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                MenuItem(icon: "btn_menu_whatsapp") { openWhatsapp() }
                                MenuItem(icon: "btn_menu_facebook") { openFacebook() }
                                MenuItem(icon: "btn_menu_instagram") { openInstagram() }
                                MenuItem(icon: "btn_menu_youtube") { openYoutube() }
                                MenuItem(icon: "btn_menu_website") { showSite = true }
                            }
                            .padding()
                        }
                        
                        Divider()
                            .foregroundColor(.gray)
                            .padding(.vertical, 10)
                        
                        // PAREAMENTO Section
                        MenuSection(title: "PAREAMENTO") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                MenuItem(icon: "btn_menu_bluetooth") { openAirPlay() }
                                MenuItem(icon: "btn_menu_chromecast") {   let castButton = GCKUICastButton(frame: .zero)
                                    castButton.sendActions(for: .touchUpInside) }
                            }
                            .padding()
                        }
                        
                        Divider()
                            .foregroundColor(.gray)
                            .padding(.vertical, 10)
                        
                        // IR PARA Section
                        MenuSection(title: "IR PARA") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                MenuItem(icon: "btn_menu_playlists") { router.go(to: .playlist) }
                                MenuItem(icon: "btn_menu_weather") { router.go(to: .clima) }
                            }
                            .padding()
                        }
                    }
                    .padding(20)
                }
            }
        }
    }

    @ViewBuilder
    private func landscape(geo: GeometryProxy) -> some View {
        ZStack {
            Color.white
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0){
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
                    .padding(.vertical, 10)
                
                // Navigation Bar
                HStack{
                    Button(action:{
                        router.goHome()
                    }, label:{
                        Image("btn_nav_home_default")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.07, height: geo.size.height * 0.1)
                    })
                    
                    Spacer()
                    
                    Button(action:{
                        router.go(to: .audio)
                    }, label:{
                        Image("btn_nav_audio_player_default")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.07, height: geo.size.height * 0.1)
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
                    
                    Image("btn_nav_menu_active")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width * 0.15, height: geo.size.height * 0.1)
                        
                    
                    Spacer()
                    
                    Image("bg_triangle_nav_buttons")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width * 0.04, height: geo.size.height * 0.08)
                }
                .padding(.horizontal, 20)
                
                Divider()
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // SOBRE O APP Section
                        MenuSection(title: "SOBRE O APP") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                MenuItem(icon: "btn_menu_contact") { router.go(to: .contato) }
                                MenuItem(icon: "btn_menu_rate") { avaliarApp() }
                                MenuItem(icon: "btn_menu_about_us") { router.go(to: .sobre) }
                                MenuItem(icon: "btn_menu_terms") { showTermos = true }
                                MenuItem(icon: "btn_menu_share") { showCompartilhar = true }
                            }
                            .padding()
                        }
                        
                        Divider()
                            .foregroundColor(.gray)
                            .padding(.vertical, 10)
                        
                        // REDES SOCIAIS Section
                        MenuSection(title: "REDES SOCIAIS") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                MenuItem(icon: "btn_menu_whatsapp") { openWhatsapp() }
                                MenuItem(icon: "btn_menu_facebook") { openFacebook() }
                                MenuItem(icon: "btn_menu_instagram") { openInstagram() }
                                MenuItem(icon: "btn_menu_youtube") { openYoutube() }
                                MenuItem(icon: "btn_menu_website") { showSite = true }
                            }
                            .padding()
                        }
                        
                        Divider()
                            .foregroundColor(.gray)
                            .padding(.vertical, 10)
                        
                        // PAREAMENTO Section
                        MenuSection(title: "PAREAMENTO") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                MenuItem(icon: "btn_menu_bluetooth") { openAirPlay() }
                                MenuItem(icon: "btn_menu_chromecast") {   let castButton = GCKUICastButton(frame: .zero)
                                    castButton.sendActions(for: .touchUpInside) }
                            }
                            .padding()
                        }
                        
                        Divider()
                            .foregroundColor(.gray)
                            .padding(.vertical, 10)
                        
                        // IR PARA Section
                        MenuSection(title: "IR PARA") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                MenuItem(icon: "btn_menu_playlists") { router.go(to: .playlist) }
                                MenuItem(icon: "btn_menu_weather") { router.go(to: .clima) }
                            }
                            .padding()
                        }
                    }
                    .padding(20)
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
        // Usa o mesmo "whatsapp" minúsculo
        if let social = getSocial(for: "whatsapp") {
            let scheme0 = social.scheme
            // Whatsapp is not supported in the internal feed, keeping deep link
            let scheme = URL(string: "whatsapp://send?phone=\(scheme0)")!
            let application = UIApplication.shared
            if application.canOpenURL(scheme) {
                application.open(scheme)
            } else {
                self.showWhatsapp = true
            }
        } else {
            self.showWhatsapp = true
        }
    }

    private func openInstagram() {
        if let social = getSocial(for: "instagram") {
            let scheme0 = social.scheme
            let scheme = URL(string: "instagram://user?username=\(scheme0)")!
            let application = UIApplication.shared
            if application.canOpenURL(scheme) {
                application.open(scheme)
            } else {
                self.showInstagram = true
            }
        } else {
            self.showInstagram = true
        }
    }

    private func openFacebook() {
        if let social = getSocial(for: "facebook") {
            let scheme0 = social.scheme
            let scheme = URL(string: "fb://profile/\(scheme0)")!
            let application = UIApplication.shared
            if application.canOpenURL(scheme) {
                application.open(scheme)
            } else {
                self.showFacebook = true
            }
        } else {
            self.showFacebook = true
        }
    }

    private func openYoutube() {
        if let social = getSocial(for: "youtube") {
            let scheme0 = social.scheme
            // YouTube channel or search fallback
            let scheme = URL(string: "youtube://www.youtube.com/user/\(scheme0)")!
            let application = UIApplication.shared
            if application.canOpenURL(scheme) {
                application.open(scheme)
            } else {
                self.showYoutube = true
            }
        } else {
            self.showYoutube = true
        }
    }
    
    private func avaliarApp() {
        let defaults = UserDefaults.standard
        var count = defaults.integer(forKey: reviewCountKey)
        count += 1
        defaults.set(count, forKey: reviewCountKey)
        
        if count <= 3 {
            // Pede avaliação dentro do app (se o sistema permitir)
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        } else {
            // Direciona para a App Store
            let appID = "6758960311" // substitua pelo ID do seu app na App Store
            if let url = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    private func openAirPlay() {
            print("🔵 Abrindo seletor de dispositivos (AirPlay/Bluetooth)...")

            // Força a sessão de áudio para playback
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try? AVAudioSession.sharedInstance().setActive(true, options: [])

            // Simula o toque no AVRoutePickerView
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    let routePicker = AVRoutePickerView()
                    routePicker.prioritizesVideoDevices = false
                    if #available(iOS 13.0, *) {
                        routePicker.activeTintColor = .white
                        routePicker.tintColor = .white
                    }

                    // Adiciona temporariamente à view
                    window.addSubview(routePicker)
                    routePicker.isHidden = true

                    // Simula o toque
                    for subview in routePicker.subviews {
                        if let button = subview as? UIButton {
                            button.sendActions(for: .touchUpInside)
                            print("✅ Seletor de dispositivos aberto")
                            break
                        }
                    }

                    // Remove após um delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        routePicker.removeFromSuperview()
                    }
                }
            }
        }
}

// MARK: - Components

struct MenuSection<Content: View>: View {
    var title: String
    var content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "play.fill")
                    .resizable()
                    .frame(width: 10, height: 10)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.custom("Spartan-Bold", size: 16))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(Color(red: 26/255, green: 60/255, blue: 104/255))
            
            VStack {
                content()
            }
            .background(Color(red: 245/255, green: 245/255, blue: 245/255))
        }
    }
}

struct MenuItem: View {
    var icon: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? 150 : 200, height: UIDevice.current.userInterfaceIdiom == .phone ? 50 : 60)
                
        }
    }
}

