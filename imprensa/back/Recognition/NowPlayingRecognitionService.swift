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
    private var backoffSeconds: TimeInterval = 0
    private var lastAppliedKey: String? = nil

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

            // Respeita intervalos + backoff
            let now = Date()
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
        guard let streamString = rp.currentRadio?.streamUrl.trimmingCharacters(in: .whitespacesAndNewlines),
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

            // 1) tenta normalizar (WAV/M4A). Se falhar, tenta enviar o raw mesmo (AAC/TS).
            let uploadURL: URL
            do {
                uploadURL = try await AudioNormalizer.normalizeToWavIfPossible(inputURL: snippet.fileURL)
            } catch {
                print("[Recognizer] normalize failed, uploading raw snippet: \(error.localizedDescription)")
                uploadURL = snippet.fileURL
            }

            let result = try await ShazamAPIClient.recognize(audioFileURL: uploadURL)
            lastSuccessAt = Date()
            lastTitle = result.title
            lastArtist = result.artist
            backoffSeconds = 0

            print("[Recognizer] ✅ recognized artist=\(result.artist) title=\(result.title) total=\(String(format: "%.2f", Date().timeIntervalSince(start)))s")

            // Atualiza metadados do player para a UI (somente se mudou)
            let newKey = "\(result.artist.lowercased())|\(result.title.lowercased())"
            if lastAppliedKey != newKey {
                lastAppliedKey = newKey
                rp.itemArtist = result.artist
                rp.itemMusic = result.title
                rp.updateAlbumArtwork(from: result.artist, track: result.title)
            }
        } catch {
            lastFailureAt = Date()

            // Se foi "sem match", não faz backoff exponencial. Respeita retryms do Shazam (normalmente 7000ms).
            if case ShazamAPIClient.ClientError.noMatch(let retryMs) = error {
                let retrySeconds = max(5, TimeInterval((retryMs ?? 7000)) / 1000.0)
                backoffSeconds = retrySeconds
                lastError = "Sem correspondência (tentando novamente em \(Int(ceil(retrySeconds)))s)"
                print("[Recognizer] ⚠️ no match, retry in \(Int(ceil(retrySeconds)))s")
                return
            }

            lastError = error.localizedDescription
            // backoff simples progressivo para falhas reais (rede/parse/etc)
            backoffSeconds = min(max(backoffSeconds * 2, 60), 10 * 60)
            print("[Recognizer] ❌ failed: \(error.localizedDescription) backoff=\(backoffSeconds)s")
        }
    }
}

