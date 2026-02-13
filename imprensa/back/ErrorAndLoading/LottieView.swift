import SwiftUI
import Lottie

final class LottieControlCenter: ObservableObject {
    @Published var pauseAll: Bool = false {
        didSet {
            // Salva o estado quando mudar (mas não durante a inicialização)
            if !_isInitializing {
                // pauseAll = true significa animações desativadas
                // pauseAll = false significa animações ativadas
                UserDefaults.animationsEnabled = !pauseAll
                print("🎨 [LottieControlCenter] pauseAll alterado para: \(pauseAll), animationsEnabled salvo como: \(!pauseAll)")
            }
        }
    }
    
    private var _isInitializing = true
    
    init() {
        // Carrega o estado salvo ao inicializar
        // Se animationsEnabled = true, então pauseAll = false (animações ativas)
        // Se animationsEnabled = false, então pauseAll = true (animações pausadas)
        let savedValue = UserDefaults.animationsEnabled
        pauseAll = !savedValue
        print("🎨 [LottieControlCenter] Inicializado - animationsEnabled carregado: \(savedValue), pauseAll definido como: \(pauseAll)")
        _isInitializing = false
    }
}

struct LottieView: UIViewRepresentable {
    var animationName: String
    var loopMode: LottieLoopMode = .loop
    var contentMode: UIView.ContentMode = .scaleAspectFit
    var participatesInGlobalPause: Bool = true
    /// Se true, este Lottie fica estático (1º frame), independente do global
    var forcePaused: Bool = false

    @EnvironmentObject private var lottieControl: LottieControlCenter

    final class Coordinator {
        let container = UIView()
        let animationView = LottieAnimationView()
        var appliedAnimationName: String?
        /// último “modo estático” aplicado; usamos para saber quando sair do estático e reiniciar do zero
        var lastStaticMode: Bool?

        init() {
            animationView.translatesAutoresizingMaskIntoConstraints = false
            animationView.isUserInteractionEnabled = false
            container.addSubview(animationView)
            NSLayoutConstraint.activate([
                animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                animationView.topAnchor.constraint(equalTo: container.topAnchor),
                animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let av = context.coordinator.animationView
        configure(av, coordinator: context.coordinator)
        applyPlaybackState(av, coordinator: context.coordinator, force: true)
        return context.coordinator.container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let av = context.coordinator.animationView

        // recarrega animação se o nome mudou (Lottie v4 não expõe "name")
        if context.coordinator.appliedAnimationName != animationName {
            av.animation = LottieAnimation.named(animationName)
            context.coordinator.appliedAnimationName = animationName
            // ao trocar de animação, se não estiver em estático, começa do zero
            if !currentStaticMode() {
                av.stop()
                av.currentProgress = 0
            } else {
                // se estático, garante 1º frame
                av.stop()
                av.currentProgress = 0
            }
        }

        if av.loopMode != loopMode { av.loopMode = loopMode }
        if av.contentMode != contentMode { av.contentMode = contentMode }

        applyPlaybackState(av, coordinator: context.coordinator)
    }

    // MARK: - Helpers

    private func configure(_ av: LottieAnimationView, coordinator: Coordinator) {
        av.animation = LottieAnimation.named(animationName)
        coordinator.appliedAnimationName = animationName
        av.loopMode = loopMode
        av.contentMode = contentMode
    }

    private func currentStaticMode() -> Bool {
        (participatesInGlobalPause && lottieControl.pauseAll) || forcePaused
    }

    /// Regra “modo estático” sem mudar chamadas:
    /// - static == true  -> para e mostra 1º frame
    /// - static == false -> se antes era estático, REINICIA do zero e toca
    private func applyPlaybackState(_ av: LottieAnimationView,
                                    coordinator: Coordinator,
                                    force: Bool = false) {
        let staticMode = currentStaticMode()

        DispatchQueue.main.async {
            // Se nada mudou e não é forçado, sai
            if coordinator.lastStaticMode == staticMode && !force { return }
            defer { coordinator.lastStaticMode = staticMode }

            if staticMode {
                // “modo estático”: parar e ir ao primeiro frame
                av.stop()
                av.currentProgress = 0.0
            } else {
                // saindo do estático ou primeira aplicação: recomeça do zero e toca
                av.stop()
                av.currentProgress = 0.0
                av.play(fromProgress: 0, toProgress: 1, loopMode: av.loopMode, completion: nil)
            }
        }
    }
}
