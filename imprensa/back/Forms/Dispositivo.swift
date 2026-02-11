import Foundation
import UIKit

public enum Model : String {

    // Simulator
    case simulator     = "simulator/sandbox"

    // iPod
    case iPod1              = "iPod 1"
    case iPod2              = "iPod 2"
    case iPod3              = "iPod 3"
    case iPod4              = "iPod 4"
    case iPod5              = "iPod 5"
    case iPod6              = "iPod 6"
    case iPod7              = "iPod 7"

    // iPad (clássico)
    case iPad2              = "iPad 2"
    case iPad3              = "iPad 3"
    case iPad4              = "iPad 4"
    case iPad5              = "iPad 5" // 2017
    case iPad6              = "iPad 6" // 2018
    case iPad7              = "iPad 7" // 2019
    case iPad8              = "iPad 8" // 2020
    case iPad9              = "iPad 9" // 2021
    case iPad10             = "iPad 10" // 2022 10a geração 10.9"

    // iPad Air
    case iPadAir            = "iPad Air"
    case iPadAir2           = "iPad Air 2"
    case iPadAir3           = "iPad Air 3"
    case iPadAir4           = "iPad Air 4"
    case iPadAir5           = "iPad Air 5"   // M1 (2022)
    case iPadAir6_11        = "iPad Air 6 11\" (M2, 2024)"
    case iPadAir6_13        = "iPad Air 6 13\" (M2, 2024)"

    // iPad Mini
    case iPadMini           = "iPad Mini"
    case iPadMini2          = "iPad Mini 2"
    case iPadMini3          = "iPad Mini 3"
    case iPadMini4          = "iPad Mini 4"
    case iPadMini5          = "iPad Mini 5"
    case iPadMini6          = "iPad Mini 6"

    // iPad Pro
    case iPadPro9_7         = "iPad Pro 9.7"
    case iPadPro10_5        = "iPad Pro 10.5"
    case iPadPro11          = "iPad Pro 11"
    case iPadPro2_11        = "iPad Pro 11 2"
    case iPadPro3_11        = "iPad Pro 11 3"
    case iPadPro4_11        = "iPad Pro 11 4"   // M2 (2022)
    case iPadPro5_11        = "iPad Pro 11 5"   // M4 (2024)
    case iPadPro12_9        = "iPad Pro 12.9"
    case iPadPro2_12_9      = "iPad Pro 2 12.9"
    case iPadPro3_12_9      = "iPad Pro 3 12.9"
    case iPadPro4_12_9      = "iPad Pro 4 12.9"
    case iPadPro5_12_9      = "iPad Pro 5 12.9"
    case iPadPro6_12_9      = "iPad Pro 6 12.9" // M2 (2022)
    case iPadPro7_13        = "iPad Pro 13\" 7" // M4 (2024)

    // iPhone
    case iPhone4            = "iPhone 4"
    case iPhone4S           = "iPhone 4S"
    case iPhone5            = "iPhone 5"
    case iPhone5S           = "iPhone 5S"
    case iPhone5C           = "iPhone 5C"
    case iPhone6            = "iPhone 6"
    case iPhone6Plus        = "iPhone 6 Plus"
    case iPhone6S           = "iPhone 6S"
    case iPhone6SPlus       = "iPhone 6S Plus"
    case iPhoneSE           = "iPhone SE"
    case iPhone7            = "iPhone 7"
    case iPhone7Plus        = "iPhone 7 Plus"
    case iPhone8            = "iPhone 8"
    case iPhone8Plus        = "iPhone 8 Plus"
    case iPhoneX            = "iPhone X"
    case iPhoneXS           = "iPhone XS"
    case iPhoneXSMax        = "iPhone XS Max"
    case iPhoneXR           = "iPhone XR"
    case iPhone11           = "iPhone 11"
    case iPhone11Pro        = "iPhone 11 Pro"
    case iPhone11ProMax     = "iPhone 11 Pro Max"
    case iPhone12Mini       = "iPhone 12 mini"
    case iPhone12           = "iPhone 12"
    case iPhone12Pro        = "iPhone 12 Pro"
    case iPhone12ProMax     = "iPhone 12 Pro Max"
    case iPhoneSE2ndG       = "iPhone SE (2nd generation)"
    case iPhone13Mini       = "iPhone 13 mini"
    case iPhone13           = "iPhone 13"
    case iPhone13Pro        = "iPhone 13 Pro"
    case iPhone13ProMax     = "iPhone 13 Pro Max"
    case iPhoneSE3ndG       = "iPhone SE (3rd generation)"
    case iPhone14           = "iPhone 14"
    case iPhone14Plus       = "iPhone 14 Plus"
    case iPhone14Pro        = "iPhone 14 Pro"
    case iPhone14ProMax     = "iPhone 14 Pro Max"
    case iPhone15           = "iPhone 15"
    case iPhone15Plus       = "iPhone 15 Plus"
    case iPhone15Pro        = "iPhone 15 Pro"
    case iPhone15ProMax     = "iPhone 15 Pro Max"
    case iPhone16           = "iPhone 16"
    case iPhone16Plus       = "iPhone 16 Plus"
    case iPhone16Pro        = "iPhone 16 Pro"
    case iPhone16ProMax     = "iPhone 16 Pro Max"
    case iPhone16e          = "iPhone 16e"

