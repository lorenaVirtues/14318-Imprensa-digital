//
//  AudioView.swift
//  imprensa
//
//  Created by Virtues25 on 12/02/26.
//

import SwiftUI

struct AudioView: View {
    @EnvironmentObject var dataController: AppDataController
    @EnvironmentObject var radioPlayer: RadioPlayer
    @EnvironmentObject var router: NavigationRouter
    

    
    let height = UIScreen.main.bounds.size.height
    let width = UIScreen.main.bounds.size.width
    @State private var showingPlaylistPicker = false
    
    var body: some View {
        GeometryReader{ geo in
            let isPortrait = geo.size.height > geo.size.width
            if isPortrait {
                portrait(geo: geo)
            } else {
                landscape(geo: geo)
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
    
    @ViewBuilder
    private func portrait(geo: GeometryProxy) -> some View {
        Color("azulEscuro")
            .edgesIgnoringSafeArea(.bottom)
        
        ZStack{
            Color.white
            VStack {
                ZStack {
                    Image(UIDevice.current.userInterfaceIdiom == .phone ? "bg_song_cover_shadow" : "sombra_capa_de_album")
                        .resizable()
                        .scaledToFit()
                    
                    ZStack {
                        if let artwork = radioPlayer.albumArtwork {
                            Image(uiImage: artwork)
                                .resizable()
                                .scaledToFit()
                                .mask(
                                    Image(UIDevice.current.userInterfaceIdiom == .phone ? "img_song_cover" : "forma_capa_de_album")
                                        .resizable()
                                        .scaledToFit()
                                )
                                
                        } else {
                            Image(UIDevice.current.userInterfaceIdiom == .phone ? "img_song_cover" : "forma_capa_de_album")
                                .resizable()
                                .scaledToFit()
                        }
                        
                        if !dataController.minimalMode {
                            LottieView(animationName: "traco_capa_de_album_player")
                                .scaledToFit()
                                .scaleEffect(1.5)
                                .offset(x: geo.size.width * 0.16, y: geo.size.height * -0.14)
                        }
                    }
                    
                    
                    // Barra de Volume Diagonal
                    ZStack(alignment: .leading) {
                        // Track Total (Cinza)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: geo.size.width * 0.6, height: 5)
                        
                        Rectangle()
                            .fill(Color(red: 26/255, green: 60/255, blue: 114/255))
                            .frame(width: CGFloat(radioPlayer.volume) * (geo.size.width * 0.6), height: 5)
                        
                        // Botão (Thumb)
                        Rectangle()
                            .fill(Color(red: 112/255, green: 42/255, blue: 78/255))
                            .frame(width: 12, height: 20)
                            .offset(x: CGFloat(radioPlayer.volume) * (geo.size.width * 0.6) - 6)
                        
                        // Área de Toque Ampliada (Invisível)
                        Rectangle()
                            .fill(Color.white.opacity(0.001))
                            .frame(width: geo.size.width * 0.6, height: 40)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { gesture in
                                        let translation = gesture.location.x
                                        let newVolume = Float(translation / (geo.size.width * 0.6))
                                        radioPlayer.volume = max(0, min(1, newVolume))
                                    }
                            )
                    }
                    .rotationEffect(.degrees(-135)) // Rotaciona para que o início (0) fique embaixo e o fim (100) em cima
                    .offset(x: -geo.size.width * 0.15, y: geo.size.height * 0.18)
                    .border(Color.pink)
                }.ignoresSafeArea(.all)
                Spacer()
            }
            
            VStack{
                HStack{
                    ZStack {
                        Image("bg_volume")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.3, height: geo.size.height * 0.25, alignment: .leading)
                        
                        HStack(alignment: .bottom, spacing: 2) {
                            Text("\(Int(radioPlayer.volume * 100))")
                                .font(.custom("Spartan-Regular", size: 28))
                            Text("%")
                                .font(.custom("Spartan-Regular", size: 12))
                                .padding(.bottom, 5)
                        }
                        .foregroundColor(Color(red: 26/255, green: 60/255, blue: 114/255))
                        .offset(x: -8)
                        .border(Color.yellow)
                    }
                    .border(Color.green)
                    .offset(x: geo.size.width * 0.0, y: geo.size.height * 0.22)
                  
                    
                    Spacer()
                    
                    Button(action:{
                        radioPlayer.playToggle(with: radioPlayer.currentRadio ?? RadioModel(streamUrl: ""))
                    }, label:{
                        if dataController.minimalMode {
                            ZStack {
                                Image(radioPlayer.isPlaying ? "bg_player_pause" : "bg_player_play")
                                     .resizable()
                                     .scaledToFit()
                                     .frame(width: geo.size.width * 0.4, height: geo.size.height * 0.45)
                                
                                if radioPlayer.isLoading {
                                    LoadingView()
                                        .scaleEffect(2.5)
                                }
                            }
                        } else {
                            ZStack {
                                LottieView(animationName: "sombra_play")
                                    .scaledToFit()
                                    .frame(width: geo.size.width * 0.45, height: geo.size.height * 0.3)
                                    .scaleEffect(1.5)
                                    .offset(x: geo.size.width * 0.23, y: geo.size.height * 0.07)
                                
                                Image(radioPlayer.isPlaying ? "bg_pause" : "bg_play")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width * 0.4, height: geo.size.height * 0.45)
                                    .offset(x: geo.size.width * 0.05)
                                
                                if radioPlayer.isLoading {
                                    LoadingView()
                                        .scaleEffect(3.0)
                                        .offset(x: geo.size.width * 0.05)
                                }
                            }
                        }
                       
                    })
                    .offset(y: geo.size.height * 0.35)
                }
                
                HStack{
                    VStack (alignment: .leading){
                        VStack (alignment: .leading, spacing: 0){
                            Text(radioPlayer.itemMusic)
                                .font(.custom("Spartan-Bold", size: 16))
                                .foregroundColor(Color.black)
                            
                            Text(radioPlayer.itemArtist)
                                .font(.custom("Spartan-Regular", size: 16))
                                .foregroundColor(Color.black)
                        }
                        
                        HStack (spacing: 30){
                            Image("ic_triangle_actions")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width * 0.07, height: geo.size.height * 0.04)
                            
                            Button(action:{
                                withAnimation { showingPlaylistPicker = true }
                            }, label:{
                                Image("btn_add_playlist_active")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width * 0.09, height: geo.size.height * 0.07)
                            })
                            
                            Button(action:{
                                
                            }, label:{
                                Image("btn_bluetooth")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width * 0.09, height: geo.size.height * 0.07)
                            })
                            
                            Button(action:{
                                
                            }, label:{
                                Image("btn_chromecast")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width * 0.09, height: geo.size.height * 0.07)
                            })
                        }
                        
                        Image("bg_connected_device_card")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.6, height: geo.size.height * 0.08)
                    }
                    .padding(.leading, 10)
                    Spacer()
                }
                .offset(y: geo.size.height * 0.2)
                
                Spacer()
                
                HStack{
                    Button(action:{
                        router.goHome()
                    }, label:{
                        Image("btn_return")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.25, height: geo.size.height * 0.1)
                    })
                    
                    Spacer()
                }
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
}
