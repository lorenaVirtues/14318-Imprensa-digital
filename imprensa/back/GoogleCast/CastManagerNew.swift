import GoogleCast

class CastManager: NSObject, GCKSessionManagerListener, GCKRequestDelegate {
    static let shared = CastManager()
    private var videoStream: String = ""
    private var streamType: String = ""
    private let sessionManager: GCKSessionManager
    private var mediaInformation: GCKMediaInformation?
    
    override init() {
        sessionManager = GCKCastContext.sharedInstance().sessionManager
        super.init()
        sessionManager.add(self)
        NotificationCenter.default.addObserver(self,
                                                   selector: #selector(castDeviceDidChange),
                                               name: NSNotification.Name.gckCastStateDidChange,
                                                   object: sessionManager)
    }
    
    
        var isCasting: Bool {
            return sessionManager.currentSession != nil
        }

    func endCurrentSession() {
            sessionManager.endSessionAndStopCasting(true)
        }
        var remoteClient: GCKRemoteMediaClient? {
            return sessionManager.currentSession?.remoteMediaClient
        }
    
    func setVideoStream(_ video: String, _ type: String) {
        videoStream = video
        streamType = type
    }
    
    // Implement necessary methods for session management, device discovery, and media control.
    func disconnect() {
        sessionManager.endSessionAndStopCasting(true)
    }
    
    func loadMedia(with: GCKMediaInformation) {
        if let request = sessionManager.currentSession?.remoteMediaClient?.loadMedia(with) {
          request.delegate = self
        }
    }
    
    func startCasting(mediaTitle: String, mediaImageURL: URL) {
        let metadata = GCKMediaMetadata()
        metadata.setString(mediaTitle, forKey: kGCKMetadataKeyTitle)
        metadata.addImage(GCKImage(url: mediaImageURL,
                                   width: 480,
                                   height: 360))
        let url2 = URL.init(string: videoStream)
        guard let mediaURL = url2 else {
          print("invalid mediaURL")
          return
        }

        let mediaInfoBuilder = GCKMediaInformationBuilder.init(contentURL: mediaURL)
        mediaInfoBuilder.streamType = GCKMediaStreamType.none;
        mediaInfoBuilder.contentType = streamType
        mediaInfoBuilder.metadata = metadata;
        let mediaInformation = mediaInfoBuilder.build()
        loadMedia(with: mediaInformation)
    }
    
    @objc func castDeviceDidChange(notification: Notification) {
        print("dispositivo selecionado, iniciando transmissão")
        // Verifique se um dispositivo foi selecionado e comece o casting
        if let sessionManager = notification.object as? GCKSessionManager, sessionManager.currentCastSession != nil {
            // Aqui você pode chamar startCasting com os detalhes de mídia
            startCasting(mediaTitle: "Rádio Imprensa Digital", mediaImageURL: URL(string: "")!)
        }
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        print("Sessão de casting iniciada")
        // Inicie o casting aqui se necessário
        
        
        startCasting(mediaTitle: "Rádio Imprensa Digital", mediaImageURL: URL(string: "")!)
        
        DispatchQueue.main.async {
            // Reinicia o player local após a transmissão ser interrompida
            if let url = URL(string: self.videoStream) {
                NotificationCenter.default.post(name: .castSessionDidStart, object: url)
            }
        }
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        print("Sessão de casting terminada")

        DispatchQueue.main.async {
            // Reinicia o player local após a transmissão ser interrompida
            if let url = URL(string: self.videoStream) {
                NotificationCenter.default.post(name: .castSessionEnded, object: url)
            }
        }
    }
}


extension Notification.Name {
  static let castSessionEnded   = Notification.Name("castSessionEnded")
}

extension Notification.Name {
    static let castSessionDidStart = Notification.Name("castSessionDidStart")
}
