import SwiftUI

enum AlertType {
    case success, warning, error
    
    var background: Color {
        switch self {
        case .success: return Color.green
        case .warning: return Color.orange
        case .error:   return Color.red
        }
    }
    
    var buttonText: Color {
        switch self {
        case .success: return .green
        case .warning: return .orange
        case .error:   return .red
        }
    }
    
    var iconName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error:   return "xmark.octagon.fill"
        }
    }
}

struct AlertaView: View {
    let message: String
    let alertType: AlertType
    let onOk: () -> Void
    
    private var appDisplayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "App"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text(appDisplayName)
                .font(.custom("Poppins-BoldItalic", size: 24))
                .foregroundColor(.white)
                .padding(.top, 16)
            
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(height: 4)
                .frame(maxWidth: .infinity)
            
            Image(systemName: alertType.iconName)
                .font(.system(size: 50))
                .foregroundColor(.white)
            
            Text(message)
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Button(action: onOk) {
                Text("OK")
                    .font(.custom("Poppins-BoldItalic", size: 18))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .foregroundColor(alertType.buttonText)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(alertType.background)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(24)
    }
}

struct AlertaView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AlertaView(message: "Operação realizada com sucesso!", alertType: .success) { }
            AlertaView(message: "Preencha todos os campos antes de enviar.", alertType: .warning) { }
            AlertaView(message: "Falha ao salvar. Tente novamente.", alertType: .error) { }
        }
    }
}
