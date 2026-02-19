import SwiftUI
import CoreLocation

/*
 Adicione no Info.plist:

  Privacy - Location Always and When In Use Usage Description : Precisamos da sua localização para mostrar o clima local.
  Privacy - Location When In Use Usage Description            : Precisamos da sua localização para mostrar o clima local.
*/

struct ClimaView: View {
    @EnvironmentObject private var locManager: LocationManager
    @EnvironmentObject private var weatherSvc: WeatherService
    @EnvironmentObject private var router: NavigationRouter
    @Environment(\.dismiss) private var dismiss

    @State private var isSwitchingDay = false
    @State private var switchingTask: Task<Void, Never>?

    // MARK: - Computeds

    private var daysToShow: [DailyForecast] {
        Array(weatherSvc.daily.prefix(5))
    }

    private var selectedDay: DailyForecast? {
        let idx = weatherSvc.selectedDayIndex
        guard idx >= 0, idx < daysToShow.count else { return nil }
        return daysToShow[idx]
    }

    private var selectedIcon: String {
        if let d = selectedDay { return WeatherCondition.from(code: d.code).assetName }
        return weatherSvc.condition?.assetName ?? "ic_sunny"
    }

    private var selectedDesc: String {
        if let d = selectedDay { return WeatherCondition.from(code: d.code).description }
        return weatherSvc.condition?.description ?? "—"
    }

    private var selectedMaxTemp: Int {
        if let d = selectedDay { return d.max }
        return weatherSvc.maxTemp ?? 0
    }

    private var selectedMinTemp: Int {
        if let d = selectedDay { return d.min }
        return weatherSvc.minTemp ?? 0
    }

    private var selectedBackgroundAsset: String {
        // seu selectedIcon já vem de WeatherCondition.from(code: ...)
        let icon = selectedIcon.lowercased()

        // detecta noite pelo nome do ícone (ajuste se seus ícones tiverem outro padrão)
        let isNight =
            icon.contains("night") ||
            icon.contains("_n") ||
            icon.contains("lua")

        // escolhe a "família" do background baseado no ícone
        let family: String
        if icon.contains("rain") || icon.contains("chuva") || icon.contains("storm") || icon.contains("thunder") {
            family = "rainy"
        } else if icon.contains("partly") || icon.contains("partial") || icon.contains("parcial") {
            family = "partially_cloudy"
        } else if icon.contains("cloud") || icon.contains("nublado") || icon.contains("cloudy") {
            family = "cloudy"
        } else if icon.contains("clear") || icon.contains("limpo") {
            family = "clear"
        } else {
            family = "sunny"
        }

        // monta exatamente no padrão dos seus assets
        let name = "img_weather_background_\(family)_\(isNight ? "night" : "day")"
        return name
    }

    private var displayTemp: Int {
        if let t = weatherSvc.currentTemp { return t }
        if let d = selectedDay { return Int(round(Double(d.min + d.max) / 2.0)) }
        return 0
    }

    /// ✅ Critério robusto: se tem daily OU current, já dá pra renderizar conteúdo.
    private var hasData: Bool {
        (weatherSvc.currentTemp != nil) || !weatherSvc.daily.isEmpty
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            if geo.size.width > geo.size.height {
                landscapeView(geo: geo)
            } else {
                portraitView(geo: geo)
            }
        }
        .navigationBarHidden(true)

        // ✅ Sempre volta pra previsão do dia atual ao abrir a view
        .onAppear {
            weatherSvc.selectDay(at: 0)
            fetchIfPossible()
        }

        // ✅ Se a localização atualiza, refaz fetch
        .onChange(of: locManager.lastLocation) { _ in
            fetchIfPossible()
        }

        // ✅ Quando o usuário concede permissão, tenta pegar location e refaz fetch
        .onChange(of: locManager.authStatus) { status in
            if status == .authorizedAlways || status == .authorizedWhenInUse {
                locManager.startOnceIfAuthorized()
                fetchIfPossible()
            }
        }

        // ✅ Quando o daily atualizar, força seleção de “hoje” novamente
        .onChange(of: weatherSvc.daily.count) { _ in
            weatherSvc.selectDay(at: 0)
        }

        // ✅ Loading de troca de dia
        .overlay {
            if isSwitchingDay {
                DaySwitchLoadingOverlay()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isSwitchingDay)
    }

    // MARK: - Orientation Views

