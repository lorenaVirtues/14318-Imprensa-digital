//
//  ContentView.swift
//  imprensa
//
//  Created by Virtues25 on 09/02/26.
//

import SwiftUI
import GoogleCast
import StoreKit
//import Shimmer
import UIKit
import AVKit



struct ContentView: View {
    let castManager = CastManager.shared
    let height = UIScreen.main.bounds.size.height
    let width = UIScreen.main.bounds.size.width
    @StateObject private var castSession = CastSessionManager.shared
    @StateObject private var monitor = Monitor()
    @State private var hasStarted = false
    @State private var showSobre = false
    @State private var menuOffset: CGFloat = -UIScreen.main.bounds.width
    @State private var dataLoading = false
    @State private var currentRadioId: String? = nil
    @EnvironmentObject private var launchTracker: LaunchTracker
    @EnvironmentObject private var dataController: AppDataController
    @EnvironmentObject private var linkHandler: LinkHandler
    @EnvironmentObject private var radioPlayer: RadioPlayer
    @EnvironmentObject private var router: NavigationRouter
 //   @EnvironmentObject private var lottieCtrl: LottieControlCenter
    var body: some View {
        GeometryReader{ geo in
            Color(.black).ignoresSafeArea()
            if dataController.isLoading {
                LoaderView()
            } else if dataController.errorMessage != nil {
                ErrorView(onReconnect: {
                    dataController.parseAppData()
                })
            }
            
        }
        .onAppear  {
            guard !launchTracker.didStartRadio,
                  UserDefaults.autoplayEnabled, // Valida autoplay antes de iniciar
                  let first = dataController.appData?.app.radios.first,
                  let url = URL(string: first.streaming.trimmingCharacters(in: .whitespaces))
            else { return }
            
            launchTracker.didStartRadio = true
            radioPlayer.initPlayer(url: url)
            radioPlayer.playToggle(with: RadioModel(streamUrl: first.streaming.trimmingCharacters(in: .whitespaces)))
            currentRadioId = first.id
            castManager.setVideoStream(first.streaming.trimmingCharacters(in: .whitespaces), "audio/aac")
            
            NotificationCenter.default.addObserver(forName: .castSessionEnded, object: nil, queue: .main) { notification in
                // Reinicia a rádio que estava tocando antes do cast
                if let currentId = currentRadioId,
                   let radio = dataController.appData?.app.radios.first(where: { $0.id == currentId }),
                   let url = URL(string: radio.streaming.trimmingCharacters(in: .whitespaces)) {
                    print("Reiniciando o player local após Cast ser interrompido...")
                    radioPlayer.initPlayer(url: url)
                    radioPlayer.play(RadioModel(streamUrl: radio.streaming.trimmingCharacters(in: .whitespaces)))
                }
            }
            
            NotificationCenter.default.addObserver(forName: .castSessionDidStart, object: nil, queue: .main) { notification in
                print("Parando rádio local - Cast iniciado")
                radioPlayer.stop()
            }
        }
        .onReceive(monitor.$status) { status in
            switch status {
            case .desconnected:
                if !dataController.isLoading {
                    dataController.errorMessage = "Sem conexão com a Internet"
                }
            case .connected:
                if dataController.appData == nil {
                    dataController.parseAppData()
                } else if dataController.errorMessage == "Sem conexão com a Internet" {
                    dataController.errorMessage = nil
                }
            }
        }
        .navigationTitle("Voltar")
        .navigationBarHidden(true)
    }

    func playToggle() {
            guard monitor.status == .connected else {
                return
            }

            if castManager.isCasting {
                if castSession.isCastPlaying {
                    castManager.remoteClient?.pause()
                } else {
                    castManager.remoteClient?.play()
                }
                castSession.isCastPlaying.toggle()
            } else {
                if let first = dataController.appData?.app.radios.first {
                                let model = RadioModel(streamUrl: first.streaming)

                    radioPlayer.playToggle(with: model)
                }
            }
        }
    
}
