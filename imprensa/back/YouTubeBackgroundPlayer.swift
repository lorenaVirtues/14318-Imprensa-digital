import Foundation
import WebKit
import AVFoundation
import MediaPlayer
import UIKit
import Combine

final class YouTubeBackgroundPlayer: NSObject, WKNavigationDelegate, WKUIDelegate, ObservableObject {

    // MARK: - Endpoints
    private let integrationBase = "https://radiointegration.ticketss.app/index.html"

    // (opcional) utilitários
    private let legacyBaseEmbed = "https://www.youtube-nocookie.com/embed"

    // MARK: - Singleton
    static let shared = YouTubeBackgroundPlayer()

    // MARK: - Estado exposto à UI
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentKey: String? = nil
    @Published var isLoading: Bool = false

    // MARK: - Internos
    private var webView: WKWebView!
    private var hostWindow: UIWindow?
    private var cancellables = Set<AnyCancellable>()
    private let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"

    private let netSession: URLSession = {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.waitsForConnectivity = true
        cfg.timeoutIntervalForRequest = 15
        cfg.timeoutIntervalForResource = 20
        cfg.allowsConstrainedNetworkAccess = true
        cfg.allowsExpensiveNetworkAccess = true
        return URLSession(configuration: cfg)
    }()

    // gesto recente para unmute confiável
    private var hasRecentUserGesture = false

    private override init() {
        super.init()
        setupWebView()
        if !isPreview {
            activateAudioSession()
            setupCommandCenter()
            NotificationCenter.default.addObserver(self, selector: #selector(handleStopRequest), name: .appShouldStopExternalPlayer, object: nil)
        }
    }

    @objc private func handleStopRequest() {
        stop()
    }

    // Chame isso no onTap do botão play
    func noteUserGesture() { hasRecentUserGesture = true }
    func requestSound()    { forcePlayUnmute() }

    // MARK: - Setup
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        if #available(iOS 10.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = []
        } else {
            config.requiresUserActionForMediaPlayback = false
        }
        config.preferences.javaScriptEnabled = true

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self

        // ⚠️ dê "visibilidade mínima"
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.isHidden = false
        webView.alpha = 0.01
        webView.isUserInteractionEnabled = false