    @ViewBuilder
    private func portraitView(geo: GeometryProxy) -> some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack {
                Image(selectedBackgroundAsset)
                    .resizable()
                    .scaledToFit()
                    .offset(y: UIDevice.current.userInterfaceIdiom == .phone ? 0 : geo.size.height * -0.1)
                Spacer()
            }

            // ✅ Lógica robusta de estado (erro/loading/conteúdo/permissão)
            if let error = weatherSvc.errorMessage, !hasData {
                errorView(message: error)
            } else if weatherSvc.isLoading && !hasData {
                loadingView()
            } else if hasData {
                mainContentView(geo: geo)
            } else {
                switch locManager.authStatus {
                case .denied, .restricted:
                    permissionDeniedView(geo: geo)
                case .notDetermined:
                    requestPermissionView(geo: geo)
                default:
                    loadingView()
                }
            }

            VStack {
                Spacer()
                HStack {
                    Button(action: { router.go(to: .menu) }) {
                        Image("btn_return")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90)
                    }
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private func landscapeView(geo: GeometryProxy) -> some View {
        ZStack {
            Color.white.ignoresSafeArea()

            HStack {
                Spacer()
                Image(selectedBackgroundAsset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 250, height: 300)
                    .rotationEffect(.degrees(90))
                    .ignoresSafeArea()
            }
            .ignoresSafeArea()

            // ✅ Mesmo gate de estado no landscape também
            if let error = weatherSvc.errorMessage, !hasData {
                errorView(message: error)
            } else if weatherSvc.isLoading && !hasData {
                loadingView()
            } else if hasData {
                landscapeContent(geo: geo)
            } else {
                switch locManager.authStatus {
                case .denied, .restricted:
                    permissionDeniedView(geo: geo)
                case .notDetermined:
                    requestPermissionView(geo: geo)
                default:
                    loadingView()
                }
            }

            VStack {
                Spacer()
                HStack {
                    Button(action: { router.go(to: .menu) }) {
                        Image("btn_return")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120)
                    }
                    Spacer()
                }
            }
            .padding(.bottom, 10)
            .padding(.leading, 10)
        }
    }

    @ViewBuilder
    private func landscapeContent(geo: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            // Main Content
            VStack(spacing: 10) {
                HStack(alignment: .top) {
                    ZStack {
                        Image("bg_weather_location")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 45)

                        HStack(spacing: 5) {
                            Text(locManager.city ?? "Salvador")
                                .font(.custom("Spartan-Regular", size: 16))
                            Text(locManager.state ?? "BA")
                                .font(.custom("Spartan-Bold", size: 16))
                        }
                        .foregroundColor(.white)
                        .padding(.trailing, 15)
                    }

                    Spacer()

                    HeaderDateTimeView()
                        .padding(.trailing, 30)

                    Image("bg_triangle_nav_buttons")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .padding(.top, 5)
                        .padding(.trailing, 10)
                }
                .padding(.top, 10)

                Divider().padding(.horizontal, 30)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 15) {

                        // Forecast Row
                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(white: 0.96))
                                .frame(height: 95)

                            HStack(spacing: 10) {
                                ForEach(Array(daysToShow.enumerated()), id: \.offset) { index, day in
                                    ForecastBox(
                                        day: shortWeekday(day.dateISO),
                                        icon: WeatherCondition.from(code: day.code).assetName,
                                        tempMax: "\(day.max)°",
                                        tempMin: "\(day.min)°",
                                        isActive: index == weatherSvc.selectedDayIndex,
                                        onTap: { switchDay(index) }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 30)

                        // Graph Card
                        ZStack {
                            RoundedRectangle(cornerRadius: 1)
                                .stroke(Color(red: 26/255, green: 60/255, blue: 104/255), lineWidth: 1.5)
                                .background(Color.white)

                            VStack(spacing: 0) {
                                HStack {
                                    let data = weatherSvc.hourlyTemperatures
                                    if !data.isEmpty {
                                        ForEach(sampleHourlyIndices(from: data), id: \.self) { idx in
                                            Text("\(data[idx].temp)")
                                            if idx != lastHourlyIndex(from: data) { Spacer() }
                                        }
                                    } else { Text("—") }
                                }
                                .font(.custom("Spartan-Regular", size: 10))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 30)
                                .padding(.top, 10)

                                TemperatureChart(data: weatherSvc.hourlyTemperatures)
                                    .frame(height: 100)

                                HStack {
                                    let data = weatherSvc.hourlyTemperatures
                                    if !data.isEmpty {
                                        ForEach(sampleHourlyIndices(from: data), id: \.self) { idx in
                                            Text(formatTime(data[idx].date))
                                            if idx != lastHourlyIndex(from: data) { Spacer() }
                                        }
                                    } else { Text("—") }
                                }
                                .font(.custom("Spartan-Regular", size: 10))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 10)
                            }
                        }
                        .frame(height: 160)
                        .padding(.horizontal, 30)

