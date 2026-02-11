import SwiftUI

enum Route: Hashable {
    case splash
    case home
    case menu
    case contato
}

final class NavigationRouter: ObservableObject {
    // Pilha para navegação interna (quando usar NavigationStack/Link)
    @Published var path: [Route] = []

    // Rota top-level atual
    @Published var currentRoute: Route = .splash

    // Histórico de rotas top-level (ex.: home -> noticias -> radio ...)
    @Published private(set) var topLevelHistory: [Route] = []

    // Limite opcional para não crescer demais
    private let historyLimit = 32

    // MARK: - Top-level
    func goHome() {
        go(to: .home)
    }

    /// Vai para uma rota top-level e lembra a anterior
    func go(to route: Route, remember: Bool = true) {
        withAnimation(.easeInOut) {
            if remember, currentRoute != route, currentRoute != .splash {
                topLevelHistory.append(currentRoute)
                if topLevelHistory.count > historyLimit {
                    topLevelHistory.removeFirst(topLevelHistory.count - historyLimit)
                }
            }
            currentRoute = route
            path.removeAll()
        }
    }

    /// Volta para a rota top-level anterior (se existir)
    func backTopLevel() {
        withAnimation(.easeInOut) {
            guard let last = topLevelHistory.popLast() else { return }
            currentRoute = last
            path.removeAll()
        }
    }

    // MARK: - Navegação interna (push/pop)
    func push(_ route: Route) {
        withAnimation(.easeInOut) { path.append(route) }
    }

    func pop() {
        withAnimation(.easeInOut) {
            if !path.isEmpty { path.removeLast() }
        }
    }

    func popTo(_ route: Route) {
        withAnimation(.easeInOut) {
            guard let idx = path.firstIndex(of: route) else { return }
            path = Array(path.prefix(through: idx))
        }
    }

    func popToRoot() {
        withAnimation(.easeInOut) { path.removeAll() }
    }

    /// Pop “inteligente”: se houver pilha interna faz pop(); senão, volta a top-level anterior
    func popOrBack() {
        if !path.isEmpty {
            pop()
        } else {
            backTopLevel()
        }
    }

    /// Reset total (ex.: logout)
    func reset(to route: Route = .splash) {
        withAnimation(.easeInOut) {
            currentRoute = route
            path.removeAll()
            topLevelHistory.removeAll()
        }
    }
}
