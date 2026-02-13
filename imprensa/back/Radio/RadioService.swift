import Foundation
import MediaPlayer
import AVKit
import AVFoundation
import Combine
import UIKit

// User-Agent personalizado para o streaming
func makeStreamingUserAgent() -> String {
    let systemVersion = UIDevice.current.systemVersion
    let deviceModel = UIDevice.current.type.rawValue   // Dispositivo.swift
    
    let rawAppName =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "App"
    
    // 🔹 Remove acentos e normaliza
    let appName = rawAppName
        .folding(options: .diacriticInsensitive, locale: .current)
        .replacingOccurrences(of: "[^A-Za-z0-9 _.-]", with: "", options: .regularExpression)
    
    let appVersion =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        ?? "1.0"
    
    return "APPRADIO.PRO / MOBILE APP / iOS \(systemVersion) / \(deviceModel) / APP: \(appName) / Versao: \(appVersion)"
}


struct RadioModel: Codable, Identifiable {
    let id = UUID()
    public var streamUrl: String
    
    enum CodingKeys: String, CodingKey {
        case streamUrl = "url"
    }
}

struct ItunesSearchResponse: Codable {
    let results: [ItunesTrack]
}

struct ItunesTrack: Codable {
    let artworkUrl100: String
}



class RadioPlayer: NSObject, ObservableObject {
    @Published var itemArtist: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Radio Eldorado BA"
    @Published var itemMusic: String = "Há mais de 7 anos no ar!"
    @Published var albumArtwork: UIImage? = UIImage(named: "live") 
    @Published private(set) var isPlaying: Bool = false
    @Published var isLoading: Bool = false
    @Published var currentRadio: RadioModel? = nil
    @Published var showAlertConnect: Bool = false
    @Published var isConnected: Bool = true
    @Published var currentArtworkUrl: String? = nil
    @Published var volume: Float = 1.0 {
        didSet {
            player?.volume = volume
        }
    }
    
    let streamingURL: URL
    var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var playerItemContext = 0
    private var observedPlayer: AVPlayer?
    
