import Foundation

private let autoplayKey = "autoplayEnabled"
private let animationsKey = "animationsEnabled"

// Helper para gerenciar autoplay
extension UserDefaults {
    static var autoplayEnabled: Bool {
        get {
            // Por padrão, autoplay está ativado (true) para manter comportamento atual
            UserDefaults.standard.object(forKey: autoplayKey) as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: autoplayKey)
        }
    }
    
    static var animationsEnabled: Bool {
        get {
            // Por padrão, animações estão ativadas (false = não pausar = animações ativas)
            // pauseAll = false significa animações ativas
            // pauseAll = true significa animações pausadas
            // Então animationsEnabled = !pauseAll
            // Por padrão, animações estão ativas (true)
            UserDefaults.standard.object(forKey: animationsKey) as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: animationsKey)
        }
    }
}

