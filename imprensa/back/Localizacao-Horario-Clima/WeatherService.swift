import Foundation
import Combine
import CoreLocation
import SwiftUI

public struct DailyForecast: Identifiable {
    public let id = UUID()
    public let dateISO: String
    public let min: Int
    public let max: Int
    public let code: Int
}

struct WeatherCondition {
    let iconName: String  // Mantido para compatibilidade com SF Symbols
    let assetName: String // Nome do asset no Assets
    let description: String
    
    // Método para criar a partir de código numérico (mantido para compatibilidade)
    static func from(code: Int) -> WeatherCondition {
        switch code {
        case 0:            return .init(iconName: "sun.max.fill", assetName: "icon_clima_ensolarado", description: "Céu limpo")
        case 1,2,3:        return .init(iconName: "cloud.sun.fill", assetName: "icon_clima_parc_nublado", description: "Nublado")
        case 45,48:        return .init(iconName: "cloud.fog.fill", assetName: "icon_clima_nublado", description: "Neblina")
        case 51,53,55:     return .init(iconName: "cloud.drizzle.fill", assetName: "icon_clima_chuva_fraca", description: "Chuvisco")
        case 61,63,65:     return .init(iconName: "cloud.rain.fill", assetName: "icon_clima_chuva", description: "Chuva")
        case 71,73,75,77:  return .init(iconName: "cloud.snow.fill", assetName: "icon_clima_parc_nublado", description: "Neve")
        case 80,81,82:     return .init(iconName: "cloud.heavyrain.fill", assetName: "icon_clima_chuva", description: "Chuva forte")
        case 95,96,99:     return .init(iconName: "cloud.bolt.rain.fill", assetName: "icon_clima_tempestade", description: "Tempestade")
        default:           return .init(iconName: "questionmark.circle", assetName: "icon_clima_nublado", description: "Desconhecido")
        }
    }
    
    // Método para criar diretamente a partir do texto da API do Climatempo
    static func from(text: String?) -> WeatherCondition {
        guard let text = text?.lowercased() else {
            return .init(iconName: "questionmark.circle", assetName: "icon_clima_nublado", description: "Desconhecido")
        }
        
        let hour = Calendar.current.component(.hour, from: Date())
        let isNight = hour >= 18 || hour < 6
        
        // Mapeia diretamente as condições da API do Climatempo para os assets
        if text.contains("tempestade") || text.contains("trovoada") {
            if text.contains("chuva") {
                return .init(iconName: "cloud.bolt.rain.fill", assetName: "icon_clima_tempestade", description: "Chuva com tempestade")
            } else {
                return .init(iconName: "cloud.bolt.rain.fill", assetName: "icon_clima_tempestade", description: "Tempestade")
            }
        } else if text.contains("chuva") && text.contains("sol") {
            return .init(iconName: "cloud.sun.rain.fill", assetName: "icon_clima_chuva", description: "Chuva e sol")
        } else if text.contains("chuva") {
            if isNight {
                return .init(iconName: "cloud.rain.fill", assetName: "icon_clima_chuva", description: "Chuva")
            } else {
                return .init(iconName: "cloud.rain.fill", assetName: "icon_clima_chuva", description: "Chuva")
            }
        } else if text.contains("sol") && text.contains("nuvens") {
            return .init(iconName: "cloud.sun.fill", assetName: "icon_clima_parc_nublado", description: "Sol com nuvens")
        } else if text.contains("sol") && !text.contains("nuvens") {
            return .init(iconName: "sun.max.fill", assetName: "icon_clima_ensolarado", description: "Sol")
        } else if text.contains("céu limpo") || text.contains("ceu limpo") {
            if isNight {
                return .init(iconName: "moon.fill", assetName: "icon_clima_ensolarado", description: "Céu limpo")
            } else {
                return .init(iconName: "sun.max.fill", assetName: "icon_clima_ensolarado", description: "Céu limpo")
            }
        } else if text.contains("nublado") || text.contains("nuvens") {
            if isNight {
                return .init(iconName: "cloud.fill", assetName: "icon_clima_parc_nublado", description: "Nublado")
            } else {
                return .init(iconName: "cloud.fill", assetName: "icon_clima_parc_nublado", description: "Nublado")
            }
        } else if text.contains("chuvisco") || text.contains("garoa") {
            return .init(iconName: "cloud.drizzle.fill", assetName: "icon_clima_chuva", description: "Chuvisco")
        } else if text.contains("neblina") || text.contains("névoa") {
            return .init(iconName: "cloud.fog.fill", assetName: "icon_clima_nublado", description: "Neblina")
        } else if text.contains("neve") {
            return .init(iconName: "cloud.snow.fill", assetName: "icon_clima_chuva", description: "Neve")
        } else {
            // Retorna a descrição original da API
            return .init(iconName: "cloud.fill", assetName: "icon_clima_nublado", description: text.capitalized)
        }
    }
}

