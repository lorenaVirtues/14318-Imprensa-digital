import SwiftUI

// MARK: - Máscara de telefone (BR: fixo (10) ou móvel (11 dígitos))

private func formatPhone(_ value: String) -> String {
    let digits = value.filter { $0.isNumber }
    if digits.count <= 2 {
        return digits.isEmpty ? "" : "(\(digits)"
    }
    if digits.count <= 6 {
        let ddd = String(digits.prefix(2))
        let rest = String(digits.dropFirst(2))
        return "(\(ddd)) \(rest)"
    }
    if digits.count <= 10 {
        let ddd = String(digits.prefix(2))
        let first = String(digits.dropFirst(2).prefix(4))
        let last = String(digits.dropFirst(6))
        return "(\(ddd)) \(first)-\(last)"
    }
    // 11 dígitos: (XX) XXXXX-XXXX
    let ddd = String(digits.prefix(2))
    let first = String(digits.dropFirst(2).prefix(5))
    let last = String(digits.dropFirst(7))
    return "(\(ddd)) \(first)-\(last)"
}

private func phoneDigitsOnly(_ value: String) -> String {
    value.filter { $0.isNumber }
}

/// Campo focável do formulário de sugestões (ordem de navegação).
private enum SuggestionsField: Int, CaseIterable, Hashable {
    case nome = 0
    case email
    case telefone
    case titulo
    case descricao

    var label: String {
        switch self {
        case .nome: return "Nome"
        case .email: return "E-mail"
        case .telefone: return "Telefone"
        case .titulo: return "Título"
        case .descricao: return "Descrição"
        }
    }

    static var ordered: [SuggestionsField] { [.nome, .email, .telefone, .titulo, .descricao] }
}

struct SuggestionsView: View {
    @EnvironmentObject var router: NavigationRouter
    /// Chamado ao fechar o alerta de sucesso: limpa o formulário e permite voltar à tela anterior.
    var onSuccess: (() -> Void)?

    @StateObject private var locationHelper = LocationHelper.shared
    @FocusState private var focusedField: SuggestionsField?

    @State private var nome = ""
    @State private var email = ""
    @State private var telefone = ""
    @State private var titulo = ""
    @State private var descricao = ""
    
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertType: AlertType2 = .warning
    @State private var pendingDismissAfterAlert = false