                        // Bottom Stats
                        ZStack {
                            Image("bg_card_weather_stats_bar")
                                .resizable()
                                .scaledToFill()
                                .frame(height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 5))

                            HStack(spacing: 0) {
                                StatItem(icon: "ic_precipitation", value: "\(weatherSvc.precipProbPct ?? 0)%", isLast: false)
                                StatItem(icon: "ic_humidity", value: "\(weatherSvc.humidityPct ?? 0)%", isLast: false)
                                StatItem(icon: "ic_wind", value: "\(weatherSvc.windKmh ?? 0)km/h", isLast: true)
                            }
                        }
                        .padding(.horizontal, 50)
                        .padding(.bottom, 20)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .offset(x: geo.size.width * 0.1)

            // Sidebar
            VStack(spacing: 30) {
                Image(selectedIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)

                VStack(alignment: .leading, spacing: -5) {
                    HStack(alignment: .top, spacing: 0) {
                        Text("\(displayTemp)")
                            .font(.custom("Spartan-Bold", size: 70))
                            .foregroundColor(.white)

                        Text("°C")
                            .font(.custom("Spartan-Bold", size: 24))
                            .foregroundColor(.white)
                            .padding(.top, 15)
                    }

                    Text(selectedDesc)
                        .font(.custom("Spartan-Bold", size: 22))
                        .foregroundColor(.white)

                    HStack(spacing: 5) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 14, weight: .bold))

                        Text("\(selectedMaxTemp)° | \(selectedMinTemp)°")
                            .font(.custom("Spartan-Bold", size: 16))
                    }
                    .foregroundColor(.white)
                    .padding(.top, 5)
                }
                .padding(.leading, 20)

                Spacer()
            }
            .frame(width: geo.size.width * 0.32)
            .clipped()
            .padding()
            .offset(x: geo.size.width * 0.1)
        }
    }

    // MARK: - Day Switching

    @MainActor
    private func switchDay(_ index: Int) {
        switchingTask?.cancel()
        isSwitchingDay = true

        weatherSvc.selectDay(at: index)

        switchingTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            if !Task.isCancelled { isSwitchingDay = false }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func mainContentView(geo: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            HStack(alignment: .top) {
                Image(selectedIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? geo.size.width * 0.4 : geo.size.width * 0.3)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                Spacer()

                VStack(alignment: .trailing, spacing: 0) {
                    HStack(alignment: .top, spacing: 0) {
                        Text("\(displayTemp)")
                            .font(.custom("Spartan-Bold", size: UIDevice.current.userInterfaceIdiom == .phone ? 50 : 70))
                            .foregroundColor(.white)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("°C")
                                .font(.custom("Spartan-Bold", size: UIDevice.current.userInterfaceIdiom == .phone ? 20 : 40))
                                .foregroundColor(.white)
                                .padding(.top, 15)
                        }
                    }

                    Text(selectedDesc)
                        .font(.custom("Spartan-Bold", size: UIDevice.current.userInterfaceIdiom == .phone ? 14 : 20))
                        .foregroundColor(.white)

                    HStack {
                        Image(systemName: "arrow.up")
                            .foregroundColor(Color(red: 112/255, green: 42/255, blue: 78/255))
                        Image(systemName: "arrow.down")
                            .foregroundColor(Color(red: 112/255, green: 42/255, blue: 78/255))

                        Text("\(selectedMaxTemp)°")
                            .foregroundColor(.white)
                        Text("|")
                            .foregroundColor(Color(red: 112/255, green: 42/255, blue: 78/255))
                        Text("\(selectedMinTemp)°")
                            .foregroundColor(.white)
                    }
                    .font(.custom("Spartan-Bold", size: UIDevice.current.userInterfaceIdiom == .phone ? 12 : 16))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            HStack {
                ZStack {
                    Image("bg_weather_location")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180)

                    HStack {
                        Text(locManager.city ?? "Salvador")
                            .font(.custom("Spartan-Regular", size: 16))
                        Text(locManager.state ?? "BA")
                            .font(.custom("Spartan-Bold", size: 16))
                    }
                    .padding(.vertical, 10)
                    .foregroundColor(.white)
                }

                Spacer()

                HeaderDateTimeView()
                    .padding(.trailing)

                Image("bg_triangle_nav_buttons")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.07, height: geo.size.height * 0.05)
            }

            Divider().padding(.horizontal)

            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(white: 0.96))
                    .frame(height: 110)
                    .padding(.horizontal, 20)

                HStack(spacing: 12) {
                    if daysToShow.isEmpty {
                        ForEach(0..<5, id: \.self) { _ in
                            ForecastBox(day: "—", icon: "ic_sunny", tempMax: "—", tempMin: "—", isActive: false, onTap: {})
                        }
                    } else {
                        ForEach(Array(daysToShow.enumerated()), id: \.offset) { index, day in
                            ForecastBox(
                                day: shortWeekday(day.dateISO),
                                icon: WeatherCondition.from(code: day.code).assetName,
                                tempMax: "\(day.max)°",
                                tempMin: "\(day.min)°",
                                isActive: index == weatherSvc.selectedDayIndex,
                                onTap: { switchDay(index) }
                            )
                        }
                    }
                }
            }
            .padding(.vertical, 10)

            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(red: 26/255, green: 60/255, blue: 104/255), lineWidth: 1)
                        .background(Color.white.opacity(0.1))

                    VStack {
                        HStack {
                            let data = weatherSvc.hourlyTemperatures
                            if data.isEmpty {
                                Text("Sem dados deste dia")
                                    .font(.custom("Spartan-Regular", size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            } else {
                                ForEach(sampleHourlyIndices(from: data), id: \.self) { idx in
                                    Text("\(data[idx].temp)")
                                    if idx != lastHourlyIndex(from: data) { Spacer() }
                                }
                            }
                        }
                        .font(.custom("Spartan-Regular", size: 10))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 30)
                        .padding(.top, 10)

                        TemperatureChart(data: weatherSvc.hourlyTemperatures)
                            .padding(.bottom, 10)

                        HStack {
                            let data = weatherSvc.hourlyTemperatures
                            if !data.isEmpty {
                                ForEach(sampleHourlyIndices(from: data), id: \.self) { idx in
                                    Text(formatTime(data[idx].date))
                                    if idx != lastHourlyIndex(from: data) { Spacer() }
                                }
                            }
                        }
                        .font(.custom("Spartan-Regular", size: 10))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    }
                }
                .frame(height: 180)
                .padding(.horizontal)
            }

            ZStack {
                Image("bg_card_weather_stats_bar")
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 20)

                HStack(spacing: -20) {
                    StatItem(icon: "ic_precipitation", value: "\(weatherSvc.precipProbPct ?? 0)%", isLast: false)
                    StatItem(icon: "ic_humidity", value: "\(weatherSvc.humidityPct ?? 0)%", isLast: false)
                    StatItem(icon: "ic_wind", value: "\(weatherSvc.windKmh ?? 0)km/h", isLast: true)
                }
            }
            .padding(.bottom, 40)
        }
    }

    @ViewBuilder
    private func loadingView() -> some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Text("Buscando clima...")
                .font(.custom("Spartan-Bold", size: 18))
                .foregroundColor(.white)
        }
    }

    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.white)

            Text(message)
                .font(.custom("Spartan-Regular", size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Tentar novamente") { fetchIfPossible() }
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
                .foregroundColor(.white)
        }
    }

    @ViewBuilder
    private func permissionDeniedView(geo: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.white)

            Text("O acesso à localização foi negado.")
                .font(.custom("Spartan-Bold", size: 18))
                .foregroundColor(.white)

            Text("Para ver o clima da sua região, por favor ative a localização nas configurações.")
                .font(.custom("Spartan-Regular", size: 14))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Abrir Configurações") { locManager.openSettings() }
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(Color(red: 26/255, green: 60/255, blue: 104/255))
                .cornerRadius(10)
                .foregroundColor(.white)
        }
    }

    @ViewBuilder
    private func requestPermissionView(geo: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "location.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.white)

            Text("Veja o clima local!")
                .font(.custom("Spartan-Bold", size: 24))
                .foregroundColor(.white)

            Text("Precisamos da sua permissão para mostrar os dados precisos da sua cidade.")
                .font(.custom("Spartan-Regular", size: 16))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Dar permissão") { locManager.requestPermission() }
                .padding(.horizontal, 50)
                .padding(.vertical, 20)
                .background(Color(red: 26/255, green: 60/255, blue: 104/255))
                .cornerRadius(30)
                .foregroundColor(.white)
                .shadow(radius: 10)
        }
    }

    // MARK: - Helpers

    private func fetchIfPossible() {
        if let loc = locManager.lastLocation {
            weatherSvc.fetchWeather(latitude: loc.coordinate.latitude,
                                 longitude: loc.coordinate.longitude)
        } else {
            weatherSvc.fetchWeather()
            locManager.startOnceIfAuthorized()
        }
    }

    private func shortWeekday(_ iso: String) -> String {
        let inF = DateFormatter()
        inF.dateFormat = "yyyy-MM-dd"
        let outF = DateFormatter()
        outF.locale = Locale(identifier: "pt_BR")
        outF.dateFormat = "EEE"
        if let date = inF.date(from: iso) {
            return outF.string(from: date).uppercased()
        }
        return "—"
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:00"
        return f.string(from: date)
    }

    private func sampleHourlyIndices(from data: [(date: Date, temp: Int)]) -> [Int] {
        let count = data.count
        guard count > 0 else { return [] }
        if count <= 5 { return Array(0..<count) }
        return [0, count/4, count/2, 3*count/4, count-1]
    }

    private func lastHourlyIndex(from data: [(date: Date, temp: Int)]) -> Int {
        sampleHourlyIndices(from: data).last ?? -1
    }
}