// ====== Modelos ClimaTempo ======
private struct CTDayIndex: Decodable {
    let cidade: String
    let json: String // "dias/DD-MM-YYYY/ID.json"
}

private struct CTResponse: Decodable {
    // MS Health - Saúde e bem-estar
    struct MSHealth: Decodable {
        struct HealthItem: Decodable {
            let condition: String?
            let incidence: Int?
            let description: String?
        }
        let mosquito: HealthItem?
        let skindryness: HealthItem?
        let flu_cold: HealthItem?
        let iuv: HealthItem?
        let vitaminD: HealthItem?
        let airQuality: HealthItem?
    }
    
    // Current Weather - Clima atual
    struct Current: Decodable {
        let temperature: Int?
        let humidity: Int?
        let windVelocity: Int?
        let condition: String?
        let windDirection: String?
        let pressure: Int?
        let sensation: Int?
    }
    
    // Volume of Rain - Volume de chuva
    struct VolumeOfRain: Decodable {
        let todayTmin: Double?
        let todayTmax: Double?
        let todayPrecipitation: String?
    }
    
    // Daily Forecast - Previsão diária
    struct CTDaily: Decodable {
        struct TextIcon: Decodable {
            struct Texts: Decodable { let pt: String? }
            let text: Texts?
        }
        struct Temp: Decodable { let min: Int?; let max: Int? }
        struct Rain: Decodable { let probability: Int?; let precipitation: String? }
        let date: String?              // "YYYY-MM-DD"
        let textIcon: TextIcon?
        let temperature: Temp?
        let rain: Rain?
    }
    
    // Hourly Data - Dados horários
    struct HourlyData: Decodable {
        struct Wind: Decodable {
            let velocity: Int?
            let direction_degrees: Int?
            let direction: String?
        }
        struct Temperature: Decodable {
            let temperature: Int?
        }
        struct Rain: Decodable {
            let precipitation: String?
        }
        struct Pressure: Decodable {
            let pressure: Int?
        }
        struct Humidity: Decodable {
            let relativeHumidity: Int?
        }
        struct Icon: Decodable {
            let resource: String?
        }
        let date: String?              // "2025-11-19T11:00:00"
        let wind: Wind?
        let temperature: Temperature?
        let rain: Rain?
        let pressure: Pressure?
        let humidity: Humidity?
        let icon: Icon?
    }
    
    let msHealth: MSHealth?
    let currentWeather: Current?
    let volumeOfRain: VolumeOfRain?
    let dailyForecast: [CTDaily]?
    let hourly: [HourlyData]?
    let hourlyForecast: [String: [HourlyData]]?  // Dicionário com chave "YYYY-MM-DD" e valor array de HourlyData
}

@MainActor
final class WeatherService: ObservableObject {
    // Publicados usados na UI - Clima básico
    @Published var currentTemp: Int?
    @Published var condition: WeatherCondition?
    @Published var minTemp: Int?
    @Published var maxTemp: Int?
    @Published var humidityPct: Int?
    @Published var precipProbPct: Int?
    @Published var windKmh: Int?
    @Published var daily: [DailyForecast] = []
    @Published var hourlyTemperatures: [(date: Date, temp: Int)] = [] // Dados para o gráfico
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Publicados - Saúde e bem-estar (MS Health)
    @Published var mosquitoCondition: String?
    @Published var mosquitoIncidence: Int?
    @Published var mosquitoDescription: String?
    
    @Published var skinDrynessCondition: String?
    @Published var skinDrynessIncidence: Int?
    @Published var skinDrynessDescription: String?
    
    @Published var fluColdCondition: String?
    @Published var fluColdIncidence: Int?
    @Published var fluColdDescription: String?
    
    @Published var uvIndexCondition: String?
    @Published var uvIndexIncidence: Int?
    @Published var uvIndexDescription: String?
    