    let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 512.0, height: 512.0)) { size in
        let image = UIImage(imageLiteralResourceName: "live")
        return UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    init(streamingURL: URL) {
        self.streamingURL = streamingURL
        
        // Player inicial com User-Agent
        self.playerItem = RadioPlayer.makePlayerItem(with: streamingURL)
        self.player = AVPlayer(playerItem: playerItem)
        super.init()
        
        let metaOutput = AVPlayerItemMetadataOutput(identifiers: nil)
        metaOutput.setDelegate(self, queue: DispatchQueue.main)
        self.playerItem?.add(metaOutput)
        
        // Adiciona observador inicial
        self.player?.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: &playerItemContext)
        self.observedPlayer = self.player
    }
    
    deinit {
        if let p = observedPlayer {
            p.removeObserver(self, forKeyPath: "timeControlStatus", context: &playerItemContext)
        }
        NotificationCenter.default.removeObserver(self)
        NetworkReachability.shared.reachabilityObserver = nil
    }

    /// Cria um AVPlayerItem com o User-Agent personalizado
    private static func makePlayerItem(with url: URL) -> AVPlayerItem {
        let headers = ["User-Agent": makeStreamingUserAgent()]
        let options: [String: Any] = [
            // Chave interna usada pelo AVURLAsset para enviar headers HTTP
            "AVURLAssetHTTPHeaderFieldsKey": headers
        ]
        let asset = AVURLAsset(url: url, options: options)
        return AVPlayerItem(asset: asset)
    }
    
    func getVolume() -> Float {
        return player?.volume ?? 0.0
    }
    
    func setVolume(volume: Float) {
        player?.volume = volume
    }
    
    func initPlayer(url: URL) {
        // Se já temos um player com essa URL e ele está tocando, não reinicia
        if let currentURL = (player?.currentItem?.asset as? AVURLAsset)?.url, currentURL == url {
            if player?.timeControlStatus == .playing { return }
        }

        self.isLoading = true
                
        playerItem = RadioPlayer.makePlayerItem(with: url)
        
        let metaOutput = AVPlayerItemMetadataOutput(identifiers: nil)
        metaOutput.setDelegate(self, queue: DispatchQueue.main)
        playerItem?.add(metaOutput)
        
        // Remove observador antigo se existir de forma segura
        if let oldPlayer = observedPlayer {
            oldPlayer.removeObserver(self, forKeyPath: "timeControlStatus", context: &playerItemContext)
            observedPlayer = nil
        }
        
        player = AVPlayer(playerItem: playerItem)
        player?.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: &playerItemContext)
        observedPlayer = player
        setupNotifications()
        setupNowPlayingInfo(with: artwork)
        reachabilityObserver()
        setDefaultAlbumArtwork()
    }
    
    /// Observa as mudanças no status do player (tocar/loading)
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        DispatchQueue.main.async {
            switch self.player?.timeControlStatus {
            case .playing:
                self.isPlaying = true
                self.isLoading = false
            case .waitingToPlayAtSpecifiedRate:
                self.isPlaying = false
                self.isLoading = true
            case .paused:
                self.isPlaying = false
                self.isLoading = false
            default:
                break
            }
        }
    }
    
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleInterruption),
                                               name: AVAudioSession.interruptionNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleStopRequest),
                                               name: .appShouldStopRadio,
                                               object: nil)
    }

    @objc private func handleStopRequest() {
        DispatchQueue.main.async {
            self.stop()
            self.isPlaying = false
        }
    }
    
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {
            return
        }
        
        switch type {
        case .began:
            print("Interrupção iniciada")
            stop()
        case .ended:
            print("Interrupção finalizada")
            player?.play()
            if let interruptionOptionValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let interruptionOption = AVAudioSession.InterruptionOptions(rawValue: interruptionOptionValue)
                if interruptionOption == .shouldResume {
                    player?.play()
                }
            }
        @unknown default:
            break
        }
    }
    
    
    func playAudioBackground() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            setupCommandCenter()
        } catch {
            print("Erro ao configurar áudio para background: \(error)")
        }
    }
    
    
    private func setupCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        
        commandCenter.playCommand.addTarget { [weak self] event in
            self?.player?.play()
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.player?.pause()
            return .success
        }
    }
    
    func playToggle(with radio: RadioModel) {
        if self.isConnected {
            if self.isPlaying {
                stop()
            } else {
                self.currentRadio = radio
                if let url = URL(string: radio.streamUrl) {
                    initPlayer(url: url)
                    play(radio)
                }
            }
        } else {
            self.showAlertConnect = true
        }
    }
    
    func play(_ radio: RadioModel) {
        NotificationCenter.default.post(name: .appShouldStopExternalPlayer, object: nil)
        currentRadio = radio
        player?.volume = self.volume
        isLoading = true
        player?.play()
        playAudioBackground()
    }
    
    
    func stop() {
        player?.pause()
        self.isPlaying = false
        self.isLoading = false
    }
    
    /// Altera o volume (aumenta ou diminui) com um passo definido e fornece feedback háptico.
    func changeVolume(isIncreasing: Bool) {
        let volumeStep: Float = 0.1
        let currentVolume = getVolume()
        let newVolume: Float = isIncreasing ?
            min(currentVolume + volumeStep, 1.0) :
            max(currentVolume - volumeStep, 0.0)
        setVolume(volume: newVolume)
        provideHapticFeedback(isIncreasing: isIncreasing, volume: newVolume)
    }
    
    /// Gera feedback háptico de acordo com o ajuste do volume
    private func provideHapticFeedback(isIncreasing: Bool, volume: Float) {
        let style: UIImpactFeedbackGenerator.FeedbackStyle = {
            if isIncreasing {
                if volume < 0.33 { return .light }
                else if volume < 0.66 { return .medium }
                else { return .heavy }
            } else {
                if volume > 0.66 { return .heavy }
                else if volume > 0.33 { return .medium }
                else { return .light }
            }
        }()
        
        let feedbackGenerator = UIImpactFeedbackGenerator(style: style)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }
    
    func updateAlbumArtwork(from artist: String, track: String) {
        let query = "\(artist) \(track)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://itunes.apple.com/search?term=\(query)&entity=song&limit=1"
        
        guard let url = URL(string: urlString) else {
            setDefaultAlbumArtwork()
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Erro ao buscar capa no iTunes: \(error.localizedDescription)")
                self.setDefaultAlbumArtwork()
                return
            }
            
            guard let data = data else {
                self.setDefaultAlbumArtwork()
                return
            }
            
            do {
                let result = try JSONDecoder().decode(ItunesSearchResponse.self, from: data)
                if let artworkUrlString = result.results.first?.artworkUrl100 {
                    let highResUrl = artworkUrlString.replacingOccurrences(of: "100x100", with: "512x512")
                    DispatchQueue.main.async {
                        self.currentArtworkUrl = highResUrl
                    }
                    self.downloadAlbumArtwork(from: highResUrl)
                } else {
                    print("Nenhuma capa encontrada")
                    self.setDefaultAlbumArtwork()
                }
            } catch {
                print("Erro ao decodificar JSON: \(error.localizedDescription)")
                self.setDefaultAlbumArtwork()
            }
        }.resume()
    }

    private func downloadAlbumArtwork(from urlString: String) {
        guard let url = URL(string: urlString) else {
            print("URL inválida da capa")
            setDefaultAlbumArtwork()
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Erro ao baixar capa: \(error.localizedDescription)")
                self?.setDefaultAlbumArtwork()
                return
            }
            guard let data = data, let image = UIImage(data: data) else {
                self?.setDefaultAlbumArtwork()
                return
            }
            DispatchQueue.main.async {
                self?.albumArtwork = image
                print("✅ Capa do álbum atualizada com sucesso")
            }
        }.resume()
    }

    private func setDefaultAlbumArtwork() {
        DispatchQueue.main.async {
            self.albumArtwork = UIImage(named: "live")
        }
    }

    
    
    func reachabilityObserver() {
        NetworkReachability.shared.reachabilityObserver = { [weak self] status in
            DispatchQueue.main.async {
                self?.isConnected = (status == .connected)
                if status == .connected,
                   let radio = self?.currentRadio,
                   let streamUrl = URL(string: radio.streamUrl) {
                    self?.isPlaying = true
                    self?.initPlayer(url: streamUrl)
                } else {
                    self?.isPlaying = false
                    self?.player?.pause()
                }
            }
        }
    }
    
    
    
    
    
    /// Obtém uma imagem a partir de uma URL.
    func getImageFromURL(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                completion(UIImage(data: data))
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    func setupNowPlayingInfo(with artwork: MPMediaItemArtwork) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: self.itemArtist,
            MPMediaItemPropertyArtist: self.itemMusic,
            MPMediaItemPropertyArtwork: artwork,
            MPMediaItemPropertyPlaybackDuration: 0,
            MPNowPlayingInfoPropertyIsLiveStream: true
        ]
    }
}

extension RadioPlayer: AVPlayerItemMetadataOutputPushDelegate {
    func metadataOutput(_ output: AVPlayerItemMetadataOutput,
                        didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup],
                        from track: AVPlayerItemTrack?) {
        if let item = groups.first?.items.first {
            let metadataValue = item.stringValue ?? ""
            print("Metadados recebidos: \(metadataValue)")
            
            if metadataValue.contains(" - ") {
                let arMetadata = metadataValue.components(separatedBy: " - ")
                self.itemArtist = arMetadata[0].trimmingCharacters(in: .whitespacesAndNewlines)
                self.itemMusic = arMetadata.count > 1 ? arMetadata[1].trimmingCharacters(in: .whitespacesAndNewlines) : self.itemMusic
                updateAlbumArtwork(from: self.itemArtist, track: self.itemMusic)
            }
            
            setupNowPlayingInfo(with: artwork)
        }
    }
}