// MARK: - ForecastBox

struct ForecastBox: View {
    var day: String
    var icon: String
    var tempMax: String
    var tempMin: String
    var isActive: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(day)
                    .font(.custom("Spartan-Bold", size: 12))
                    .foregroundColor(isActive ? .white : .black)

                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)

                HStack(spacing: 2) {
                    Text(tempMax)
                    Text("/")
                    Text(tempMin)
                }
                .font(.custom("Spartan-Regular", size: 10))
                .foregroundColor(isActive ? .white : .gray)
            }
            .frame(width: 65, height: 90)
            .background(isActive ? Color(red: 26/255, green: 60/255, blue: 104/255) : Color.white)
            .cornerRadius(3)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel("\(day), máxima \(tempMax), mínima \(tempMin)")
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}

// MARK: - StatItem

struct StatItem: View {
    var icon: String
    var value: String
    var isLast: Bool

    var body: some View {
        HStack {
            Spacer()

            if icon.contains("ic_") {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            } else {
                Image(icon)
                    .foregroundColor(.white)
            }

            Text(value)
                .font(.custom("Spartan-Regular", size: UIDevice.current.userInterfaceIdiom == .phone ? 14 : 16))
                .foregroundColor(.white)

            Spacer()

            if !isLast {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 1, height: 30)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
    }
}

// MARK: - TemperatureChart

struct TemperatureChart: View {
    var data: [(date: Date, temp: Int)]

