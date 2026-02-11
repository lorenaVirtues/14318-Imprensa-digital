import SwiftUI
import AVFoundation
import AVKit

struct SplashView: View {
    let height = UIScreen.main.bounds.size.height
    let width = UIScreen.main.bounds.size.width
    @State private var visible = false
    
    var body: some View {
        GeometryReader{ geo in
            
            let isPortrait = geo.size.height > geo.size.width
            if isPortrait {
                portrait(geo: geo)
            } else {
                landscape(geo: geo)
            }
        }
        .onAppear {
                    Task {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        withAnimation(.easeIn(duration: 0.4)) {
                            visible = true
                        }
                    }
                }
    }
    
    
    
    @ViewBuilder
    private func portrait(geo: GeometryProxy) -> some View {
        let h = geo.size.height
        let w = geo.size.width
        /// MARK: Caso precise do vídeo de fundo
        ZStack(alignment: .trailing){
           VideoSplashBackground(
                isLandscape: false,
                portraitNames:  ["splash_828x1792", "splash_800x1280", "splash_1024x1366"],
                landscapeNames: ["splash_1792x828", "splash_1280x800", "splash_1792x828"]
            ).ignoresSafeArea()
        }
    }
    
    @ViewBuilder
    private func landscape(geo: GeometryProxy) -> some View {
        let w = geo.size.width
        let h = geo.size.height
        
        /// MARK: Caso precise do vídeo de fundo
        ZStack(alignment: .trailing){
           VideoSplashBackground(
                isLandscape: true,
                portraitNames:  ["splash_828x1792", "splash_800x1280", "splash_1024x1366"],
                landscapeNames: ["splash_1792x828", "splash_1280x800", "splash_1792x828"]
            ).ignoresSafeArea()
        }
    }
}



// MARK: - VideoSplashBackground (agora parametrizável)
struct VideoSplashBackground: View {
    let isLandscape: Bool
    let portraitNames: [String]
    let landscapeNames: [String]
    let defaultFileExtension: String

    @StateObject private var engine = VideoEngine()

    /// Conveniência: mantém comportamento atual se nada for passado
    init(
        isLandscape: Bool,
        portraitNames: [String]? = nil,
        landscapeNames: [String]? = nil,
        defaultFileExtension: String = "mp4"
    ) {
        self.isLandscape = isLandscape
        self.portraitNames = portraitNames ?? ["splash_828x1792", "splash_800x1280", "splash_1024x1366"]
        self.landscapeNames = landscapeNames ?? ["splash_1792x828", "splash_1280x800", "splash_1792x828"]
        self.defaultFileExtension = defaultFileExtension
    }

    var body: some View {
        GeometryReader { geo in
            let screenAR = max(geo.size.width, 1) / max(geo.size.height, 1)
            let pick = bestMatchURL(for: screenAR, landscape: isLandscape)

            ZStack {
                Color.black.ignoresSafeArea()

                if let player = engine.player {
                    if isLandscape {
                        PlayerLayerView(player: player, gravity: .resizeAspectFill)
                            .ignoresSafeArea()
                    } else {
                        PlayerLayerView(player: player, gravity: .resizeAspectFill)
                            .blur(radius: 18)
                            .ignoresSafeArea()
                        PlayerLayerView(player: player, gravity: .resizeAspect)
                            .ignoresSafeArea()
                    }
                }
            }
            .task(id: "\(isLandscape)-\(pick?.absoluteString ?? "nil")") {
                if let url = pick { await engine.configure(with: url) }
                else { engine.pause() }
            }
            .onDisappear { engine.pause() }
        }
    }

    // MARK: - Escolha do melhor vídeo
    private func bestMatchURL(for screenAspect: CGFloat, landscape: Bool) -> URL? {
        func url(from nameOrURL: String) -> URL? {
            // Se for URL absoluta, usa direto
            if let u = URL(string: nameOrURL), u.scheme != nil { return u }

            // Se vier com extensão, separa; se não, usa a default
            if let dot = nameOrURL.lastIndex(of: ".") {
                let res = String(nameOrURL[..<dot])
                let ext = String(nameOrURL[nameOrURL.index(after: dot)...])
                return Bundle.main.url(forResource: res, withExtension: ext)
            } else {
                return Bundle.main.url(forResource: nameOrURL, withExtension: defaultFileExtension)
            }
        }

        func urls(from names: [String]) -> [URL] {
            names.compactMap { url(from: $0) }
        }

        let wanted  = landscape ? landscapeNames : portraitNames
        var choices = urls(from: wanted)
        if choices.isEmpty {
            choices = urls(from: landscape ? portraitNames : landscapeNames)
        }
        guard !choices.isEmpty else { return nil }

        func aspect(of url: URL) -> CGFloat {
            let asset = AVAsset(url: url)
            guard let track = asset.tracks(withMediaType: .video).first else { return 9/16 }
            let size = track.naturalSize.applying(track.preferredTransform)
            let w = abs(size.width), h = abs(size.height)
            return h > 0 ? w / h : 9/16
        }

        return choices.min { lhs, rhs in
            abs(aspect(of: lhs) - screenAspect) < abs(aspect(of: rhs) - screenAspect)
        }
    }
}

// MARK: - Engine (um player + looper compartilhado)
@MainActor
final class VideoEngine: ObservableObject {
    @Published var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var currentURL: URL?

    func configure(with url: URL) async {
        guard currentURL != url else { player?.play(); return }
        currentURL = url

        let asset = AVURLAsset(url: url)
        let item  = AVPlayerItem(asset: asset)
        let queue = player ?? AVQueuePlayer()
        queue.removeAllItems()
        queue.isMuted = false
        queue.actionAtItemEnd = .none

        looper = AVPlayerLooper(player: queue, templateItem: item)
        if player == nil { player = queue }

        await queue.seek(to: .zero)
        queue.play()
    }

    func pause() { player?.pause() }
}

// MARK: - Views de camada de vídeo
struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer
    var gravity: AVLayerVideoGravity

    func makeUIView(context: Context) -> PlayerContainerView {
        let v = PlayerContainerView()
        v.playerLayer.player = player
        v.playerLayer.videoGravity = gravity
        v.backgroundColor = .clear
        return v
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.playerLayer.videoGravity = gravity
        uiView.playerLayer.player = player
    }
}

final class PlayerContainerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
