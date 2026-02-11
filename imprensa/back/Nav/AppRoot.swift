import SwiftUI

final class LaunchTracker: ObservableObject {
  @Published var didStartRadio = false
}

struct AppRoot: View {
    @StateObject private var launchTracker = LaunchTracker()
    @StateObject private var router = NavigationRouter()
    @StateObject private var dataController = AppDataController()
    @StateObject private var linkHandler = LinkHandler.shared
   // @StateObject private var lottieCtrl = LottieControlCenter()
    @StateObject private var castSession = CastSessionManager.shared
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
                        .transition(.move(edge: .trailing))
                        .environmentObject(radioPlayer)
                        .environmentObject(dataController)
                case .menu:
                    MenuView(onClose: {},
                             onContato: {},
                             onSite: {},
                             onFacebook: {},
                             onInstagram: {},
                             onWhatsapp: {},
                             onAvaliar: {},
                             onCompartilhar: {},
                             onTermos: {})
                case .contato:
                    ContatoView()
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
        //.environmentObject(lottieCtrl)
        .environmentObject(castSession)
        .onAppear {
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
        
    }
    private func tryAdvance() {
            guard didParse, timerDone, router.currentRoute == .splash else { return }
            withAnimation {
                router.go(to: .home)
                linkHandler.dataController = dataController
            }
        }
}