        webView.loadHTMLString("<html><body></body></html>", baseURL: nil)
    }

    private func attachHiddenContainerIfNeeded() {
        guard webView.superview == nil else { return }

        if let winScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let win = winScene.windows.first {
            win.addSubview(webView)
        } else if let keyWin = UIApplication.shared.windows.first {
            keyWin.addSubview(webView)
        } else {
            let w = UIWindow(frame: UIScreen.main.bounds)
            w.windowLevel = .normal
            let vc = UIViewController()
            vc.view.backgroundColor = .clear
            w.rootViewController = vc
            w.isHidden = false
            w.makeKeyAndVisible()
            vc.view.addSubview(webView)
            hostWindow = w
        }

        webView.translatesAutoresizingMaskIntoConstraints = false
        if let superV = webView.superview {
            NSLayoutConstraint.activate([
                webView.leadingAnchor.constraint(equalTo: superV.leadingAnchor),
                webView.topAnchor.constraint(equalTo: superV.topAnchor),
                // 👉 aumenta um pouco o tamanho
                webView.widthAnchor.constraint(equalToConstant: 10),
                webView.heightAnchor.constraint(equalToConstant: 10)
            ])
        }
    }

    private func activateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("🔊 AudioSession error:", error.localizedDescription)
        }
    }

    private func setupCommandCenter() {
        let cc = MPRemoteCommandCenter.shared()
        cc.playCommand.isEnabled = true
        cc.pauseCommand.isEnabled = true
        cc.togglePlayPauseCommand.isEnabled = true

        cc.playCommand.addTarget { [weak self] _ in self?.resume(); return .success }
        cc.pauseCommand.addTarget { [weak self] _ in self?.pause(); return .success }
        cc.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.isPlaying ? self.pause() : self.resume()
            return .success
        }
    }

    private func failAndClearUI() {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentKey = nil
        }
    }

    // MARK: - Public API -------------------------------------------------------

    func play(artist: String, song: String) {
        NotificationCenter.default.post(name: .appShouldStopRadio, object: nil)

        playViaIntegration(artist: artist, song: song)
        if hasRecentUserGesture {
            forcePlayUnmute()
            hasRecentUserGesture = false
        }
    }

    func playViaIntegration(artist: String, song: String) {
        NotificationCenter.default.post(name: .appShouldStopRadio, object: nil)

        activateAudioSession()
        attachHiddenContainerIfNeeded()
        stop()
        
        DispatchQueue.main.async {
            self.isLoading = true
        }

        var comps = URLComponents(string: integrationBase)!
        comps.queryItems = [
            URLQueryItem(name: "artist", value: artist),
            URLQueryItem(name: "song",   value: song)
        ]
        guard let url = comps.url else {
            failAndClearUI()
            print("⚠️ [Player] URL de integração inválida.")
            return
        }

        let key = YouTubeBackgroundPlayer.normalizedKey(artist: artist, song: song)
        DispatchQueue.main.async {
            self.currentKey = key
            self.isPlaying = true
        }

        print("🎵 [Player] solicitando integração | artist='\(artist)' | song='\(song)'")
        print("🔗 [Player] URL gerada → \(url.absoluteString)")

        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        req.setValue("MinasBH/1.0 (iOS)", forHTTPHeaderField: "User-Agent")

        runOnMain {
            self.webView.load(req)

            // roda "fix" múltiplas vezes (alguns sites criam o iframe tardiamente)
            let kicks: [TimeInterval] = [0.20, 0.80, 1.60, 2.50]
            for t in kicks {
                DispatchQueue.main.asyncAfter(deadline: .now() + t) { [weak self] in
                    self?.fixAndPlayYouTubeIframes()
                }
            }
        }
    }

    func play(videoID: String, displayKey: String? = nil) {
        NotificationCenter.default.post(name: .appShouldStopRadio, object: nil)

        activateAudioSession()
        attachHiddenContainerIfNeeded()
        stop()

        DispatchQueue.main.async {
            self.currentKey = displayKey ?? videoID
            self.isPlaying = true
            self.isLoading = true
        }

        let embedURL = "\(legacyBaseEmbed)/\(videoID)?autoplay=1&playsinline=1&enablejsapi=1&controls=0&rel=0&modestbranding=1&mute=1"
        print("▶️ [Player] embed direto: \(embedURL)")

        runOnMain {
            self.loadDirectEmbed(videoID: videoID)
            let kicks: [TimeInterval] = [0.20, 0.80, 1.60]
            for t in kicks {
                DispatchQueue.main.asyncAfter(deadline: .now() + t) { [weak self] in
                    self?.forcePlayUnmute()
                }
            }
        }

        if hasRecentUserGesture {
            forcePlayUnmute()
            hasRecentUserGesture = false
        }
    }

    func pause() {
        let js = """
        (function(){
          try{
            const ifr = document.querySelector('iframe[src*="youtube"]');
            if (ifr && ifr.contentWindow) {
              ifr.contentWindow.postMessage(JSON.stringify({"event":"command","func":"pauseVideo","args":[]}), '*');
            }
            const v = document.querySelector('video');
            if (v) v.pause();
          }catch(e){}
        })();
        """
        runOnMain {
            self.webView.evaluateJavaScript(js, completionHandler: nil)
            self.isPlaying = false
        }
    }

    func resume() {
        activateAudioSession()
        forcePlayUnmute()
        DispatchQueue.main.async { self.isPlaying = true }
    }

    func stop() {
        let js = """
        (function(){
          try{
            const ifr = document.querySelector('iframe[src*="youtube"]');
            if (ifr && ifr.contentWindow) {
              ifr.contentWindow.postMessage(JSON.stringify({"event":"command","func":"stopVideo","args":[]}), '*');
            }
            const v = document.querySelector('video');
            if (v) { v.pause(); v.removeAttribute('src'); if (v.load) v.load(); }
            document.body.innerHTML = '';
          }catch(e){}
        })();
        """
        runOnMain {
            self.webView.evaluateJavaScript(js, completionHandler: nil)
            self.webView.loadHTMLString("<html><body></body></html>", baseURL: nil)
            self.isPlaying = false
            self.isLoading = false
            self.currentKey = nil
        }
    }

    // MARK: - Helpers

    static func normalizedKey(artist: String, song: String) -> String {
        func norm(_ s: String) -> String {
            s.folding(options: .diacriticInsensitive, locale: .init(identifier: "pt_BR"))
             .lowercased()
             .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return norm(artist) + "|" + norm(song)
    }

    private func loadDirectEmbed(videoID: String) {
        let html = """
        <!DOCTYPE html><html><head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <style>html,body{margin:0;padding:0;background:transparent;}</style>
        </head><body>
          <div id="container" style="width:10px;height:10px;overflow:hidden;">
            <iframe id="player"
              src="https://www.youtube-nocookie.com/embed/\(videoID)?autoplay=1&playsinline=1&enablejsapi=1&controls=0&rel=0&modestbranding=1&mute=1"
              frameborder="0" allow="autoplay; encrypted-media" allowfullscreen
              style="width:10px;height:10px;"></iframe>
          </div>
          <script>
            function post(cmd){
              try{
                const ifr = document.getElementById('player');
                if (ifr && ifr.contentWindow) ifr.contentWindow.postMessage(JSON.stringify(cmd),'*');
              }catch(e){}
            }
            function play(){  post({"event":"command","func":"playVideo","args":[]}); }
            function pause(){ post({"event":"command","func":"pauseVideo","args":[]}); }
            function stop(){  post({"event":"command","func":"stopVideo","args":[]}); }
            function unmute(){ post({"event":"command","func":"unMute","args":[]}); post({"event":"command","func":"setVolume","args":[100]}); }
            setTimeout(play, 100);
          </script>
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }

    /// Roda dentro da SUA página (top document). Acha iframes do YouTube e garante enablejsapi/autoplay/unmute.
    private func fixAndPlayYouTubeIframes() {
        let origin = "https://radiointegration.ticketss.app"
        let js = """
        (function(){
          try{
            const ifrs = Array.from(document.querySelectorAll('iframe')).filter(i => /youtube\\.com|youtube-nocookie\\.com/.test(i.src||''));
            console.log('[iOS] iframes YouTube encontrados:', ifrs.length);
            if (ifrs.length === 0) { return 'NO_IFRAME'; }

            ifrs.forEach((ifr, idx) => {
              try{
                let src = new URL(ifr.src);
                // garante parametros chave
                src.searchParams.set('enablejsapi','1');
                src.searchParams.set('playsinline','1');
                src.searchParams.set('autoplay','1');
                src.searchParams.set('mute','0');
                // origin ajuda a API do player a aceitar postMessage
                src.searchParams.set('origin', '\(origin)');

                if (ifr.src !== src.toString()) {
                  console.log('[iOS] ajustando src do iframe #'+idx, '→', src.toString());
                  ifr.src = src.toString();
                }

                // Tenta tocar/desmutar via postMessage
                if (ifr.contentWindow) {
                  [
                    {"event":"command","func":"playVideo","args":[]},
                    {"event":"command","func":"unMute","args":[]},
                    {"event":"command","func":"setVolume","args":[100]}
                  ].forEach(c => ifr.contentWindow.postMessage(JSON.stringify(c), '*'));
                }
              }catch(e){ console.log('[iOS] erro no iframe:', e); }
            });

            // tenta também no <video> direto (alguns integradores usam tag <video>)
            const v = document.querySelector('video');
            if (v) { v.muted=false; v.volume=1.0; (v.play && v.play()); }

            return 'OK';
          }catch(e){ return 'ERR:' + e; }
        })();
        """
        runOnMain {
            self.webView.evaluateJavaScript(js) { result, _ in
                if let r = result as? String {
                    print("🧩 [Player] fixAndPlayYouTubeIframes → \(r)")
                }
            }
        }
    }

    private func forcePlayUnmute() {
        let js = """
        try{
          const ifr = document.querySelector('iframe[src*="youtube"]');
          if (ifr && ifr.contentWindow) {
            [
              {"event":"command","func":"playVideo","args":[]},
              {"event":"command","func":"unMute","args":[]},
              {"event":"command","func":"setVolume","args":[100]}
            ].forEach(c => ifr.contentWindow.postMessage(JSON.stringify(c), '*'));
          }
          const v = document.querySelector('video');
          if (v) { v.muted=false; v.volume=1.0; v.play && v.play(); }
        }catch(e){}
        """
        runOnMain { self.webView.evaluateJavaScript(js, completionHandler: nil) }
    }

    fileprivate func runOnMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread { block() } else { DispatchQueue.main.async(execute: block) }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("✅ [Player] didFinish → carregado: \(webView.url?.absoluteString ?? "about:blank")")
        DispatchQueue.main.async { self.isLoading = false }
        // roda o fix imediatamente ao terminar o load
        fixAndPlayYouTubeIframes()
        // e mais um reforço
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.forcePlayUnmute() }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ [Player] didFail: \(error.localizedDescription)")
        DispatchQueue.main.async { self.isLoading = false }
        failAndClearUI()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("❌ [Player] didFailProvisional: \(error.localizedDescription)")
        DispatchQueue.main.async { self.isLoading = false }
        failAndClearUI()
    }
}
