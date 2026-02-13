import SwiftUI

final class LaunchTracker: ObservableObject {
  @Published var didStartRadio = false
}

struct AppRoot: View {
    @StateObject private var launchTracker = LaunchTracker()
    @StateObject private var router = NavigationRouter()
    @StateObject private var dataController = AppDataController()
    @StateObject private var linkHandler = LinkHandler.shared
    @StateObject private var lottieCtrl = LottieControlCenter()
    @StateObject private var castSession = CastSessionManager.shared
    @StateObject private var locManager = LocationManager()
    @StateObject private var weatherSvc = WeatherService()
    @StateObject private var playlistManager = PlaylistManager()
    @StateObject private var monitor = Monitor()
    @StateObject private var recognitionService = NowPlayingRecognitionService()
    @StateObject private var ytPlayer = YouTubeBackgroundPlayer.shared
    @State private var didParse   = false
    @State private var timerDone  = false
    @State var radio: RadioModel
    
    @EnvironmentObject private var radioPlayer: RadioPlayer
    
    var body: some View {
        NavigationView {
            ZStack {
                switch router.currentRoute {
                case .splash:
                    SplashView()
                        .transition(.opacity)     // fade-in/out
                case .home:
                    PrincipalView(radio: radio)
                        .environmentObject(radioPlayer)
                        .environmentObject(dataController)
                case .menu:
                    MenuView()
                        .environmentObject(radioPlayer)
                        .environmentObject(dataController)
                case .contato:
                    ContatoView()
                case .audio:
                    AudioView()
                        .environmentObject(radioPlayer)
                        .environmentObject(dataController)
                case .config:
                    ConfigView()
                        .environmentObject(radioPlayer)
                        .environmentObject(dataController)
                case .clima:
                    ClimaView()
                        .environmentObject(dataController)
                case .playlist:
                    PlaylistView()
                        .environmentObject(dataController)
                case .sobre:
                    SobreView()
                        .environmentObject(dataController)
                }
                
                // Error Overlay
                if let error = dataController.errorMessage {
                    ErrorView(onReconnect: {
                        dataController.parseAppData()
                    }, errorMessage: error)
                    .transition(.opacity)
                    .zIndex(10)
                }
            }
            .sheet(item: $linkHandler.pendingURL) { url in
                SafariView(url: url)
            }
            
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .environmentObject(dataController)
        .environmentObject(linkHandler)
        .environmentObject(router)
        .environmentObject(launchTracker)
        .environmentObject(radioPlayer)
        .environmentObject(lottieCtrl)
        .environmentObject(castSession)
        .environmentObject(locManager)
        .environmentObject(weatherSvc)
        .environmentObject(playlistManager)
        .environmentObject(recognitionService)
        .environmentObject(ytPlayer)
        .onAppear {
                    recognitionService.attach(radioPlayer: radioPlayer)
                    recognitionService.start()
                    dataController.lottieControl = lottieCtrl
                    dataController.parseAppData()

            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        timerDone = true
                        tryAdvance()
                    }
                }
        .onReceive(dataController.$appData) { appData in
            guard let info = appData?.app else { return }

            if info.ativo == "2" {
                exit(0)
            }

            didParse = true
            tryAdvance()
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
    }
    private func tryAdvance() {
            guard didParse, timerDone, router.currentRoute == .splash else { return }
            withAnimation {
                router.go(to: .home)
                linkHandler.dataController = dataController
            }
        }
}