    @Published var vitaminDCondition: String?
    @Published var vitaminDIncidence: Int?
    @Published var vitaminDDescription: String?
    
    @Published var airQualityCondition: String?
    @Published var airQualityIncidence: Int?
    @Published var airQualityDescription: String?
    
    private var lastFetchAt: Date?
    private var lastFetchLocation: CLLocation?
    private let minFetchInterval: TimeInterval = 60 * 10 // 10 min
    private let minDistanceToRefetch: CLLocationDistance = 500 // 500 m

    // Cache simples
    private var lastCityName: String?
    private var lastDayPath: String?
    
    // MARK: - Funções auxiliares para cores dos índices
    /// Retorna a cor baseada na condição e incidência para mosquitos
    func colorForMosquito() -> Color {
        guard let condition = mosquitoCondition?.lowercased() else { return .gray }
        if condition.contains("alto") || (mosquitoIncidence ?? 0) >= 7 {
            return .red
        } else if condition.contains("médio") || (mosquitoIncidence ?? 0) >= 4 {
            return .orange
        } else {
            return .green
        }
    }
    
    
    
    /// Retorna a cor baseada na condição e incidência para gripe/resfriado
    func colorForFluCold() -> Color {
        guard let condition = fluColdCondition?.lowercased() else { return .gray }
        if condition.contains("alto") || (fluColdIncidence ?? 0) >= 7 {
            return .red
        } else if condition.contains("médio") || (fluColdIncidence ?? 0) >= 4 {
            return .orange
        } else {
            return .green
        }
    }
    
    /// Retorna a cor baseada na condição e incidência para vitamina D
    func colorForVitaminD() -> Color {
        guard let condition = vitaminDCondition?.lowercased() else { return .gray }
        if condition.contains("alta") || (vitaminDIncidence ?? 0) >= 7 {
            return .green
        } else if condition.contains("média") || (vitaminDIncidence ?? 0) >= 4 {
            return .yellow
        } else {
            return .orange
        }
    }
    
    /// Retorna a cor baseada na condição e incidência para ressecamento de pele
    func colorForSkinDryness() -> Color {
        guard let condition = skinDrynessCondition?.lowercased() else { return .gray }
        if condition.contains("nenhum alerta") || (skinDrynessIncidence ?? 0) == 0 {
            return .green
        } else if condition.contains("baixo") || (skinDrynessIncidence ?? 0) <= 3 {
            return .yellow
        } else {
            return .orange
        }
    }
    
    /// Retorna a cor baseada na condição e incidência para índice UV
    func colorForUVIndex() -> Color {
        guard let condition = uvIndexCondition?.lowercased() else { return .gray }
        if condition.contains("muito alto") || condition.contains("extremo") || (uvIndexIncidence ?? 0) >= 8 {
            return .red
        } else if condition.contains("alto") || (uvIndexIncidence ?? 0) >= 6 {
            return .orange
        } else if condition.contains("médio") || (uvIndexIncidence ?? 0) >= 3 {
            return .yellow
        } else {
            return .green
        }
    }
    
    /// Retorna a cor baseada na condição e incidência para qualidade do ar
    func colorForAirQuality() -> Color {
        guard let condition = airQualityCondition?.lowercased() else { return .gray }
        if condition.contains("bom") || condition.contains("excelente") || (airQualityIncidence ?? 0) <= 30 {
            return .green
        } else if condition.contains("moderado") || (airQualityIncidence ?? 0) <= 60 {
            return .yellow
        } else if condition.contains("ruim") || (airQualityIncidence ?? 0) <= 80 {
            return .orange
        } else {
            return .red
        }
    }

    // === Entrada por latitude/longitude ===
    func fetchWeather(latitude: Double, longitude: Double, specificDay: String? = nil) {
        Task {
            await loadByCoordinates(latitude: latitude, longitude: longitude, specificDay: specificDay)
        }
    }
    
    func shouldFetch(for location: CLLocation) -> Bool {
        if isLoading { return false }

        if let last = lastFetchLocation {
            let dist = location.distance(from: last)
            if dist < minDistanceToRefetch {
                if let t = lastFetchAt, Date().timeIntervalSince(t) < minFetchInterval {
                    return false
                }
            }
        }
        return true
    }

