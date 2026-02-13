//
//  ConfigView.swift
//  imprensa
//
//  Created by Virtues25 on 12/02/26.
//

import SwiftUI

struct ConfigView: View {
    @EnvironmentObject var dataController: AppDataController
    @EnvironmentObject var radioPlayer: RadioPlayer
    @EnvironmentObject var router: NavigationRouter
    
    @AppStorage("isMinimalMode") private var isMinimalMode = false
    
    let height = UIScreen.main.bounds.size.height
    let width = UIScreen.main.bounds.size.width
    
    @AppStorage("autoplayEnabled") private var autoPlay = true
    @AppStorage("audioMono") private var audioMono = false
    @AppStorage("audioBalance") private var audioBalance: Double = 0.5
    
    @AppStorage("voiceCommands") private var voiceCommands = true
    @AppStorage("feedbackSounds") private var feedbackSounds = false
    @AppStorage("inactivityTime") private var inactivityTime: Double = 15
    
    @AppStorage("locationPermission") private var locationPermission = true
    @AppStorage("pairingPermission") private var pairingPermission = true
    @AppStorage("rotationEnabled") private var rotationEnabled = true
    
    @AppStorage("fontScale") private var fontScale: Double = 1.0
    @AppStorage("isBoldText") private var isBoldText = false
    @AppStorage("isSmallText") private var isSmallText = false
    
    @State private var showSaveAlert = false
    @State private var activeAlert: ConfigAlertType?

    private enum ConfigAlertType: Identifiable {
        case monoConfirm
        case voiceHelp
        case locationInfo
        case pairingInfo
        case generic(title: String, message: String)
        case advanced
        
        var id: String {
            switch self {
            case .monoConfirm: return "mono"
            case .voiceHelp: return "voice"
            case .locationInfo: return "location"
            case .pairingInfo: return "pairing"
            case .generic(let t, _): return t
            case .advanced: return "advanced"
            }
        }
    }
    
    
    var body: some View {
        GeometryReader{ geo in
            let isPortrait = geo.size.height > geo.size.width
            if isPortrait {
                portrait(geo: geo)
            } else {
                landscape(geo: geo)
            }
        }
        .alert(item: $activeAlert) { alertType in
            switch alertType {
            case .advanced:
                return Alert(
                    title: Text("Abrir Ajustes"),
                    message: Text("Você será redirecionado para o app Ajustes para configurar acessibilidade. Deseja continuar?"),
                    primaryButton: .default(Text("Ir para Ajustes"), action: {
                        openAppSettings()
                    }),
                    secondaryButton: .cancel(Text("Cancelar"))
                )
            case .monoConfirm:
                return Alert(
                    title: Text("Ativar Áudio Mono"),
                    message: Text("Para garantir o funcionamento ideal do modo Mono, ajuste também em: Ajustes → Acessibilidade → Áudio/Visual → Áudio Mono."),
                    primaryButton: .default(Text("Abrir Ajustes"), action: {
                        audioMono = true
                        openAppSettings()
                    }),
                    secondaryButton: .cancel(Text("Cancelar"), action: {
                        audioMono = false
                    })
                )
            case .locationInfo, .pairingInfo:
                let isLocation = if case .locationInfo = alertType { true } else { false }
                return Alert(
                    title: Text(isLocation ? "Desativar Localização" : "Desativar Pareamento"),
                    message: Text("Para desativar esta permissão, você deve acessar os Ajustes do seu aparelho e procurar pelas permissões de privacidade deste aplicativo."),
                    primaryButton: .default(Text("Ir para Ajustes"), action: {
                        openAppSettings()
                    }),
                    secondaryButton: .cancel(Text("OK"))
                )
            case .voiceHelp:
                return Alert(
                    title: Text("Comandos de Voz"),
                    message: Text("""
                    • “tocar”, “play” — inicia a rádio
                    • “pausar”, “parar” — pausa a rádio
                    • “menu” — abre o menu
                    • “configurações” — abre esta tela
                    • “voltar” — fecha a tela atual
                    """),
                    dismissButton: .default(Text("Entendi"))
                )
            case .generic(let title, let message):
                return Alert(
                    title: Text(title),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            default:
                return Alert(title: Text("Opção Alterada"))
            }
        }
        .alert("Configurações Salvas", isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Suas alterações foram aplicadas com sucesso.")
        }
        .onChange(of: autoPlay) { newValue in
            activeAlert = .generic(title: "Auto-Play", message: "Configuração de reprodução automática alterada para: \(newValue ? "Ativado" : "Desativado").")
        }
        .onChange(of: feedbackSounds) { newValue in
            activeAlert = .generic(title: "Sons de Feedback", message: "Sons de resposta alterados para: \(newValue ? "Ativado" : "Desativado").")
        }
        .onChange(of: rotationEnabled) { enabled in
            if !enabled { forcePortraitNow() }
            refreshOrientationSupport()
            activeAlert = .generic(title: "Rotação de Tela", message: "Orientação de tela configurada para: \(enabled ? "Livre" : "Travada em Retrato").")
        }
        .onChange(of: isBoldText) { newValue in
            activeAlert = .generic(title: "Texto em Negrito", message: "Destaque de fonte alterado para: \(newValue ? "Ativado" : "Desativado").")
        }
    }
    
    private func refreshOrientationSupport() {
        DispatchQueue.main.async {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first,
               let root = window.rootViewController {

                if #available(iOS 16.0, *) {
                    root.setNeedsUpdateOfSupportedInterfaceOrientations()
                } else {
                    UIViewController.attemptRotationToDeviceOrientation()
                }
            }
        }
    }
    
