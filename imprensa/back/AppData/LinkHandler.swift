import SwiftUI
import UIKit

/// Tipos de link que o app usa
enum SocialType {
    case instagram(username: String)
    case facebook(profileId: String)
    case whatsapp(phone: String)
    case youtube(channelId: String)
    case custom(urlString: String)
}

final class LinkHandler: ObservableObject {
    static let shared = LinkHandler()
    private init() {}

    weak var dataController: AppDataController?

    @Published var pendingURL: URL?  // URL que vai abrir no sheet
    @Published var whatsappPhoneNumber: String? // Número do WhatsApp
    
    // Chama esse único método, passando o rotulo do social
    func openSocial(_ rotulo: String, message: String? = nil) {
        // 1) pega o Social do AppDataController
        guard
            let appInfo = dataController?.appData?.app,
            let social = appInfo.social(rotulo: rotulo)
        else { return }

        
        whatsappPhoneNumber = appInfo.social(rotulo: "whatsapp")?.link
        
        // 2) mapeia pro tipo correto
        let type: SocialType
        switch rotulo.lowercased() {
        case "instagram":
            type = .instagram(username: social.scheme)
        case "facebook":
            type = .facebook(profileId: social.scheme)
        case "whatsapp":
            type = .whatsapp(phone: social.scheme)
        case "youtube":
            type = .youtube(channelId: social.scheme)
        case "promocao":
            // Para promoções, queremos que o link seja aberto no sheet
            type = .whatsapp(phone: social.scheme)
        case "noticia":
            // Para promoções, queremos que o link seja aberto no sheet
            pendingURL = URL(string: social.link)
            return  // Retorna aqui para evitar a abertura via scheme
        case "anunciantes":
            // Para promoções, queremos que o link seja aberto no sheet
            pendingURL = URL(string: social.link)
            return  // Retorna aqui para evitar a abertura via scheme
        case "locutores":
            // Para promoções, queremos que o link seja aberto no sheet
            pendingURL = URL(string: social.link)
            return  // Retorna aqui para evitar a abertura via scheme
        default:
            type = .custom(urlString: social.link)
        }

        open(type, message: message)
    }

    func openSite() {
        guard
            let urlString = dataController?.appData?.app.site,
            let url = URL(string: urlString)
        else { return }
        pendingURL = url
    }

    private func open(_ type: SocialType, message: String? = nil) {
        let encodedMessage = message?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let (schemeURL, webURL): (URL?, URL?) = {
            switch type {
            case .instagram(let u):
                // Instagram não suporta mensagens pré-preenchidas via URL
                return (URL(string: "instagram://user?username=\(u)"),
                        URL(string: "https://www.instagram.com/\(u)"))
            case .facebook(let id):
                // Facebook também não suporta mensagens diretas via URL
                return (URL(string: "fb://profile/\(id)"),
                        URL(string: "https://www.facebook.com/\(id)"))
            case .whatsapp(let p):
                let messageParam = message != nil ? "&text=\(encodedMessage)" : ""
                return (URL(string: "whatsapp://send?phone=\(p)\(messageParam)"),
                        URL(string: "https://api.whatsapp.com/send?phone=\(p)\(messageParam)"))
            case .youtube(let ch):
                // YouTube não suporta mensagens via URL
                return (URL(string: "youtube://channel/\(ch)"),
                        URL(string: "https://www.youtube.com/channel/\(ch)"))
            case .custom(let s):
                return (URL(string: s), URL(string: s))
            }
        }()

        if let s = schemeURL, UIApplication.shared.canOpenURL(s) {
            UIApplication.shared.open(s)
        } else if let w = webURL {
            pendingURL = w  // Abre o link de fallback no web
        }
    }
}

// para usar .sheet(item:) com URL
extension URL: Identifiable {
    public var id: String { absoluteString }
}

extension AppInfo {
    func social(rotulo: String) -> Social? {
        for radio in radios {
            if let s = radio.sociais.first(where: { $0.rotulo.lowercased() == rotulo.lowercased() }) {
                return s
            }
        }
        return nil
    }
}