    // Apple TV
    case AppleTV            = "Apple TV"
    case AppleTV_4K         = "Apple TV 4K"
    case AppleTV_4K_3rd     = "Apple TV 4K (3rd generation)"

    // HomePod
    case Homepod            = "HomePod"
    case HomepodMini        = "HomePod Mini"

    case unrecognized       = "Desconhecido"
}

// MARK: - UIDevice extensions

public extension UIDevice {
    var type: Model {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { ptr in
                String(validatingUTF8: ptr)
            }
        }

        let modelMap: [String: Model] = [

            // Simulator
            "i386": .simulator,
            "x86_64": .simulator,
            "arm64": .simulator,

            // iPod
            "iPod1,1": .iPod1,
            "iPod2,1": .iPod2,
            "iPod3,1": .iPod3,
            "iPod4,1": .iPod4,
            "iPod5,1": .iPod5,
            "iPod7,1": .iPod6, // (iPod touch 6)
            "iPod9,1": .iPod7, // (iPod touch 7)

            // iPad (clássico)
            "iPad2,1": .iPad2, "iPad2,2": .iPad2, "iPad2,3": .iPad2, "iPad2,4": .iPad2,
            "iPad3,1": .iPad3, "iPad3,2": .iPad3, "iPad3,3": .iPad3,
            "iPad3,4": .iPad4, "iPad3,5": .iPad4, "iPad3,6": .iPad4,
            "iPad6,11": .iPad5, "iPad6,12": .iPad5,
            "iPad7,5": .iPad6, "iPad7,6": .iPad6,
            "iPad7,11": .iPad7, "iPad7,12": .iPad7,
            "iPad11,6": .iPad8, "iPad11,7": .iPad8,
            "iPad12,1": .iPad9, "iPad12,2": .iPad9,
            "iPad13,18": .iPad10, "iPad13,19": .iPad10, // iPad 10a gen (2022)

            // iPad Air
            "iPad4,1": .iPadAir, "iPad4,2": .iPadAir, "iPad4,3": .iPadAir,
            "iPad5,3": .iPadAir2, "iPad5,4": .iPadAir2,
            "iPad11,3": .iPadAir3, "iPad11,4": .iPadAir3,
            "iPad13,1": .iPadAir4, "iPad13,2": .iPadAir4,
            "iPad13,16": .iPadAir5, "iPad13,17": .iPadAir5, // M1 (2022)
            "iPad14,8": .iPadAir6_11,  "iPad14,9": .iPadAir6_11,  // 11" M2 (2024) Wi-Fi/Cell
            "iPad14,10": .iPadAir6_13, "iPad14,11": .iPadAir6_13, // 13" M2 (2024) Wi-Fi/Cell

            // iPad Mini
            "iPad2,5": .iPadMini, "iPad2,6": .iPadMini, "iPad2,7": .iPadMini,
            "iPad4,4": .iPadMini2, "iPad4,5": .iPadMini2, "iPad4,6": .iPadMini2,
            "iPad4,7": .iPadMini3, "iPad4,8": .iPadMini3, "iPad4,9": .iPadMini3,
            "iPad5,1": .iPadMini4, "iPad5,2": .iPadMini4,
            "iPad11,1": .iPadMini5, "iPad11,2": .iPadMini5,
            "iPad14,1": .iPadMini6, "iPad14,2": .iPadMini6,

            // iPad Pro 9.7 / 10.5
            "iPad6,3": .iPadPro9_7, "iPad6,4": .iPadPro9_7,
            "iPad7,3": .iPadPro10_5, "iPad7,4": .iPadPro10_5,

            // iPad Pro 12.9 (1ª–7ª) e 11" (1ª–5ª)
            "iPad6,7": .iPadPro12_9, "iPad6,8": .iPadPro12_9,
            "iPad7,1": .iPadPro2_12_9, "iPad7,2": .iPadPro2_12_9,

            "iPad8,1": .iPadPro11, "iPad8,2": .iPadPro11, "iPad8,3": .iPadPro11, "iPad8,4": .iPadPro11, // 11" (2018)
            "iPad8,11": .iPadPro4_12_9, "iPad8,12": .iPadPro4_12_9, // 12.9 4ª (2020)
            "iPad8,9": .iPadPro2_11, "iPad8,10": .iPadPro2_11, // 11" 2ª (2020)

            "iPad13,4": .iPadPro3_11, "iPad13,5": .iPadPro3_11, "iPad13,6": .iPadPro3_11, "iPad13,7": .iPadPro3_11, // 11" 3ª (2021)
            "iPad13,8": .iPadPro5_12_9, "iPad13,9": .iPadPro5_12_9, "iPad13,10": .iPadPro5_12_9, "iPad13,11": .iPadPro5_12_9, // 12.9 5ª (2021)

            "iPad14,3": .iPadPro4_11, "iPad14,4": .iPadPro4_11, // 11" 4ª (M2, 2022)
            "iPad14,5": .iPadPro6_12_9, "iPad14,6": .iPadPro6_12_9, // 12.9 6ª (M2, 2022)

            // iPad Pro M4 (2024) — 11" 5ª e 13" 7ª
            "iPad16,3": .iPadPro5_11, "iPad16,4": .iPadPro5_11,
            "iPad16,5": .iPadPro7_13, "iPad16,6": .iPadPro7_13,

            // iPhone (clássicos)
            "iPhone3,1": .iPhone4, "iPhone3,2": .iPhone4, "iPhone3,3": .iPhone4,
            "iPhone4,1": .iPhone4S,
            "iPhone5,1": .iPhone5, "iPhone5,2": .iPhone5,
            "iPhone5,3": .iPhone5C, "iPhone5,4": .iPhone5C,
            "iPhone6,1": .iPhone5S, "iPhone6,2": .iPhone5S,
            "iPhone7,1": .iPhone6Plus, "iPhone7,2": .iPhone6,
            "iPhone8,1": .iPhone6S, "iPhone8,2": .iPhone6SPlus,
            "iPhone8,4": .iPhoneSE,
            "iPhone9,1": .iPhone7, "iPhone9,3": .iPhone7,
            "iPhone9,2": .iPhone7Plus, "iPhone9,4": .iPhone7Plus,
            "iPhone10,1": .iPhone8, "iPhone10,4": .iPhone8,
            "iPhone10,2": .iPhone8Plus, "iPhone10,5": .iPhone8Plus,
            "iPhone10,3": .iPhoneX, "iPhone10,6": .iPhoneX,
            "iPhone11,2": .iPhoneXS,
            "iPhone11,4": .iPhoneXSMax, "iPhone11,6": .iPhoneXSMax,
            "iPhone11,8": .iPhoneXR,
            "iPhone12,1": .iPhone11,
            "iPhone12,3": .iPhone11Pro,
            "iPhone12,5": .iPhone11ProMax,
            "iPhone12,8": .iPhoneSE2ndG,

            // iPhone 12/13/SE3
            "iPhone13,1": .iPhone12Mini, "iPhone13,2": .iPhone12, "iPhone13,3": .iPhone12Pro, "iPhone13,4": .iPhone12ProMax,
            "iPhone14,4": .iPhone13Mini, "iPhone14,5": .iPhone13,
            "iPhone14,2": .iPhone13Pro, "iPhone14,3": .iPhone13ProMax,
            "iPhone14,6": .iPhoneSE3ndG,

            // iPhone 14
            "iPhone14,7": .iPhone14, "iPhone14,8": .iPhone14Plus,
            "iPhone15,2": .iPhone14Pro, "iPhone15,3": .iPhone14ProMax,

            // iPhone 15 (corrigido)
            "iPhone15,4": .iPhone15,
            "iPhone15,5": .iPhone15Plus,
            "iPhone16,1": .iPhone15Pro,
            "iPhone16,2": .iPhone15ProMax,

            // iPhone 16 (2024)
            "iPhone17,3": .iPhone16,
            "iPhone17,4": .iPhone16Plus,
            "iPhone17,1": .iPhone16Pro,
            "iPhone17,2": .iPhone16ProMax,
            "iPhone17,5": .iPhone16e, // linha econômica (quando aplicável)

            // Apple TV
            "AppleTV5,3": .AppleTV,        // HD (4ª)
            "AppleTV11,1": .AppleTV_4K,    // 4K (2ª, 2021)
            "AppleTV14,1": .AppleTV_4K_3rd, // 4K (3ª, 2022)

            // HomePod
            "AudioAccessory1,1": .Homepod, // HomePod (1ª)
            "AudioAccessory1,2": .Homepod, // HomePod (1ª rev)
            "AudioAccessory5,1": .HomepodMini, // HomePod mini
            "AudioAccessory6,1": .Homepod     // HomePod (2ª)
        ]

