import SwiftUI
import UIKit
 
struct ContatoView: View {
    @EnvironmentObject var router: NavigationRouter
    
    // Campos do formulário
    @State private var nome     = ""
    @State private var email    = ""
    @State private var assunto  = ""
    @State private var mensagem = ""
    @State private var telefone = ""
    @State private var selectedDDI = DDIList.first!
    @State private var shouldDismissOnAlert = false
    // Foco dos campos
    enum Field: Hashable { case nome, email, telefone, assunto, mensagem }
    @FocusState private var focusedField: Field?
    
    // Controle do alerta
    @State private var showAlert    = false
    @State private var alertMessage = ""
    @State private var alertType: AlertType = .warning
    @State private var errorField: Field? = nil
    
    // Controle de carregamento
    @State private var isSending = false
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // layout
                    header
                    
                    Divider()
                    
                    Group { campos }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    enviarButton
                        .padding(16)
                }
            }
            .disabled(isSending)
            .opacity(isSending ? 0.6 : 1)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .toolbar { keyboardToolbar }
            
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if shouldDismissOnAlert {
                            shouldDismissOnAlert = false
                            router.go(to: .home)
                        } else {
                            focusedField = errorField
                        }
                    }
                }
                .zIndex(1)
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
    }
    
    private var header: some View {
        HStack {
            Button { router.go(to: .home) } label: {
                Image(systemName: "chevron.left").font(.title2)
            }
            Spacer()
            Text("Contato")
                .font(.title2).bold()
            Spacer()
            Color.clear.frame(width: 24, height: 24)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
    
    @ViewBuilder
    private var campos: some View {
        campo(icon: "person.fill", placeholder: "Nome",    text: $nome,     field: .nome)
        campo(icon: "envelope.fill", placeholder: "E-mail", text: $email,    field: .email, keyboard: .emailAddress)
        campo(icon: "bookmark.fill", placeholder: "Assunto", text: $assunto,  field: .assunto)
        
        campoTelefone
        
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "text.bubble.fill")
                Text("Mensagem").foregroundColor(.secondary)
            }
            TextEditor(text: $mensagem)
                .frame(minHeight: 120)
                .disableAutocorrection(true)
                .focused($focusedField, equals: .mensagem)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private func campo(icon: String,
                       placeholder: String,
                       text: Binding<String>,
                       field: Field,
                       keyboard: UIKeyboardType = .default) -> some View
    {
        HStack {
            Image(systemName: icon)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .autocapitalization(field == .email ? .none : .words)
                .disableAutocorrection(true)
                .focused($focusedField, equals: field)
                .submitLabel(.next)
                .onSubmit { vaiParaProximo() }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
    @ViewBuilder
    private var campoTelefone: some View {
            HStack {
                Image(systemName: "phone.fill")

                Menu {
                    ForEach(DDIList) { info in
                        Button {
                            selectedDDI = info
                            telefone = ""
                        } label: {
                            Text("\(info.flag) \(info.code)")
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedDDI.flag)
                        Text(selectedDDI.code)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 6)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(6)
                }

                TextField(selectedDDI.placeholder, text: $telefone)
                    .keyboardType(.numberPad)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .telefone)
                    .submitLabel(.next)
                    .onChange(of: telefone) { new in
                        telefone = applyMask(new, mask: selectedDDI.placeholder)
                    }
                    .onSubmit { vaiParaProximo() }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
        }


    private var enviarButton: some View {
        Button(action: submit) {
            Text("Enviar")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
    
    private var keyboardToolbar: some ToolbarContent {
            ToolbarItemGroup(placement: .keyboard) {
                Button("Fechar") { focusedField = nil }
                Spacer()
                Text(currentText)
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 200)
                Spacer()
                Button("Próximo") { vaiParaProximo() }
            }
        }
    
    private var currentText: String {
        switch focusedField {
        case .nome:     return nome
        case .email:    return email
        case .assunto:  return assunto
        case .telefone: return telefone
        case .mensagem: return mensagem
        default:        return ""
        }
    }

    private func vaiParaProximo() {
        switch focusedField {
        case .nome:     focusedField = .email
        case .email:    focusedField = .assunto
        case .assunto:  focusedField = .telefone
        case .telefone: focusedField = .mensagem
        default:        focusedField = nil
        }
    }
    
    private func submit() {
        focusedField = nil

        if nome.trimmingCharacters(in: .whitespaces).isEmpty {
            show(cause: "Por favor, informe o nome.", type: .warning, focus: .nome)
        }
        else if !email.contains("@") || email.count < 5 {
            show(cause: "Digite um e-mail válido.", type: .warning, focus: .email)
        }
        else if assunto.trimmingCharacters(in: .whitespaces).isEmpty {
            show(cause: "Por favor, informe o assunto.", type: .warning, focus: .assunto)
        }
        else if selectedDDI.code.isEmpty {
            show(cause: "Por favor, selecione o DDI.", type: .warning, focus: .telefone)
        }
        else if telefone.trimmingCharacters(in: .whitespaces).isEmpty {
            show(cause: "Por favor, informe o telefone.", type: .warning, focus: .telefone)
        }
        else if mensagem.trimmingCharacters(in: .whitespaces).isEmpty {
                show(cause: "Por favor, escreva a mensagem.", type: .warning, focus: .mensagem)
        }
        else {
            let digits = telefone.filter { $0.isNumber }
            let validLens = requiredLengths(for: selectedDDI)

            if !validLens.contains(digits.count) {
                if selectedDDI.code == "+55" {
                    show(
                        cause: "Telefone incompleto. Use (00) 0000-0000 (fixo) ou (00) 00000-0000 (celular).",
                        type: .warning,
                        focus: .telefone
                    )
                } else {
                    let required = validLens.first ?? 0
                    show(
                        cause: "Telefone incompleto. Use o formato \(selectedDDI.placeholder).",
                        type: .warning,
                        focus: .telefone
                    )
                }
                return
            }
            sendContact()
        }

    }
    
    private func requiredLengths(for ddi: DDIInfo) -> Set<Int> {
        if ddi.code == "+55" {
            // Brasil: aceita Fixo (10) e Celular (11)
            return [10, 11]
        } else {
            // Conta a quantidade de zeros no placeholder como comprimento esperado
            let len = ddi.placeholder.filter { $0 == "0" }.count
            return [len]
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
        let dispositivo  = UIDevice.current.type.rawValue
        
        let ddiDigits   = selectedDDI.code.filter { $0.isNumber }
        let phoneDigits = telefone.filter { $0.isNumber }
        let fullPhone   = ddiDigits + phoneDigits
        
        DeviceModelResolver.shared.resolveModelName { resolvedModel in
            let dispositivo = resolvedModel
            
            var paramString = """
            radio=\(radio)&nome=\(nome)&email=\(email)&assunto=\(assunto)&mensagem=\(mensagem)&cliente=\(bundleId)&sistema=\(sistema)&dispositivo=\(dispositivo)
            """
            
            paramString = paramString
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "\r", with: "")
                .replacingOccurrences(of: "\t", with: "")
            
            let encoded = paramString
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? paramString
            
            guard let url = URL(string: "https://www.virtueslab.app/contato_radio_salvar.php") else {
                return finishSending(success: false, message: "URL inválida.")
            }
            var request = URLRequest(url: url, timeoutInterval: 15)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = Data(encoded.utf8)
            
            URLSession.shared.dataTask(with: request) { data, resp, error in
                DispatchQueue.main.async { isSending = false }
                
                if let err = error {
                    return finishSending(success: false, message: "Erro na conexão: \(err.localizedDescription)")
                }
                guard let http = resp as? HTTPURLResponse else {
                    return finishSending(success: false, message: "Resposta inválida do servidor.")
                }
                
                print("📬 Status code: \(http.statusCode)")
                if let d = data, let s = String(data: d, encoding: .utf8) {
                    print("📨 Body: \(s)")
                }
                
                if http.statusCode == 200 {
                    finishSending(success: true, message: "Enviado com sucesso!")
                } else {
                    finishSending(success: false, message: "Erro no servidor: \(http.statusCode)")
                }
            }
            .resume()
        }
        
        
        func finishSending(success: Bool, message: String) {
            DispatchQueue.main.async {
                shouldDismissOnAlert = success

                show(cause: message,
                     type: success ? .success : .error,
                     focus: success ? nil : errorField)

                if success {
                    nome = ""; email = ""; assunto = ""; mensagem = ""; telefone = ""
                }
            }
        }
    }
    
    private func applyMask(_ string: String, mask: String) -> String {
        let digits = string.filter { $0.isNumber }
        var result = ""
        var index = digits.startIndex
        
        if selectedDDI.code == "+55" {
            let isMobile = digits.count > 10
            let finalMask = isMobile ? "(00) 00000-0000" : "(00) 0000-0000"

            for ch in finalMask {
                guard index < digits.endIndex else { break }
                if ch == "0" {
                    result.append(digits[index])
                    index = digits.index(after: index)
                } else {
                    result.append(ch)
                }
            }
        } else {
            for ch in mask {
                guard index < digits.endIndex else { break }
                if ch == "0" {
                    result.append(digits[index])
                    index = digits.index(after: index)
                } else {
                    result.append(ch)
                }
            }
        }
        
        return result
    }

}