    var body: some View {
        ZStack {
            Color("azulEscuro")
                .edgesIgnoringSafeArea(.top)
            
            Color.white
            
            ScrollView {
                VStack(spacing: 0) {
                    header
                    
                    Divider()
                    
                    VStack(spacing: 16) {
                        campo(icon: "person.fill", placeholder: "Nome", text: $nome, field: .nome)
                        campo(icon: "envelope.fill", placeholder: "E-mail", text: $email, field: .email, keyboard: .emailAddress)
                        campo(icon: "phone.fill", placeholder: "Telefone", text: $telefone, field: .telefone, keyboard: .phonePad)
                        campo(icon: "bookmark.fill", placeholder: "Título da sugestão", text: $titulo, field: .titulo)
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "text.bubble.fill")
                                Text("Descrição").foregroundColor(.secondary)
                            }
                            TextEditor(text: $descricao)
                                .frame(minHeight: 120)
                                .disableAutocorrection(true)
                                .focused($focusedField, equals: .descricao)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    enviarButton
                        .padding(16)
                }
            }
            .disabled(isLoading)
            .opacity(isLoading ? 0.6 : 1)
            
            if isLoading {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView("Enviando...")
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
            
            if showAlert {
                Color.black.opacity(0.4).ignoresSafeArea()
                AlertaView2(message: alertMessage, alertType: alertType) {
                    withAnimation { showAlert = false }
                    if pendingDismissAfterAlert {
                        pendingDismissAfterAlert = false
                        clearForm()
                        onSuccess?()
                        router.go(to: .menu)
                    }
                }
                .zIndex(1)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            locationHelper.requestLocation()
        }
        .preferredColorScheme(.light)
    }
    
    private var header: some View {
        HStack {
            Button { router.go(to: .menu) } label: {
                Image(systemName: "chevron.left").font(.title2)
                    .foregroundColor(.white)
            }
            Text("Sugestões")
                .font(.title2).bold()
                .foregroundColor(.white)
            Spacer()
            Color.clear.frame(width: 24, height: 24)
        }
        .padding()
        .background(Color("azulEscuro"))
    }
    
    private func campo(icon: String,
                       placeholder: String,
                       text: Binding<String>,
                       field: SuggestionsField,
                       keyboard: UIKeyboardType = .default) -> some View {
        HStack {
            Image(systemName: icon)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .autocapitalization(field == .email ? .none : .words)
                .disableAutocorrection(true)
                .focused($focusedField, equals: field)
                .submitLabel(.next)
                .onChange(of: text.wrappedValue) { newValue in
                    if field == .telefone {
                        let digits = String(newValue.filter { $0.isNumber }.prefix(11))
                        let formatted = formatPhone(digits)
                        if formatted != newValue {
                            text.wrappedValue = formatted
                        }
                    }
                }
                .onSubmit { focusNext() }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }

    private var enviarButton: some View {
        Button(action: submitSuggestion) {
            Text("Enviar sugestão")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("azulEscuro"))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
        }
    }

    private func focusNext() {
        guard let current = focusedField else { return }
        guard let idx = SuggestionsField.ordered.firstIndex(of: current) else { return }
        if idx + 1 < SuggestionsField.ordered.count {
            focusedField = SuggestionsField.ordered[idx + 1]
        } else {
            focusedField = nil
        }
    }

    private func submitSuggestion() {
        focusedField = nil
        if let error = validateAll() {
            alertMessage = error
            alertType = .warning
            pendingDismissAfterAlert = false
            withAnimation { showAlert = true }
            return
        }
        
        isLoading = true
        Task {
            do {
                try await SuggestionsService.shared.submit(
                    nome: nome.trimmingCharacters(in: .whitespaces),
                    email: email.trimmingCharacters(in: .whitespaces),
                    telefone: phoneDigitsOnly(telefone),
                    titulo: titulo.trimmingCharacters(in: .whitespaces),
                    descricao: descricao.trimmingCharacters(in: .whitespaces),
                    latitude: locationHelper.latitude,
                    longitude: locationHelper.longitude
                )
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Sua sugestão foi enviada e será analisada. Obrigado!"
                    alertType = .success
                    pendingDismissAfterAlert = true
                    withAnimation { showAlert = true }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = error.localizedDescription
                    alertType = .error
                    pendingDismissAfterAlert = false
                    withAnimation { showAlert = true }
                }
            }
        }
    }

    private func validateAll() -> String? {
        let nomeTrim = nome.trimmingCharacters(in: .whitespaces)
        let emailTrim = email.trimmingCharacters(in: .whitespaces)
        let tituloTrim = titulo.trimmingCharacters(in: .whitespaces)
        let descricaoTrim = descricao.trimmingCharacters(in: .whitespaces)

        if nomeTrim.isEmpty { return "O campo Nome não pode ficar vazio." }
        if nomeTrim.count < 2 { return "O Nome deve ter pelo menos 2 caracteres." }
        if emailTrim.isEmpty { return "O campo E-mail não pode ficar vazio." }
        if !isValidEmail(emailTrim) { return "Digite um E-mail válido." }
        
        let telDigits = phoneDigitsOnly(telefone)
        if telDigits.isEmpty { return "O campo Telefone não pode ficar vazio." }
        if telDigits.count != 10 && telDigits.count != 11 { return "O Telefone deve ter 10 ou 11 dígitos." }

        if tituloTrim.isEmpty { return "O campo Título não pode ficar vazio." }
        if descricaoTrim.isEmpty { return "O campo Descrição não pode ficar vazio." }
        return nil
    }

    private func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        return trimmed.contains("@") && trimmed.contains(".")
    }

    private func clearForm() {
        nome = ""; email = ""; telefone = ""; titulo = ""; descricao = ""
    }
}
