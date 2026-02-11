//
//  PrincipalView.swift
//  imprensa
//
//  Created by Virtues25 on 09/02/26.
//

import SwiftUI
import StoreKit


private let reviewCountKey = "reviewCount"

struct PrincipalView: View {
    @EnvironmentObject var dataController: AppDataController
    @EnvironmentObject var radioPlayer: RadioPlayer
    @EnvironmentObject var router: NavigationRouter
    
    @State var radio: RadioModel
    
    @State private var menuOffset: CGFloat = -UIScreen.main.bounds.width
    @State private var showMenu = false
    @State private var showAvaliar = false
    @State private var showCompartilhar = false
    @State private var showTermos = false
    @State private var showSite = false
    @State private var showWhatsapp = false
    @State private var showFacebook = false
    @State private var showInstagram = false
    
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
                
                if showMenu{
                    MenuView(onClose: {
                        withAnimation {
                            menuOffset = -UIScreen.main.bounds.width
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                            showMenu = false
                        }
                    },onContato: {
                        router.go(to: .contato)
                        showMenu = false
                    }, onSite: {
                        showSite = true
                        showMenu = false
                    }, onFacebook: {
                        openFacebook()
                        showMenu = false
                    }, onInstagram: {
                        openInstagram()
                        showMenu = false
                    }, onWhatsapp: {
                        openWhatsapp()
                        showMenu = false
                    },  onAvaliar: {
                        showMenu = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            avaliarApp()
                        }
                    }, onCompartilhar: {
                        showCompartilhar = true
                        showMenu = false
                    }, onTermos: {
                        showTermos = true
                        showMenu = false
                    })
                    .offset(x: menuOffset)
                    .onAppear{
                        withAnimation{
                            menuOffset = 0
                        }
                    }
                    .zIndex(1)
                }//fim showMenu
            }
        }
        .onAppear{
            dataController.parseAppData()
        }
        .onReceive(dataController.$appData) { appData in
            if let streaming = appData?.app.radios.first?.streaming {
                self.radio = RadioModel(streamUrl: streaming)
                if let url = URL(string: streaming) {
                    radioPlayer.initPlayer(url: url)
                    radioPlayer.play(self.radio)
                }
            }
        }
    }
    
    @ViewBuilder
    private func portrait(geo: GeometryProxy) -> some View {
        ZStack{
            Color.white
                .ignoresSafeArea(.all)
            
            VStack{
                HStack{
                    Button(action: {
                        showMenu = true
                    }, label:{
                        Image("menu")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.1, height: geo.size.height * 0.1)
                            .foregroundColor(Color("azulEscuro"))
                            .padding()
                    })
                    
                    Spacer()
                }
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.8, height: geo.size.height * 0.2)
                    .padding(.top)
                
                Spacer()
                
                HStack{
                    VStack(alignment: .leading){
                        Text(radioPlayer.itemMusic)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                        Text(radioPlayer.itemArtist)
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                    Spacer()
                    
                    Button(action:{
                        radioPlayer.playToggle(with: radio)
                    }, label:{
                        VStack {
                            if radioPlayer.isLoading {
                                LoadingView()
                                    .padding(.bottom, 5)
                            }
                            
                            Image(radioPlayer.isPlaying ? "bg_player_pause" : "bg_player_play")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width * 0.25, height: UIDevice.current.userInterfaceIdiom == .phone ? geo.size.height * 0.3 : geo.size.height * 0.4)
                        }
                    })
                }
                .padding(.leading)
                Spacer()
                
                Button(action: {
                    showCompartilhar = true
                }, label:{
                    Image("share-fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width * 0.1, height: geo.size.height * 0.1)
                        .foregroundColor(Color("azulEscuro"))
                })
            }
            
        }

    }
    
    @ViewBuilder
    private func landscape(geo: GeometryProxy) -> some View {
        ZStack{
            Color.white
                .ignoresSafeArea(.all)
            
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
}
