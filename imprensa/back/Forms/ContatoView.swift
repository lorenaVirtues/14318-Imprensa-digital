import SwiftUI

struct ContatoView: View {
    @EnvironmentObject var router: NavigationRouter
    
    // Form fields
    @State private var nome     = ""
    @State private var email    = ""
    @State private var assunto  = ""
    @State private var mensagem = ""
    
    // Focus management
    enum Field: Hashable { case nome, email, assunto, mensagem }
    @FocusState private var focusedField: Field?
    
    // Alert control
    @State private var showAlert    = false
    @State private var alertMessage = ""
    @State private var alertType: AlertType = .warning
    @State private var errorField: Field? = nil
    @State private var shouldDismissOnAlert = false
    
    // Loading state
    @State private var isSending = false
    
    var body: some View {
        Color("azulEscuro")
            .edgesIgnoringSafeArea(.bottom)
        ZStack {
            Color.white
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        // Title / Subtitle
                        VStack(spacing: 5) {
                            Text("Tem um recado?")
                                .font(.custom("Spartan-Bold", size: 18))
                                .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                            
                            Text("Preencha seus dados e manda pra gente!")
                                .font(.custom("Spartan-Regular", size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                        
                        // Fields Grid (Nome and Email in same row)
                        VStack(spacing: 20) {
                            HStack(spacing: 15) {
                                formField(label: "Nome:", icon: "person.fill", placeholder: "Seu nome....", text: $nome, field: .nome)
                                formField(label: "E-mail:", icon: "at", placeholder: "Seu e-mail....", text: $email, field: .email, keyboard: .emailAddress)
                            }
                            
                            formField(label: "Assunto:", icon: "magnifyingglass", placeholder: "Assunto da mensagem...", text: $assunto, field: .assunto)
                            
                            // Mensagem (Larger)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Mensagem:")
                                    .font(.custom("Spartan-Bold", size: 16))
                                    .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                                
                                ZStack(alignment: .topLeading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(Color.gray, lineWidth: 1)
                                        .background(Color.white)
                                    
                                    HStack(alignment: .top, spacing: 5) {
                                        Image(systemName: "envelope.fill")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 14))
                                            .padding(.top, 12)
                                        
                                        ZStack(alignment: .topLeading) {
                                            if mensagem.isEmpty {
                                                Text("Sua mensagem....")
                                                    .foregroundColor(.gray.opacity(0.6))
                                                    .font(.custom("Spartan-Regular", size: 14))
                                                    .padding(.top, 10)
                                            }
                                            
                                            TextEditor(text: $mensagem)
                                                .font(.custom("Spartan-Regular", size: 14))
                                                .focused($focusedField, equals: .mensagem)
                                                .opacity(mensagem.isEmpty ? 0.85 : 1)
                                                .frame(minHeight: 180)
                                                .padding(.top, 2)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                }
                                .frame(height: 200)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Enviar Button (Slanted style)
                        HStack {
                            Spacer()
                            Button(action: submit) {
                                HStack {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 12))
                                    Text("ENVIAR")
                                        .font(.custom("Spartan-Bold", size: 18))
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 30)
                                .background(
                                    ZStack {
                                        // Simple slanted background
                                        SlantedButtonShape()
                                            .fill(Color(red: 26/255, green: 60/255, blue: 104/255))
                                        
                                        // Shadow
                                        SlantedButtonShape()
                                            .fill(Color(red: 26/255, green: 60/255, blue: 104/255).opacity(0.3))
                                            .offset(x: 2, y: 3)
                                            .zIndex(-1)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 100)
                    }
                }
            }
            
            // Bottom Left Back Button
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        router.backTopLevel()
                    }) {
                        Image("btn_return")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100)
                    }
                    Spacer()
                }
            }
            
            if isSending {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView("Enviando...")
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
            
            if showAlert {
                Color.black.opacity(0.4).ignoresSafeArea()
                AlertaView(
                    message: alertMessage,
                    alertType: alertType
                ) {
                    withAnimation { showAlert = false }
                    if shouldDismissOnAlert {
                        router.backTopLevel()
                    }
                }
                .zIndex(1)
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.light)
    }
    
    // MARK: - Components
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                // Title
               Image("bg_header_title_contact")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160)
                    .padding(.leading)
                
                Spacer()
                
                HeaderDateTimeView()
                    .padding(.trailing, 20)
            }
            .padding(.top, 40)
            .padding(.bottom, 15)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.top, 5)
        }
    }
    
    @ViewBuilder
    private func formField(label: String, icon: String, placeholder: String, text: Binding<String>, field: Field, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.custom("Spartan-Bold", size: 16))
                .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                
                TextField(placeholder, text: text)
                    .font(.custom("Spartan-Regular", size: 14))
                    .keyboardType(keyboard)
                    .focused($focusedField, equals: field)
                    .autocapitalization(field == .email ? .none : .words)
            }
            .padding(.horizontal, 10)
            .frame(height: 45)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.gray, lineWidth: 1)
                    .background(Color.white)
            )
        }
    }
    
    // MARK: - Logic
    
    private func submit() {
        focusedField = nil
        
        if nome.isEmpty {
            show(cause: "Informe seu nome.", type: .warning, focus: .nome)
        } else if email.isEmpty || !email.contains("@") {
            show(cause: "Informe um e-mail válido.", type: .warning, focus: .email)
        } else if assunto.isEmpty {
            show(cause: "Informe o assunto.", type: .warning, focus: .assunto)
        } else if mensagem.isEmpty {
            show(cause: "Escreva sua mensagem.", type: .warning, focus: .mensagem)
        } else {
            sendContact()
        }
    }
    
    private func show(cause: String, type: AlertType, focus: Field?) {
        alertMessage = cause
        alertType    = type
        errorField   = focus
        withAnimation { showAlert = true }
    }
    
    private func sendContact() {
        isSending = true
        
        let radio        = "11069"
        let bundleId     = "14318"
        let sistema      = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        
        DeviceModelResolver.shared.resolveModelName { resolvedModel in
            let dispositivo = resolvedModel
            
            let paramString = "radio=\(radio)&nome=\(nome)&email=\(email)&assunto=\(assunto)&mensagem=\(mensagem)&cliente=\(bundleId)&sistema=\(sistema)&dispositivo=\(dispositivo)"
            
            guard let url = URL(string: "https://www.virtueslab.app/contato_radio_salvar.php") else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = paramString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.data(using: .utf8)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    isSending = false
                    if let _ = error {
                        show(cause: "Erro de conexão", type: .error, focus: nil)
                    } else {
                        shouldDismissOnAlert = true
                        show(cause: "Mensagem enviada com sucesso!", type: .success, focus: nil)
                    }
                }
            }.resume()
        }
    }
}

// MARK: - Helper Shapes

struct SlantedButtonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let slant: CGFloat = 10
        path.move(to: CGPoint(x: slant, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width - slant, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}