    var body: some View {
        GeometryReader { geo in
            let temps = data.map { $0.temp }
            let minTemp = temps.min() ?? 0
            let maxTemp = temps.max() ?? 1
            let range = CGFloat(max(1, maxTemp - minTemp))

            ZStack {
                Path { path in
                    let w = geo.size.width
                    let h = geo.size.height
                    guard !data.isEmpty else { return }

                    for (i, item) in data.enumerated() {
                        let x = w * CGFloat(i) / CGFloat(max(1, data.count - 1))
                        let y = h * (1.0 - CGFloat(item.temp - minTemp) / range * 0.6 - 0.2)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(Color(red: 26/255, green: 60/255, blue: 104/255), lineWidth: 2)

                Path { path in
                    let w = geo.size.width
                    let h = geo.size.height
                    guard !data.isEmpty else { return }

                    path.move(to: CGPoint(x: 0, y: h))

                    for (i, item) in data.enumerated() {
                        let x = w * CGFloat(i) / CGFloat(max(1, data.count - 1))
                        let y = h * (1.0 - CGFloat(item.temp - minTemp) / range * 0.6 - 0.2)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }

                    path.addLine(to: CGPoint(x: w, y: h))
                    path.closeSubpath()
                }
                .fill(Color("azulClaro").opacity(0.3))
            }
        }
    }
}

// MARK: - Day Switch Overlay

private struct DaySwitchLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))

                Text("Atualizando…")
                    .font(.custom("Spartan-Bold", size: 14))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(Color.black.opacity(0.55))
            .cornerRadius(14)
        }
        .allowsHitTesting(true)
    }
}
