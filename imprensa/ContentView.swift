import SwiftUI
import GoogleCast
import StoreKit
//import Shimmer
import UIKit
import AVKit

private var reviewCountKey = "reviewRequestCount"

struct ContentView: View {
    let castManager = CastManager.shared
    let height = UIScreen.main.bounds.size.height
    let width = UIScreen.main.bounds.size.width
    @StateObject private var castSession = CastSessionManager.shared
    @StateObject private var monitor = Monitor()
    @StateObject private var speechManager = SpeechManager()
    @State private var hasStarted = false
    @State private var showSobre = false
    @State private var showTermos = false
    @State private var showCompartilhar = false
    @State private var menuOffset: CGFloat = -UIScreen.main.bounds.width
    @State private var dataLoading = false
    @State private var currentRadioId: String? = nil // Rastreia qual rádio está tocando
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var launchTracker: LaunchTracker
    @EnvironmentObject private var locManager: LocationManager
    @EnvironmentObject private var weatherSvc: WeatherService
    @EnvironmentObject private var dateTimeSvc: DateTimeService
    @EnvironmentObject private var dataController: AppDataController
    @EnvironmentObject private var linkHandler: LinkHandler
    @EnvironmentObject private var radioPlayer: RadioPlayer
    @EnvironmentObject private var router: NavigationRouter
    @EnvironmentObject private var lottieCtrl: LottieControlCenter
    
    var body: some View {
        GeometryReader{ geo in
            Color(.black).ignoresSafeArea()
            let isPortrait = geo.size.height > geo.size.width
            if isPortrait {
                portrait(geo: geo)
            } else {
                landscape(geo: geo)
            }
            
            if dataController.isLoading {
                LoaderView()
            } else if dataController.errorMessage != nil {
                ErrorView(onReconnect: {
                    dataController.parseAppData()
                })
            }
            
            
            Group{
                Button(action: {  }, label: {  }) .fullScreenCover(isPresented: $showCompartilhar) {
                    if let urlString = dataController.appData?.app.share,
                       let url = URL(string: urlString) {
                        ActivityView(activityItems: [NSURL(string: urlString)!] as [Any], applicationActivities: nil)
                    }
                }
            }
        }
        .onAppear  {
            fetchIfPossible()
            
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
        .onChange(of: locManager.lastLocation) { _ in fetchIfPossible() }
        .navigationTitle("Voltar")
        .navigationBarHidden(true)
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
    private func fetchIfPossible() {
        guard let loc = locManager.lastLocation else { return }
        guard weatherSvc.shouldFetch(for: loc) else { return }

        weatherSvc.fetchWeather(
            latitude: loc.coordinate.latitude,
            longitude: loc.coordinate.longitude
        )
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
    
    @ViewBuilder
    private func portrait(geo: GeometryProxy) -> some View {
        let h = geo.size.height
        let w = geo.size.width
        ZStack(alignment: .top){
        }
        .frame(width: w)
    }
    
    @ViewBuilder
    private func landscape(geo: GeometryProxy) -> some View {
        let w = geo.size.width
        let h = geo.size.height
        ZStack{
            
        }
    }
}