    private func forcePortraitNow() {
        if #available(iOS 16.0, *) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                try? scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        }
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    @ViewBuilder
    private func portrait(geo: GeometryProxy) -> some View {
        ZStack {
            Color.white
                .ignoresSafeArea(.all)
            
            VStack{
                HStack{
                    if isMinimalMode {
                        Image("logo")
                              .resizable()
                              .scaledToFit()
                              .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? geo.size.width * 0.55 : geo.size.width * 0.4, height: geo.size.height * 0.12)
                              .border(Color.yellow)
                    } else {
                        LottieView(animationName: "logotipo")
                            .scaledToFit()
                            .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? geo.size.width * 0.55 : geo.size.width * 0.4, height: geo.size.height * 0.12)
                            .scaleEffect(2.0)
                    }
                     
                    
                    Spacer()
                    
                    HeaderDateTimeView()
                }
                .padding(20)
               
                Divider()
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                
                HStack{
                    Button(action:{
                        router.goHome()
                    }, label:{
                        Image("btn_nav_home_default")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.1, height: geo.size.height * 0.05)
                            
                    })
                   
                    Spacer()
                    
                    Button(action:{
                        router.go(to: .audio)
                    }, label:{
                        Image("btn_nav_audio_player_default")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.1, height: geo.size.height * 0.05)
                            
                    })
                    
                    Spacer()
                    
                    Image("btn_nav_settings_active")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width * 0.3, height: geo.size.height * 0.05)
                        
                    
                    Spacer()
                    