    // MARK: - Fluxo principal
    private func loadByCoordinates(latitude: Double, longitude: Double, specificDay: String?) async {

        // =========================
        // ✅ 0) THROTTLE / CACHE
        // =========================
        let newLoc = CLLocation(latitude: latitude, longitude: longitude)

        // Se já temos dados e o fetch anterior foi recente e a localização não mudou muito,
        // não refaz request (evita recarregar quando volta pra ContentView).
        if let lastLoc = lastFetchLocation,
           let lastAt = lastFetchAt,
           Date().timeIntervalSince(lastAt) < minFetchInterval {

            let dist = newLoc.distance(from: lastLoc)

            // Se a UI já está preenchida, evita ficar "piscando" com loading de novo
            let alreadyHasData = (currentTemp != nil || !daily.isEmpty)

            if dist < minDistanceToRefetch && alreadyHasData && specificDay == nil {
                print("⏳ WeatherService: ignorando fetch (cache) — dist=\(Int(dist))m, age=\(Int(Date().timeIntervalSince(lastAt)))s")
                return
            }
        }

        // Marca a tentativa agora (antes mesmo de baixar, pra evitar spam de chamadas)
        lastFetchAt = Date()
        lastFetchLocation = newLoc
        
        
        isLoading = true
        errorMessage = nil
        daily.removeAll()
        hourlyTemperatures.removeAll()

        do {
            // 0) Coordenadas e geocoder
            print("🌍 Coordenadas recebidas: lat=\(latitude), lon=\(longitude)")
            let cityName = try await reverseGeocodeCity(latitude: latitude, longitude: longitude)
            print("🏙 Cidade obtida do geocoder: \(cityName)")

            // 1) Carrega lista de dias
            let indexURL = URL(string: "https://climatempo.ticketss.app/index.json")!
            let dayPaths: [String] = try await get(indexURL)
            print("📅 Dias disponíveis no índice: \(dayPaths.count)")

            // Decide o dia a usar
            let dayPath: String
            if let s = specificDay {
                dayPath = try dayPathForSpecificDay(s, from: dayPaths)
                print("📅 Usando dia específico \(s) → \(dayPath)")
            } else if let cached = lastDayPath, dayPaths.contains(cached) {
                dayPath = cached
                print("📅 Usando dia do cache → \(dayPath)")
            } else {
                dayPath = try mostRecentDayPath(from: dayPaths)
                print("📅 Usando dia mais recente → \(dayPath)")
            }
            lastDayPath = dayPath

            // 2) Índice do dia → cidades
            let dayIndexURL = URL(string: "https://climatempo.ticketss.app/\(dayPath)")!
            let cities: [CTDayIndex] = try await get(dayIndexURL)
            print("🏙 Total de cidades para o dia: \(cities.count)")

            // Log das primeiras cidades (útil para comparar com o geocoder)
            let preview = cities.prefix(10).map { $0.cidade }
            print("🔎 Amostra de cidades [0..\(preview.count)]: \(preview)")

            // Procura a cidade
            let chosen = pickCity(cities: cities, name: cityName) ?? cities.first
            guard let chosen else {
                print("⚠️ Nenhuma cidade encontrada no índice para \(cityName)")
                throw NSError(domain: "CT", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cidade não encontrada no índice do dia"])
            }
            print("✅ Cidade escolhida: \(chosen.cidade) → JSON: \(chosen.json)")
            lastCityName = cityName

            // 3) Baixa JSON da cidade
            let cityURL = URL(string: "https://climatempo.ticketss.app/\(chosen.json)")!
            let ct: CTResponse = try await get(cityURL)

            // Logs dos principais campos
            print("🌡 Temp atual: \(ct.currentWeather?.temperature.map(String.init) ?? "n/d") °C")
            print("💧 Umidade: \(ct.currentWeather?.humidity.map(String.init) ?? "n/d") %")
            print("💨 Vento: \(ct.currentWeather?.windVelocity.map(String.init) ?? "n/d") km/h")
            if let vr = ct.volumeOfRain {
                print("📈 Tmin/Tmax hoje (volumeOfRain): \(vr.todayTmin?.description ?? "n/d") / \(vr.todayTmax?.description ?? "n/d")")
            }
            if let firstDay = ct.dailyForecast?.first {
                print("🗓 Primeiro dia em dailyForecast: \(firstDay.date ?? "n/d")")
                print("   └ Prob. chuva: \(firstDay.rain?.probability.map(String.init) ?? "n/d")%")
                print("   └ Texto PT: \(firstDay.textIcon?.text?.pt ?? "n/d")")
                print("   └ Min/Max: \(firstDay.temperature?.min.map(String.init) ?? "n/d") / \(firstDay.temperature?.max.map(String.init) ?? "n/d")")
            } else {
                print("🗓 dailyForecast ausente ou vazio")
            }

            // Logs MS Health
            if let health = ct.msHealth {
                print("🦟 Mosquitos: \(health.mosquito?.condition ?? "n/d") (incidência: \(health.mosquito?.incidence ?? -1))")
                print("🌡 UV: \(health.iuv?.condition ?? "n/d") (incidência: \(health.iuv?.incidence ?? -1))")
                print("💊 Vitamina D: \(health.vitaminD?.condition ?? "n/d") (incidência: \(health.vitaminD?.incidence ?? -1))")
                print("🌬 Qualidade do ar: \(health.airQuality?.condition ?? "n/d") (incidência: \(health.airQuality?.incidence ?? -1))")
            }
            
            // 4) Extrai dados horários baseados na hora atual do hourlyForecast
            let hourlyData = extractCurrentHourlyData(from: ct.hourlyForecast)
            if let hourly = hourlyData {
                print("⏰ Dados horários encontrados para hora atual:")
                print("   └ Temp: \(hourly.temperature?.temperature.map(String.init) ?? "n/d")°C")
                print("   └ Umidade: \(hourly.humidity?.relativeHumidity.map(String.init) ?? "n/d")%")
                print("   └ Vento: \(hourly.wind?.velocity.map(String.init) ?? "n/d") km/h")
                print("   └ Chuva: \(hourly.rain?.precipitation ?? "n/d") mm")
            } else {
                print("⚠️ Nenhum dado horário encontrado no hourlyForecast")
            }
            
            // 4.5) Preenche dados horários para o gráfico
            print("🔍 Verificando dados para gráfico...")
            if let hf = ct.hourlyForecast {
                print("   └ hourlyForecast tem \(hf.count) chaves: \(hf.keys.sorted().prefix(3))")
                for (key, values) in hf.prefix(3) {
                    print("   └ \(key): \(values.count) pontos")
                }
            } else {
                print("   └ hourlyForecast é nil")
            }
            if let h = ct.hourly {
                print("   └ hourly tem \(h.count) pontos")
            } else {
                print("   └ hourly é nil")
            }
            
            self.hourlyTemperatures = extractHourlyTemperaturesForChart(from: ct.hourlyForecast, or: ct.hourly)
            print("📊 Dados para gráfico: \(self.hourlyTemperatures.count) pontos")

            // 5) Preenche publicados - Clima básico
            // SEMPRE usa dados horários do hourlyForecast, nunca currentWeather para temperatura
            if let hourly = hourlyData {
                self.currentTemp = hourly.temperature?.temperature
                self.humidityPct = hourly.humidity?.relativeHumidity
                self.windKmh = hourly.wind?.velocity
                if let precip = hourly.rain?.precipitation {
                    // Se houver precipitação horária, pode ser usado como referência
                    print("💧 Precipitação horária: \(precip) mm")
                }
            } else {
                // Fallback apenas se hourlyForecast não estiver disponível
                print("⚠️ Usando fallback de currentWeather (não recomendado)")
                if let t = ct.currentWeather?.temperature { self.currentTemp = t }
                self.humidityPct = ct.currentWeather?.humidity
                self.windKmh = ct.currentWeather?.windVelocity
            }

            if let tmin = ct.volumeOfRain?.todayTmin, let tmax = ct.volumeOfRain?.todayTmax {
                self.minTemp = Int(round(tmin))
                self.maxTemp = Int(round(tmax))
            } else if let today = ct.dailyForecast?.first {
                self.minTemp = today.temperature?.min
                self.maxTemp = today.temperature?.max
            }

            if let pp = ct.dailyForecast?.first?.rain?.probability {
                self.precipProbPct = pp
            }

            // Usa diretamente a condição da API do Climatempo
            let conditionText = ct.currentWeather?.condition
                ?? ct.dailyForecast?.first?.textIcon?.text?.pt
            self.condition = WeatherCondition.from(text: conditionText)

            self.daily = (ct.dailyForecast ?? [])
                .prefix(7)
                .compactMap { d in
                    guard let iso = d.date,
                          let min = d.temperature?.min,
                          let max = d.temperature?.max else { return nil }
                    // Usa a condição diretamente da API para o código
                    let conditionText = d.textIcon?.text?.pt
                    let code = inferCode(fromPT: conditionText)
                    return DailyForecast(dateISO: iso, min: min, max: max, code: code)
                }
            
            // 6) Preenche publicados - Saúde e bem-estar (MS Health)
            if let health = ct.msHealth {
                // Mosquitos
                self.mosquitoCondition = health.mosquito?.condition
                self.mosquitoIncidence = health.mosquito?.incidence
                self.mosquitoDescription = health.mosquito?.description
                
                // Ressecamento de pele
                self.skinDrynessCondition = health.skindryness?.condition
                self.skinDrynessIncidence = health.skindryness?.incidence
                self.skinDrynessDescription = health.skindryness?.description
                
                // Gripe/Resfriado
                self.fluColdCondition = health.flu_cold?.condition
                self.fluColdIncidence = health.flu_cold?.incidence
                self.fluColdDescription = health.flu_cold?.description
                
                // Índice UV
                self.uvIndexCondition = health.iuv?.condition
                self.uvIndexIncidence = health.iuv?.incidence
                self.uvIndexDescription = health.iuv?.description
                
                // Vitamina D
                self.vitaminDCondition = health.vitaminD?.condition
                self.vitaminDIncidence = health.vitaminD?.incidence
                self.vitaminDDescription = health.vitaminD?.description
                
                // Qualidade do ar
                self.airQualityCondition = health.airQuality?.condition
                self.airQualityIncidence = health.airQuality?.incidence
                self.airQualityDescription = health.airQuality?.description
                }

            print("✅ Publicados atualizados: temp=\(self.currentTemp ?? -999)°C, min=\(self.minTemp ?? -999), max=\(self.maxTemp ?? -999), hum=\(self.humidityPct ?? -1)%, vento=\(self.windKmh ?? -1)km/h, pp=\(self.precipProbPct ?? -1)%")
            print("📦 daily.count=\(self.daily.count)")

        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ Erro ao carregar clima: \(error)")
        }

        isLoading = false
    }


    // MARK: - Rede/JSON
    private func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func dayPathForSpecificDay(_ ddmmyyyy: String, from paths: [String]) throws -> String {
        let wanted = "dias/\(ddmmyyyy)/index.json"
        if paths.contains(where: { $0 == wanted }) { return wanted }
        throw NSError(domain: "CT", code: 3, userInfo: [NSLocalizedDescriptionKey: "Dia \(ddmmyyyy) não disponível"])
    }

    private func mostRecentDayPath(from paths: [String]) throws -> String {
        // paths no formato: "dias/DD-MM-YYYY/index.json"
        let df = DateFormatter()
        df.dateFormat = "dd-MM-yyyy"
        df.timeZone = .autoupdatingCurrent

        // Mapeia cada path para (path, date) de forma segura e tipada
        let tuples: [(path: String, date: Date)] = paths.compactMap { path in
            // Quebra o path
            // ["dias", "DD-MM-YYYY", "index.json"]
            let comps = path.split(separator: "/")
            guard comps.count >= 3 else { return nil }

            let dayToken = String(comps[1]) // "DD-MM-YYYY"
            guard let date = df.date(from: dayToken) else { return nil }

            return (path: path, date: date)
        }

        guard let best = tuples.max(by: { $0.date < $1.date }) else {
            throw NSError(domain: "CT",
                          code: 4,
                          userInfo: [NSLocalizedDescriptionKey: "Nenhum dia encontrado"])
        }

        return best.path
    }


    private func pickCity(cities: [CTDayIndex], name: String) -> CTDayIndex? {
        let normTarget = normalize(name)

        // 1) Match exato
        if let exact = cities.first(where: { normalize($0.cidade) == normTarget }) {
            print("🔎 pickCity: match EXATO com '\(exact.cidade)'")
            return exact
        }

        // 2) Match parcial (agora nos DOIS sentidos)
        if let partial = cities.first(where: {
            let c = normalize($0.cidade)
            return c.contains(normTarget) || normTarget.contains(c)
        }) {
            print("🔎 pickCity: match PARCIAL com '\(partial.cidade)'")
            return partial
        }

        // 3) Heurística por sobreposição de tokens (último recurso)
        let targetTokens = Set(normTarget.split(separator: " "))
        let scored = cities.map { item -> (CTDayIndex, Int) in
            let tokens = Set(normalize(item.cidade).split(separator: " "))
            let score = tokens.intersection(targetTokens).count
            return (item, score)
        }

        if let best = scored.max(by: { $0.1 < $1.1 }), best.1 > 0 {
            print("🔎 pickCity: match por tokens com '\(best.0.cidade)' (score \(best.1))")
            return best.0
        }

        print("⚠️ pickCity: nenhum match encontrado para '\(name)'.")
        return nil
    }


    private func normalize(_ s: String) -> String {
        s.folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .replacingOccurrences(of: " - ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Geocoding (lat/lon → "Cidade - UF")
    private func reverseGeocodeCity(latitude: Double, longitude: Double) async throws -> String {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
        guard let first = placemarks.first else {
            throw NSError(domain: "GEOCODE", code: 1, userInfo: [NSLocalizedDescriptionKey: "Não foi possível obter a cidade"])
        }
        print("📍 Placemark bruto: \(first)")
        let city = first.locality ?? first.subAdministrativeArea ?? first.name ?? "Desconhecida"
        if let uf = first.administrativeArea, !uf.isEmpty {
            return "\(city) - \(uf)"
        }
        return city
    }


    // MARK: - Extração de dados horários
    private func extractCurrentHourlyData(from hourlyForecast: [String: [CTResponse.HourlyData]]?) -> CTResponse.HourlyData? {
        guard let hourlyForecast = hourlyForecast, !hourlyForecast.isEmpty else { return nil }
        
        let now = Date()
        
        // Formata a data atual no formato "YYYY-MM-DD" para buscar no dicionário
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = .autoupdatingCurrent
        let todayKey = dateFormatter.string(from: now)
        
        // Busca o array de dados horários para o dia atual
        guard let todayHourly = hourlyForecast[todayKey], !todayHourly.isEmpty else {
            // Se não encontrar o dia atual, tenta o primeiro dia disponível
            if let firstKey = hourlyForecast.keys.sorted().first,
               let firstHourly = hourlyForecast[firstKey], !firstHourly.isEmpty {
                print("⚠️ Dia atual não encontrado, usando primeiro dia disponível: \(firstKey)")
                return findClosestHourlyData(in: firstHourly, for: now)
            }
            return nil
        }
        
        return findClosestHourlyData(in: todayHourly, for: now)
    }
    
    private func findClosestHourlyData(in hourly: [CTResponse.HourlyData], for date: Date) -> CTResponse.HourlyData? {
        // Formata a data atual no formato esperado: "2025-11-19T11:00:00"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:00:00"
        dateFormatter.timeZone = .autoupdatingCurrent
        
        // Procura o registro mais próximo da hora atual
        // Primeiro tenta encontrar exatamente a hora atual
        let targetDateString = dateFormatter.string(from: date)
        
        if let exact = hourly.first(where: { $0.date == targetDateString }) {
            return exact
        }
        
        // Se não encontrar exato, procura o mais próximo
        let targetDate = dateFormatter.date(from: targetDateString) ?? date
        
        let closest = hourly.min(by: { hour1, hour2 in
            let date1 = parseHourlyDate(hour1.date) ?? Date.distantFuture
            let date2 = parseHourlyDate(hour2.date) ?? Date.distantFuture
            let diff1 = abs(date1.timeIntervalSince(targetDate))
            let diff2 = abs(date2.timeIntervalSince(targetDate))
            return diff1 < diff2
        })
        
        return closest
    }
    
    private func parseHourlyDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        // Tenta primeiro com ISO8601DateFormatter (formato completo com timezone)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: dateString) {
            return date
        }
        
        // Tenta sem frações de segundo
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateString) {
            return date
        }
        
        // Tenta formato simples sem timezone: "2025-12-03T00:00:00"
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        simpleFormatter.timeZone = .autoupdatingCurrent
        if let date = simpleFormatter.date(from: dateString) {
            return date
        }
        
        // Tenta com apenas hora e minuto: "2025-12-03T00:00"
        simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        if let date = simpleFormatter.date(from: dateString) {
            return date
        }
        
        return nil
    }
    
