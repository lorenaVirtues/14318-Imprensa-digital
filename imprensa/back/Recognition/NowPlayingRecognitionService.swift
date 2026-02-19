import Foundation

/// Serviço que roda periodicamente enquanto a rádio toca e tenta identificar a música via API Shazam.
@MainActor
final class NowPlayingRecognitionService: ObservableObject {
    @Published private(set) var isRecognizing: Bool = false
    @Published private(set) var lastError: String? = nil
    @Published private(set) var lastAttemptAt: Date? = nil
    @Published private(set) var lastSuccessAt: Date? = nil
    @Published private(set) var lastFailureAt: Date? = nil
    @Published private(set) var lastTitle: String? = nil
    @Published private(set) var lastArtist: String? = nil

    var minIntervalSeconds: TimeInterval = 60
    var sampleDurationSeconds: TimeInterval = 10

    private weak var radioPlayer: RadioPlayer?
    private var loopTask: Task<Void, Never>?
    private let shazamKit = ShazamKitManager()
    private var backoffSeconds: TimeInterval = 0
    private var lastAppliedKey: String? = nil
    private var lastURL: URL? = nil

    // Placeholders “originais” do app (antes do reconhecimento via Shazam).
    private let placeholderArtist = "Tocando agora"
    private let placeholderTitle = "Rádio Morrinhos"

    func attach(radioPlayer: RadioPlayer) {
        self.radioPlayer = radioPlayer
    }

    func start() {
        guard loopTask == nil else { return }
        loopTask = Task { [weak self] in
            await self?.loop()
        }
    }

    func stop() {
        loopTask?.cancel()
        loopTask = nil
    }

    private func loop() async {
        while !Task.isCancelled {
            // tick a cada 1s, mas só executa quando necessário
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000)
            } catch {
                break
            }

            guard let rp = radioPlayer else { continue }
            guard rp.isPlaying else { continue }
            if isRecognizing { continue }

            // Respeita intervalos + backoff (a menos que a rádio tenha mudado)
            let now = Date()
            let currentURL = URL(string: rp.currentRadio?.streamUrl ?? "")
            
            if currentURL != lastURL {
                // Radio mudou, reseta o timer para identificar logo
                lastSuccessAt = nil
                lastURL = currentURL
                print("[NowPlayingRecognitionService] Radio station changed, resetting recognition timer")
            }

            if let last = lastSuccessAt, now.timeIntervalSince(last) < minIntervalSeconds {
                continue
            }
            if backoffSeconds > 0, let last = lastFailureAt, now.timeIntervalSince(last) < backoffSeconds {
                continue
            }

            await recognizeOnce()
        }
    }

    private func recognizeOnce() async {
        guard let rp = radioPlayer else { return }

        // Pega o stream atual
        guard let streamString = rp.currentRadio?.streamUrl.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
              let streamURL = URL(string: streamString) else {
            return
        }

        isRecognizing = true
        lastError = nil
        defer { isRecognizing = false }

        let start = Date()
        lastAttemptAt = start
        let ua = makeStreamingUserAgent()

        do {
            let snippet = try await StreamSnippetRecorder.capture(
                from: streamURL,
                durationSeconds: sampleDurationSeconds,
                userAgent: ua
            )

            // 1) Normaliza para WAV (Obrigatório para o ShazamKit ler o buffer PCM)
            let uploadURL: URL
            do {
                uploadURL = try await AudioNormalizer.normalizeToWavIfPossible(inputURL: snippet.fileURL)
            } catch {
                print("[Recognizer] normalize failed, cannot use ShazamKit: \(error.localizedDescription)")
                // Tenta fallback para a API antiga com o arquivo bruto se possível
                try await fallbackRecognition(fileURL: snippet.fileURL, rp: rp, start: start)
                return
            }

            // 2) Tenta via ShazamKit (Oficial Apple)
            do {
                let result = try await shazamKit.recognize(audioURL: uploadURL)
                applyResult(title: result.title, artist: result.artist, source: .shazam, rp: rp, start: start)
            } catch {
                print("[Recognizer] ShazamKit failed: \(error.localizedDescription). Trying fallback API with M4A...")
                
                // Fallback: Transcodifica para M4A (AAC) que é mais leve e aceito pela API virtues.now
                do {
                    let fallbackURL = try await AudioNormalizer.normalizeToM4A(inputURL: snippet.fileURL)
                    try await fallbackRecognition(fileURL: fallbackURL, rp: rp, start: start)
                } catch {
                    print("[Recognizer] M4A fallback transcode failed: \(error.localizedDescription)")
                    // Se falhar o transcode, tenta com o arquivo original como última esperança
                    try await fallbackRecognition(fileURL: snippet.fileURL, rp: rp, start: start)
                }
            }
            
        } catch {
            handleError(error)
        }
    }
    
    private func fallbackRecognition(fileURL: URL, rp: RadioPlayer, start: Date) async throws {
        let result = try await ShazamAPIClient.recognize(audioFileURL: fileURL)
        applyResult(title: result.title, artist: result.artist, source: .shazam, rp: rp, start: start)
    }
    
    private func applyResult(title: String, artist: String, source: RadioPlayer.MetadataSource, rp: RadioPlayer, start: Date) {
        lastSuccessAt = Date()
        lastTitle = title
        lastArtist = artist
        backoffSeconds = 0
        
        print("[Recognizer] ✅ identified=\(artist) - \(title) time=\(String(format: "%.2f", Date().timeIntervalSince(start)))s")
        rp.updateMetadata(artist: artist, music: title, source: source)
    }
    
    private func handleError(_ error: Error) {
        lastFailureAt = Date()
        
        if case ShazamAPIClient.ClientError.noMatch(let retryMs) = error {
            let retrySeconds = max(5, TimeInterval((retryMs ?? 7000)) / 1000.0)
            backoffSeconds = retrySeconds
            lastError = "Sem correspondência"
            print("[Recognizer] ⚠️ no match, retry in \(Int(ceil(retrySeconds)))s")
            return
        }
        
        lastError = error.localizedDescription
        backoffSeconds = min(max(backoffSeconds * 2, 60), 10 * 60)
        print("[Recognizer] ❌ failed: \(error.localizedDescription) backoff=\(backoffSeconds)s")
    }
}