                    Button(action:{
                        router.go(to: .menu)
                    }, label:{
                        Image("btn_nav_menu_default")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.1, height: geo.size.height * 0.05)
                            
                    })
                    
                    Spacer()
                    
                    Image("bg_triangle_nav_buttons")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width * 0.07, height: geo.size.height * 0.05)
                        
                }
                .padding(.leading, 20)
                
                Divider()
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 15) {
                        // ÁUDIO Section
                        ConfigSection(title: "ÁUDIO") {
                            VStack(spacing: 0) {
                                ConfigToggle(title: "Auto-Play", subtitle: "Áudio inicia automaticamente ao abrir o aplicativo.", icon: "icone_auto_play", isOn: $autoPlay)
                                Divider().padding(.horizontal)
                                
                                ConfigToggle(title: "Áudio Mono", subtitle: "Alto-falantes esquerdo e direito tocam o mesmo áudio.", icon: "icone_audio_mono", isOn: Binding(
                                    get: { audioMono },
                                    set: { newValue in
                                        if newValue {
                                            activeAlert = .monoConfirm
                                        } else {
                                            audioMono = false
                                        }
                                    }
                                ))
                                Divider().padding(.horizontal)
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Image("icone_balanco_de_audio")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 25)
                                        
                                        Text("• Balanço de Áudio")
                                            .appFont(weight: .bold, size: 14)
                                            .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                                    }
                                    
                                    CustomSlider(value: $audioBalance, range: 0...1, onEnded: {
                                        activeAlert = .generic(title: "Balanço de Áudio", message: "Você também pode ajustar o balanço do sistema em Ajustes do aparelho.")
                                    })
                                    
                                    HStack {
                                        Text("Esquerdo")
                                        Spacer()
                                        Text("Direito")
                                    }
                                    .font(.custom("Spartan-Regular", size: 10))
                                    .foregroundColor(.gray)
                                }
                                .padding()
                            }
                        }
                        
                        Divider()
                            .foregroundColor(.gray)
                            .padding(.vertical, 10)
                        
                        // COMANDOS DE VOZ Section
                        ConfigSection(title: "COMANDOS DE VOZ") {
                            VStack(spacing: 0) {
                                ConfigToggle(title: "Comandos", subtitle: "Ativa a navegação por comandos de voz.", icon: "icone_comandos", isOn: Binding(
                                    get: { voiceCommands },
                                    set: { newValue in
                                        voiceCommands = newValue
                                        if newValue { activeAlert = .voiceHelp } else {
                                            activeAlert = .generic(title: "Comandos de Voz", message: "Navegação por voz desativada.")
                                        }
                                    }
                                ))
                                Divider().padding(.horizontal)
                                ConfigToggle(title: "Sons de Feedback", subtitle: "Toca sons ao ativar o microfone, ao dar resultado de comandos ou erros.", icon: "icone_sons_de_feedback", isOn: $feedbackSounds)
                                Divider().padding(.horizontal)
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Image("icone_inatiivdade")
                                            .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                                        Text("• Inatividade")
                                            .font(.custom("Spartan-Bold", size: 14))
                                            .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                                    }
                                    
                                    Text("Expira se não houver fala. Defina o tempo (segundos) abaixo.")
                                        .font(.custom("Spartan-Regular", size: 12))
                                        .foregroundColor(.gray)
                                    
                                    CustomSlider(value: $inactivityTime, range: 5...30)
                                    
                                    HStack {
                                        Text("05")
                                        Spacer()
                                        Text("10")
                                        Spacer()
                                        Text("15")
                                        Spacer()
                                        Text("20")
                                        Spacer()
                                        Text("25")
                                        Spacer()
                                        Text("30")
                                    }
                                    .font(.custom("Spartan-Regular", size: 10))
                                    .foregroundColor(.gray)
                                }
                                .padding()
                            }
                        }
                        
                        Divider()
                            .foregroundColor(.gray)
                            .padding(.vertical, 10)
                        
                        // PERMISSÕES Section
                        ConfigSection(title: "PERMISSÕES") {
                            VStack(spacing: 0) {
                                ConfigToggle(title: "Localização", subtitle: "Previsão do tempo e hora com base na sua localização atual.", icon: "icone_localizacao", isOn: Binding(
                                    get: { locationPermission },
                                    set: { newValue in
                                        if !newValue {
                                            activeAlert = .locationInfo
                                        } else {
                                            locationPermission = true
                                        }
                                    }
                                ))
                                Divider().padding(.horizontal)
                                ConfigToggle(title: "Pareamento", subtitle: "Busca dispositivos (Bluetooth e Chromecast) para transmitir", icon: "icone_pareamento", isOn: Binding(
                                    get: { pairingPermission },
                                    set: { newValue in
                                        if !newValue {
                                            activeAlert = .pairingInfo
                                        } else {
                                            pairingPermission = true
                                        }
                                    }
                                ))
                            }
                        }
                        
                        Divider()
                            .foregroundColor(.gray)
                            .padding(.vertical, 10)
                        
                        // APARÊNCIA Section
                        ConfigSection(title: "APARÊNCIA") {
                            ConfigToggle(title: "Animações", subtitle: "Ativa as animações do layout.", icon: "icone_animacoes", isOn: Binding(
                                get: { !dataController.minimalMode },
                                set: { dataController.minimalMode = !$0 }
                            ))
                        }
                        
                        Divider()
                            .foregroundColor(.gray)
                            .padding(.vertical, 10)
                        
                        // Bottom Buttons
                        HStack(spacing: 20) {
                            Button(action: {
                                showSaveAlert = true
                            }) {
                               Image("btn_apply_changes")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width * 0.4)
                            }
                            
                            Button(action: {
                                activeAlert = .advanced
                            }) {
                                Image("btn_reset_default") // Usando o botão como 'Opção Avançado' visualmente ou substituindo se houver imagem específica
                                     .resizable()
                                     .scaledToFit()
                                     .frame(width: geo.size.width * 0.4)
                                     .overlay(
                                        Text("OPÇÃO AVANÇADO")
                                            .font(.custom("Spartan-Bold", size: 10))
                                            .foregroundColor(.white)
                                     )
                            }
                        }
                        .padding(.vertical, 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    @ViewBuilder
    private func landscape(geo: GeometryProxy) -> some View {
        ZStack{
            Color.white
                .ignoresSafeArea(.all)
        }
    }
}

// MARK: - Components

struct ConfigSection<Content: View>: View {
    var title: String
    var content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .appFont(weight: .bold, size: 16)
                    .foregroundColor(.white)
                Spacer()
                Image("btn_expand_interactive")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
            }
            .padding()
            .background(Color(red: 26/255, green: 60/255, blue: 104/255))
            
            VStack {
                content()
            }
            .background(Color(red: 245/255, green: 245/255, blue: 245/255))
        }
    }
}

struct ConfigToggle: View {
    var title: String
    var subtitle: String
    var icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 25)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("• \(title)")
                    .appFont(weight: .bold, size: 14)
                    .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                
                Text(subtitle)
                    .appFont(weight: .regular, size: 11)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Button(action: { isOn.toggle() }) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .resizable()
                    .frame(width: 22, height: 22)
                    .foregroundColor(isOn ? Color(red: 26/255, green: 60/255, blue: 104/255) : .gray)
            }
        }
        .padding()
    }
}

struct CustomSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var onEnded: (() -> Void)? = nil
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 12)
                    .cornerRadius(6)
                
                Rectangle()
                    .fill(Color(red: 112/255, green: 42/255, blue: 78/255))
                    .frame(width: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width, height: 12)
                    .cornerRadius(6)
                
                Circle()
                    .fill(Color(red: 112/255, green: 42/255, blue: 78/255))
                    .frame(width: 14, height: 14)
                    .offset(x: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width - 7)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newValue = Double(gesture.location.x / geometry.size.width) * (range.upperBound - range.lowerBound) + range.lowerBound
                                value = max(range.lowerBound, min(range.upperBound, newValue))
                            }
                            .onEnded { _ in
                                onEnded?()
                            }
                    )
            }
        }
        .frame(height: 14)
    }
}
