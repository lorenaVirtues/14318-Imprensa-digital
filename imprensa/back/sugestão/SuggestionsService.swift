import Foundation
import UIKit

/// Serviço para envio de sugestões ao backend (virtues.now).
enum SuggestionsAPI {
    static let baseURL = "https://virtues.now/suggestions/api/suggestions/create.php"
    static let apiToken = "token-api-sugestoes-df4dc3c340a7df6b04044730dfa5ec87731401a1efa3fe368fda5f36e5f456c2"
}

final class SuggestionsService {
    static let shared = SuggestionsService()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    /// Dados do app (bundle id, versão, nome) obtidos do projeto.
    static var appInfo: (package: String, version: String, name: String) {
        let bundle = Bundle.main
        let package = bundle.bundleIdentifier ?? "com.app.imprensa"
        let version = (bundle.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
        let name = (bundle.infoDictionary?["CFBundleDisplayName"] as? String)
            ?? (bundle.infoDictionary?["CFBundleName"] as? String)
            ?? "Rádio Imprensa Digital"
        return (package, version, name)
    }

    /// Dados do dispositivo (sistema, modelo).
    static var deviceInfo: (sistema: String, dispositivo: String) {
        let device = UIDevice.current
        let sistema = "iOS \(device.systemVersion)"
        let dispositivo = device.model
        return (sistema, dispositivo)
    }

    /// Envia a sugestão para o backend.
    /// - Parameters:
    ///   - nome: Nome do usuário
    ///   - email: E-mail
    ///   - telefone: Telefone
    ///   - titulo: Título da sugestão
    ///   - descricao: Descrição detalhada
    ///   - latitude: Latitude (opcional; use nil se não houver permissão)
    ///   - longitude: Longitude (opcional)
    func submit(
        nome: String,
        email: String,
        telefone: String,
        titulo: String,
        descricao: String,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) async throws {
        guard let url = URL(string: SuggestionsAPI.baseURL) else {
            throw SuggestionsError.invalidURL
        }

        let (package, version, name) = Self.appInfo
        let (sistema, dispositivo) = Self.deviceInfo
        let x = latitude.map { String($0) } ?? "0"
        let y = longitude.map { String($0) } ?? "0"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(SuggestionsAPI.apiToken, forHTTPHeaderField: "X-API-Token")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "nome", value: nome),
            URLQueryItem(name: "email", value: email),
            URLQueryItem(name: "telefone", value: telefone),
            URLQueryItem(name: "titulo", value: titulo),
            URLQueryItem(name: "descricao", value: descricao),
            URLQueryItem(name: "app_package", value: package),
            URLQueryItem(name: "app_name", value: name),
            URLQueryItem(name: "sistema", value: sistema),
            URLQueryItem(name: "dispositivo", value: dispositivo),
            URLQueryItem(name: "versao", value: version),
            URLQueryItem(name: "x", value: x),
            URLQueryItem(name: "y", value: y),
            URLQueryItem(name: "cliente", value: "14318"),
            URLQueryItem(name: "radio", value: "11069")
        ]
        let bodyString = components.percentEncodedQuery ?? ""
        request.httpBody = bodyString.data(using: .utf8)

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SuggestionsError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw SuggestionsError.serverError(statusCode: http.statusCode)
        }
    }
}

enum SuggestionsError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida."
        case .invalidResponse:
            return "Resposta inválida do servidor."
        case .serverError(let code):
            return "Erro no servidor (código \(code)). Tente novamente mais tarde."
        }
    }
}