    // MARK: - Extração de dados para gráfico
    private func extractHourlyTemperaturesForChart(from hourlyForecast: [String: [CTResponse.HourlyData]]?, or hourly: [CTResponse.HourlyData]?) -> [(date: Date, temp: Int)] {
        // Primeiro tenta usar hourlyForecast (dicionário)
        if let hourlyForecast = hourlyForecast, !hourlyForecast.isEmpty {
            let now = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = .autoupdatingCurrent
            let todayKey = dateFormatter.string(from: now)
            
            print("   🔍 Procurando chave '\(todayKey)' no hourlyForecast")
            
            // Pega os dados do dia atual, ou o primeiro dia disponível
            let hourlyData: [CTResponse.HourlyData]
            if let todayHourly = hourlyForecast[todayKey], !todayHourly.isEmpty {
                print("   ✅ Encontrado \(todayHourly.count) pontos para hoje")
                hourlyData = todayHourly
            } else if let firstKey = hourlyForecast.keys.sorted().first,
                      let firstHourly = hourlyForecast[firstKey], !firstHourly.isEmpty {
                print("   ⚠️ Usando primeiro dia disponível: \(firstKey) com \(firstHourly.count) pontos")
                hourlyData = firstHourly
            } else {
                print("   ❌ Nenhum dado encontrado no hourlyForecast")
                // Tenta usar o array hourly como fallback
                if let hourly = hourly, !hourly.isEmpty {
                    print("   🔄 Tentando usar array hourly com \(hourly.count) pontos")
                    return processHourlyArray(hourly)
                }
                return []
            }
            
            return processHourlyArray(hourlyData)
        }
        
        // Fallback: usa o array hourly diretamente
        if let hourly = hourly, !hourly.isEmpty {
            print("   🔄 Usando array hourly diretamente com \(hourly.count) pontos")
            return processHourlyArray(hourly)
        }
        
        print("   ❌ Nenhum dado horário disponível")
        return []
    }
    
