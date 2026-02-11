import SwiftUI
import Combine
import UIKit

final class ThemeManager: ObservableObject {

    // MARK: - Config persistente
    private enum Keys {
        static let theme              = "theme"
        static let syncIconWithTheme  = "syncIconWithTheme"
        static let selectedIcon       = "selectedIcon"
    }

    // Define se o ícone deve seguir o tema
    private var syncIconWithTheme: Bool {
        didSet { UserDefaults.standard.set(syncIconWithTheme, forKey: Keys.syncIconWithTheme) }
    }

    // Controla chamadas internas (para evitar loop de notificação)
    private var isApplyingIconManually = false

    // MARK: - Tema
    @Published var theme: Theme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: Keys.theme)

            // Aplica ícone só se o usuário pediu sincronia
            if syncIconWithTheme && !isApplyingIconManually {
                applyIcon(theme.iconName)
            }
        }
    }
    
    @Published var selectedIcon: String? {
            didSet {
                UserDefaults.standard.set(selectedIcon, forKey: Keys.selectedIcon)
            }
        }

    // Ordem de ciclos de ícones (nil = padrão)
    private let iconCycle: [String?] = [
        nil,
        Theme.escuro.iconName
    ]

    // MARK: - Init
    init() {
            if let savedTheme = UserDefaults.standard.string(forKey: Keys.theme),
               let t = Theme(rawValue: savedTheme) {
                theme = t
            } else {
                theme = .default
            }

            syncIconWithTheme = UserDefaults.standard.bool(forKey: Keys.syncIconWithTheme)
            selectedIcon = UserDefaults.standard.string(forKey: Keys.selectedIcon)

            if syncIconWithTheme {
                applyIcon(theme.iconName)
            } else if let savedIcon = selectedIcon {
                applyIcon(savedIcon) // garante coerência no 1º launch
            }
        }

    // MARK: 1) Tema + Ícone
    func toggleThemeAndIcon() {
        syncIconWithTheme = true
        theme = theme.next          // `didSet` aplicará o ícone
    }

    func selectThemeAndIcon(_ selected: Theme) {
        syncIconWithTheme = true
        theme = selected
    }

    // MARK: 2) Somente Tema
    func toggleThemeOnly() {
        syncIconWithTheme = false   // descola ícone do tema
        theme = theme.next
    }

    func selectThemeOnly(_ selected: Theme) {
        syncIconWithTheme = false
        theme = selected
    }

    // MARK: 3) Somente Ícone
    func toggleIconOnly() {
        guard UIApplication.shared.supportsAlternateIcons else { return }

        syncIconWithTheme = false   // ícone passa a ser gerido manualmente

        let current = UIApplication.shared.alternateIconName
        let idx     = iconCycle.firstIndex { $0 == current } ?? 0
        let next    = iconCycle[(idx + 1) % iconCycle.count]
        applyIcon(next)
    }

    func selectIconOnly(_ iconName: String?) {
            syncIconWithTheme = false
            selectedIcon = iconName
            applyIcon(iconName)
        }

    // MARK: – Lógica de troca de ícone
    private func applyIcon(_ iconName: String?) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        guard UIApplication.shared.alternateIconName != iconName else { return }

        isApplyingIconManually = true     // evita reentrância no didSet
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let err = error {
                print("Erro ao trocar ícone: \(err.localizedDescription)")
            }
            self.isApplyingIconManually = false
        }
    }

    // MARK: – Helpers (inalterados)
    func getSuffix() -> String {
        return theme.suffix
    }

    func themedImageName(_ baseName: String) -> String {
        return theme.themedImageName(baseName)
    }

    // MARK: – Enum Theme (igual ao seu)
    enum Theme: String {
        case `default` = "default"
        case escuro   = "escuro"

        var next: Theme {
            switch self {
            case .default: return .escuro
            case .escuro:   return .default
            }
        }

        var suffix: String {
            switch self {
            case .default: return ""
            case .escuro:    return "Escuro"
            }
        }

        var iconName: String? {
            switch self {
            case .default: return nil
            case .escuro:    return "AppIconEscuro"
            }
        }

        func themedImageName(_ baseName: String) -> String {
            switch self {
            case .default: return baseName
            case .escuro:    return baseName + "Escuro"
            }
        }
    }
}
