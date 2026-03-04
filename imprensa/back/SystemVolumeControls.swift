//
//  SystemVolumeControls.swift
//
//  Controle de Volume do Sistema (iPhone/iPad)
//  Implementação oficial baseada em MPVolumeView (Apple)
//
//  IMPORTANTE:
//  - NÃO é possível alterar o volume do aparelho diretamente por API.
//  - É permitido permitir que o USUÁRIO controle o volume via MPVolumeView.
//  - Este arquivo encapsula essa solução de forma modular.
//
//  Componentes incluídos:
//  1) SystemVolume -> Observa o volume REAL do aparelho (0...1)
//  2) SystemVolumeMPDriver -> Ponte oficial para MPVolumeView
//  3) SystemVolumeSlider -> Slider visual custom + driver oficial
//  4) SystemVolumeDecreaseButton -> Botão "-" separado
//  5) SystemVolumeIncreaseButton -> Botão "+" separado
//  6) SystemVolumeControl -> Componente completo pronto para uso
//  7) SystemVolumeRoutePicker -> Botão oficial AirPlay/Bluetooth
//

import SwiftUI
import AVFAudio
import MediaPlayer
import Combine

// MARK: - 1) Observador do Volume REAL do Sistema

@MainActor
public final class SystemVolume: ObservableObject {

    /// Valor real do volume do aparelho (0...1)
    /// Atualiza quando usuário usa:
    /// - Botões físicos
    /// - Central de Controle
    /// - MPVolumeView
    @Published public var value: Double =
        Double(AVAudioSession.sharedInstance().outputVolume)

    private var observation: NSKeyValueObservation?

    /// Inicializa o observador.
    /// - activateAudioSession: ativa sessão de áudio para garantir leitura correta.
    public init(activateAudioSession: Bool = true) {
        if activateAudioSession {
            Self.ensureAudioSessionActive()
        }

        let session = AVAudioSession.sharedInstance()

        observation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            guard let self, let newValue = change.newValue else { return }
            Task { @MainActor in
                self.value = Double(newValue)
            }
        }
    }

    deinit {
        observation?.invalidate()
    }

    /// Garante que a sessão de áudio esteja ativa.
    /// Recomendado chamar no onAppear da tela principal.
    public static func ensureAudioSessionActive() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .allowBluetooth]
            )
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch {
            print("⚠️ Erro ao ativar AVAudioSession: \(error)")
        }
    }
}


// MARK: - 2) Driver Oficial (MPVolumeView)

/// Esta é a parte mais importante.
/// MPVolumeView é o controle OFICIAL da Apple para alterar volume.
///
/// Ele contém internamente um UISlider que realmente altera
/// o volume do sistema quando o usuário interage.
public struct SystemVolumeMPDriver: UIViewRepresentable {

    @Binding var value: Double

    /// Mostra botão de rota (AirPlay/Bluetooth)
    public var showsRouteButton: Bool

    /// Se verdadeiro, deixa o controle quase invisível,
    /// mas ainda funcional (interativo).
    public var isHiddenButInteractive: Bool

    public init(
        value: Binding<Double>,
        showsRouteButton: Bool = false,
        isHiddenButInteractive: Bool = true
    ) {
        self._value = value
        self.showsRouteButton = showsRouteButton
        self.isHiddenButInteractive = isHiddenButInteractive
    }

    public func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: .zero)
        view.showsVolumeSlider = true
        view.showsRouteButton = showsRouteButton

        // Captura o UISlider interno
        if let slider = view.subviews.compactMap({ $0 as? UISlider }).first {
            context.coordinator.slider = slider

            slider.minimumValue = 0
            slider.maximumValue = 1
            slider.value = Float(value)

            slider.addTarget(context.coordinator,
                             action: #selector(Coordinator.changed(_:)),
                             for: .valueChanged)

            if isHiddenButInteractive {
                slider.alpha = 0.02
            }
        }

        return view
    }

    public func updateUIView(_ uiView: MPVolumeView, context: Context) {
        // Quando o binding muda (ex: botão +/-),
        // empurra valor para o slider do sistema
        if let slider = context.coordinator.slider {
            let target = Float(value)
            if abs(slider.value - target) > 0.001 {
                slider.setValue(target, animated: false)
                slider.sendActions(for: .valueChanged)
            }
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(value: $value)
    }

    public final class Coordinator: NSObject {
        var value: Binding<Double>
        weak var slider: UISlider?

        init(value: Binding<Double>) {
            self.value = value
        }

        @objc func changed(_ sender: UISlider) {
            value.wrappedValue = Double(sender.value)
        }
    }
}


// MARK: - 3) Slider Visual Customizado

/// Slider visual com gradiente.
/// O MPVolumeView fica sobreposto invisível para alterar o volume real.
public struct SystemVolumeSlider: View {

    @Binding var value: Double
    public var height: CGFloat
    public var showPercentage: Bool

    public init(
        value: Binding<Double>,
        height: CGFloat = 14,
        showPercentage: Bool = false
    ) {
        self._value = value
        self.height = height
        self.showPercentage = showPercentage
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {

                    Capsule()
                        .fill(.gray.opacity(0.25))
                        .frame(height: height)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * value,
                               height: height)
                }
                .clipShape(Capsule())

                // Driver oficial invisível
                SystemVolumeMPDriver(value: $value)
                    .frame(width: geo.size.width, height: height)
            }
            .frame(height: height)

            if showPercentage {
                HStack {
                    Text("\(Int(value * 100))%")
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                }
                .padding(.horizontal, 10)
            }
        }
    }
}


// MARK: - 4) Botão DIMINUIR Volume

public struct SystemVolumeDecreaseButton: View {

    @Binding var value: Double
    public var step: Double

    public init(
        value: Binding<Double>,
        step: Double = 0.0625
    ) {
        self._value = value
        self.step = step
    }

    public var body: some View {
        Button {
            value = max(0, value - step)
        } label: {
            Image(systemName: "speaker.fill")
                .font(.system(size: 18, weight: .semibold))
        }
        .accessibilityLabel("Diminuir volume")
    }
}


// MARK: - 5) Botão AUMENTAR Volume

public struct SystemVolumeIncreaseButton: View {

    @Binding var value: Double
    public var step: Double

    public init(
        value: Binding<Double>,
        step: Double = 0.0625
    ) {
        self._value = value
        self.step = step
    }

    public var body: some View {
        Button {
            value = min(1, value + step)
        } label: {
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 18, weight: .semibold))
        }
        .accessibilityLabel("Aumentar volume")
    }
}


// MARK: - 6) Componente Completo Pronto

public struct SystemVolumeControl: View {

    @StateObject private var systemVolume = SystemVolume()

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Volume do aparelho: \(Int(systemVolume.value * 100))%")
                .font(.headline)

            HStack(spacing: 12) {
                SystemVolumeDecreaseButton(value: $systemVolume.value)
                SystemVolumeIncreaseButton(value: $systemVolume.value)
                SystemVolumeSlider(value: $systemVolume.value)
            }
        }
        .onAppear {
            SystemVolume.ensureAudioSessionActive()
        }
    }
}


// MARK: - 7) Botão Oficial AirPlay / Bluetooth

public struct SystemVolumeRoutePicker: View {

    public init() {}

    public var body: some View {
        SystemVolumeMPDriver(
            value: .constant(Double(AVAudioSession.sharedInstance().outputVolume)),
            showsRouteButton: true,
            isHiddenButInteractive: false
        )
        .frame(width: 44, height: 44)
    }
}
