import AVFoundation
import SwiftUI
import Speech

/// SpeechManager:
/// - Fala um texto (feedback) e depois inicia escuta (se configurado)
/// - Escuta comandos simples: "tocar/play/continuar" e "parar/pausar/pause"
/// - Garante permissões de Speech + Microfone
/// - Ajusta AVAudioSession para funcionar junto com rádio (duckOthers)
final class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {

    // MARK: - Public state
    @Published private(set) var isSpeaking  = false
    @Published private(set) var isPaused    = false
    @Published var isListening = false
    @Published var lastCommand = ""

    // MARK: - Internal
    private let synthesizer = AVSpeechSynthesizer()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    /// Callback para sua View controlar play/pause
    var onCommandAction: ((String) -> Void)?

    private var shouldListenAfterSpeaking = false
    private var isStartingListening = false // evita duplo start em toques rápidos

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    deinit {
        stopListening()
    }

    // MARK: - Integration

    /// Executa o fluxo completo: fala os metadados (se feedback ativo) e depois escuta
    func speakAndListen(metadata: String) {
        let feedbackEnabled      = UserDefaults.standard.bool(forKey: "feedbackSounds")
        let voiceCommandsEnabled = UserDefaults.standard.bool(forKey: "voiceCommands")

        guard voiceCommandsEnabled else {
            print("SpeechManager: Comandos de voz desativados (voiceCommands=false).")
            return
        }

        if feedbackEnabled {
            shouldListenAfterSpeaking = true
            speakText(metadata)
        } else {
            startListening()
        }
    }

    // MARK: - Text to Speech

    func toggleSpeak(_ text: String) {
        let feedbackEnabled = UserDefaults.standard.bool(forKey: "feedbackSounds")
        guard feedbackEnabled else { return }

        if isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
        } else if isPaused {
            synthesizer.continueSpeaking()
        } else {
            speakText(text)
        }
    }

    func speakText(_ text: String) {
        let feedbackEnabled = UserDefaults.standard.bool(forKey: "feedbackSounds")
        guard feedbackEnabled else { return }

        synthesizer.stopSpeaking(at: .immediate)

        let utt = AVSpeechUtterance(string: text)
        utt.voice = AVSpeechSynthesisVoice(language: "pt-BR")
        utt.rate  = AVSpeechUtteranceDefaultSpeechRate

        synthesizer.speak(utt)
    }

    // MARK: - Speech Recognition (Public)

    func startListening() {
        // Toggle behavior
        if isListening {
            stopListening()
            return
        }

        if isStartingListening {
            print("SpeechManager: startListening ignorado (já iniciando).")
            return
        }
        isStartingListening = true

        // Evita eco se estiver falando
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        requestPermissionsAndStart { [weak self] ok in
            guard let self else { return }
            self.isStartingListening = false

            guard ok else {
                DispatchQueue.main.async { self.isListening = false }
                return
            }

            do {
                try self.startRecording()
                DispatchQueue.main.async { self.isListening = true }
            } catch {
                print("SpeechManager: Erro ao iniciar gravação:", error.localizedDescription)
                DispatchQueue.main.async { self.isListening = false }
            }
        }
    }

    func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        // remove tap com segurança
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        // Volta para playback (rádio)
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .default, options: [])
        try? audioSession.setActive(true)

        DispatchQueue.main.async {
            self.isListening = false
        }
    }

    // MARK: - Permissions

    private func requestPermissionsAndStart(completion: @escaping (Bool) -> Void) {
        // 1) Speech permission
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                guard status == .authorized else {
                    print("SpeechManager: Speech NÃO autorizado. Status:", status)
                    completion(false)
                    return
                }

                // 2) Microphone permission
                AVAudioSession.sharedInstance().requestRecordPermission { micGranted in
                    DispatchQueue.main.async {
                        guard micGranted else {
                            print("SpeechManager: Microfone NEGADO.")
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
            }
        }
    }

    // MARK: - Recording Core

    private func startRecording() throws {
        // Cancela tarefa anterior
        recognitionTask?.cancel()
        recognitionTask = nil

        // Logs úteis
        let session = AVAudioSession.sharedInstance()
        print("🎙️ startRecording() chamado")
        print("🎙️ recordPermission:", session.recordPermission.rawValue)
        print("🎙️ category antes:", session.category.rawValue, "mode:", session.mode.rawValue)

        // Ajuste ideal para voz + rádio
        try session.setCategory(.playAndRecord,
                                mode: .voiceChat,
                                options: [.defaultToSpeaker, .allowBluetooth, .duckOthers])

        try session.setActive(true, options: .notifyOthersOnDeactivation)

        // Request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        // Engine input
        let inputNode = audioEngine.inputNode

        // IMPORTANTE: use inputFormat (mais estável)
        let recordingFormat = inputNode.inputFormat(forBus: 0)

        // Remove tap anterior e instala novo
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0,
                             bufferSize: 1024,
                             format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        // Task
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            var isFinal = false

            if let result = result {
                let text = result.bestTranscription.formattedString.lowercased()
                print("SpeechManager: Detectado:", text)

                // Guarda último comando (opcional)
                DispatchQueue.main.async { self.lastCommand = text }

                // Comandos simples
                if text.contains("parar") || text.contains("pausar") || text.contains("pause") {
                    self.onCommandAction?("parar")
                    self.stopListening()
                } else if text.contains("tocar") || text.contains("play") || text.contains("continuar") {
                    self.onCommandAction?("tocar")
                    self.stopListening()
                }

                isFinal = result.isFinal
            }

            if let error = error {
                print("SpeechManager: erro recognitionTask:", error.localizedDescription)
            }

            if error != nil || isFinal {
                self.cleanupAfterRecognition()
            }
        }
    }

    private func cleanupAfterRecognition() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil

        DispatchQueue.main.async { self.isListening = false }

        // Volta sessão pra playback
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
            self.isPaused = false
        }
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.isPaused = false

            if self.shouldListenAfterSpeaking {
                self.shouldListenAfterSpeaking = false
                self.startListening()
            }
        }
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.isPaused = true
        }
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
            self.isPaused = false
        }
    }
}