    private func processHourlyArray(_ hourlyData: [CTResponse.HourlyData]) -> [(date: Date, temp: Int)] {
        print("   🔍 Processando array com \(hourlyData.count) pontos")
        
        let now = Date()
        
        // Filtra e ordena os dados
        var validCount = 0
        var invalidCount = 0
        
        let allValid = hourlyData
            .compactMap { data -> (date: Date, temp: Int)? in
                guard let dateStr = data.date else {
                    invalidCount += 1
                    if invalidCount <= 3 {
                        print("   ⚠️ Item sem date")
                    }
                    return nil
                }
                
                guard let date = parseHourlyDate(dateStr) else {
                    invalidCount += 1
                    if invalidCount <= 3 {
                        print("   ⚠️ Falha ao parsear date: '\(dateStr)'")
                    }
                    return nil
                }
                
                guard let temp = data.temperature?.temperature else {
                    invalidCount += 1
                    if invalidCount <= 3 {
                        print("   ⚠️ Item sem temperatura")
                    }
                    return nil
                }
                
                validCount += 1
                return (date: date, temp: temp)
            }
            .sorted { $0.date < $1.date }
        
        // Filtra apenas os pontos a partir da hora atual
        let fromNow = allValid.filter { $0.date >= now }
        
        // Pega os próximos 5 pontos a partir de agora
        let result = Array(fromNow.prefix(5))
        
        print("   ✅ Processados \(result.count) pontos válidos de \(hourlyData.count) totais (inválidos: \(invalidCount))")
        if !result.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            print("   └ Primeiro (a partir de agora): \(dateFormatter.string(from: result.first!.date)) = \(result.first!.temp)°C")
            print("   └ Último: \(dateFormatter.string(from: result.last!.date)) = \(result.last!.temp)°C")
        } else {
            print("   ⚠️ Nenhum ponto futuro encontrado, usando os primeiros 5 disponíveis")
            // Fallback: se não houver pontos futuros, usa os primeiros 5
            return Array(allValid.prefix(5))
        }
        return result
    }

    // MARK: - Heurísticas condição (PT → código)
    private func mapCondition(fromPT text: String?) -> WeatherCondition? {
        WeatherCondition.from(code: inferCode(fromPT: text))
    }
    private func inferCode(fromPT text: String?) -> Int {
        guard let t = text?.lowercased() else { return 0 }
        if t.contains("tempestade")    { return 95 }
        if t.contains("chuva forte")   { return 82 }
        if t.contains("chuva")         { return 61 }
        if t.contains("neblina")       { return 45 }
        if t.contains("nuvens") || t.contains("nublado") { return 2 }
        if t.contains("geada")         { return 77 }
        if t.contains("sol") || t.contains("céu limpo")  { return 0 }
        return 0
    }
}