        if let modelCode,
           let model = modelMap[modelCode] {

            // Resolver modelo real no Simulator
            if model == .simulator,
               let simModel = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"],
               let real = modelMap[simModel] {
                return real
            }
            return model
        }
        return .unrecognized
    }
}

// MARK: - Device Model via API

/// Resposta do endpoint de modelos de dispositivo
private struct DeviceModelAPIResponse: Decodable {
    let modelIdentifier: String
    let modelName: String
}

/// Resolve o nome do modelo do dispositivo consultando a API,
/// com cache em memória e fallback para o `UIDevice.current.type.rawValue`.
final class DeviceModelResolver {
    static let shared = DeviceModelResolver()

    private init() {}

    private var cachedModelName: String?
    private var isFetching = false
    private var pendingCompletions: [(String) -> Void] = []

    /// Retorna o nome do modelo para uso em formulários (ex: contato).
    /// - A ordem de preferência é:
    ///   1. Nome vindo da API (`modelName`)
    ///   2. Fallback local do `Dispositivo.swift` (`UIDevice.current.type.rawValue`)
    func resolveModelName(completion: @escaping (String) -> Void) {
        // Se já temos em cache, retorna imediatamente
        if let cached = cachedModelName {
            completion(cached)
            return
        }

        let fallbackName = UIDevice.current.type.rawValue

        // Evita múltiplas requisições simultâneas
        if isFetching {
            pendingCompletions.append(completion)
            return
        }

        isFetching = true
        pendingCompletions.append(completion)

        let identifier = DeviceModelResolver.currentModelIdentifier()
        let urlString = "https://devapi.virtueslab.app/15.0/device_models.php?model=\(identifier)"

        guard let url = URL(string: urlString) else {
            completeAll(with: fallbackName)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            var resolvedName = fallbackName

            defer {
                self.completeAll(with: resolvedName)
            }

            if let error = error {
                print("⚠️ Erro ao buscar modelo do dispositivo: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("⚠️ Resposta vazia ao buscar modelo do dispositivo")
                return
            }

            do {
                let decoded = try JSONDecoder().decode(DeviceModelAPIResponse.self, from: data)
                let name = decoded.modelName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty {
                    resolvedName = name
                }
            } catch {
                print("⚠️ Falha ao decodificar modelo do dispositivo: \(error.localizedDescription)")
            }
        }.resume()
    }

    private func completeAll(with name: String) {
        DispatchQueue.main.async {
            self.cachedModelName = name
            self.isFetching = false
            let completions = self.pendingCompletions
            self.pendingCompletions.removeAll()
            completions.forEach { $0(name) }
        }
    }

    /// Obtém o identificador bruto do modelo (ex: "iPhone14,7").
    private static func currentModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let identifier = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { ptr in
                String(validatingUTF8: ptr) ?? "Unknown"
            }
        }
        return identifier
    }
}
