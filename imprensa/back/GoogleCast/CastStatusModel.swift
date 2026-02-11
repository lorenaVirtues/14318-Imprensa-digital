import Combine
import GoogleCast

final class CastSessionManager: ObservableObject {
    static let shared = CastSessionManager()

    @Published var isCasting: Bool = false
    @Published var isCastPlaying: Bool = false
    @Published var isCastingLoading: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let sessionManager = GCKCastContext.sharedInstance().sessionManager

    private init() {
        // Observe início/fim de sessão
        NotificationCenter.default.publisher(for: .castSessionDidStart)
            .sink { [weak self] _ in self?.handleCastStarted() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .castSessionEnded)
            .sink { [weak self] _ in self?.handleCastEnded() }
            .store(in: &cancellables)

        // Timer para playerState
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.updatePlayerState() }
            .store(in: &cancellables)
    }

    private func handleCastStarted() {
        isCasting = true
        updatePlayerState()
    }

    private func handleCastEnded() {
        isCasting = false
        isCastingLoading = false
    }

    private func updatePlayerState() {
        guard let session = sessionManager.currentCastSession,
              let playerState = session.remoteMediaClient?.mediaStatus?.playerState
        else {
            isCastingLoading = false
            return
        }
        isCastingLoading = (playerState == .buffering || playerState == .unknown)
        isCastPlaying    = (playerState == .playing)
    }
}
