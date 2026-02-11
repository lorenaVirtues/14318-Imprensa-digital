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
    @Environment(\.dismiss) private var dismiss
    private let gradient = LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)

    var body: some View {
        GeometryReader{ geo in
            let h = geo.size.height
            let w = geo.size.width
            ZStack {
                gradient.ignoresSafeArea()
                switch locManager.authStatus {
                case .denied, .restricted:
                    VStack(spacing: 8) {
                        HStack{
                            Button(action: {
                                dismiss()
                            }, label: {
                                Image(systemName: "chevron.left")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: w * 0.3, height: h * 0.06)
                            })
                            .padding(.leading, w * 0.05)
                            .padding(.top, h * 0.02)
                            Spacer()
                        }
                        Image(systemName: "location.slash")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                        Text("Ative a localização para ver o clima")
                            .font(.custom("Inter-Regular", size: 12))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                        Button("Ativar localização") {
                            locManager.openSettings()
                        }
                        .font(.custom("LeagueSpartan-Regular", size: 12))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(.black)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                    }
                    .frame(width: 300, height: 200)
                    .foregroundStyle(.white)
                    
                case .notDetermined:
                    VStack(spacing: 8) {
                        HStack{
                            Button(action: {
                                dismiss()
                            }, label: {
                                Image(systemName: "chevron.left")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: w * 0.3, height: h * 0.06)
                            })
                            .padding(.leading, w * 0.05)
                            .padding(.top, h * 0.02)
                            Spacer()
                        }
                        Image(systemName: "location")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                        Text("Permita o acesso à localização")
                            .font(.custom("Inter-Regular", size: 12))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                        Button("Permitir agora") {
                            locManager.requestPermission()
                        }
                        .font(.custom("Inter-Regular", size: 12))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(.black)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                    }
                    .frame(width: 300, height: 200)
                    .foregroundStyle(.white)
                    
                default:
                    if let error = weatherSvc.errorMessage {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text(error)
                        }
                        .foregroundColor(.white)
                    } else if weatherSvc.isLoading || weatherSvc.currentTemp == nil {
                        ProgressView("Carregando clima…")
                            .foregroundColor(.white)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 32) {
                                HStack{
                                    Button(action: {
                                        dismiss()
                                    }, label: {
                                        Image(systemName: "chevron.left")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: w * 0.3, height: h * 0.06)
                                    })
                                    .padding(.leading, w * 0.05)
                                    .padding(.top, h * 0.02)
                                    Spacer()
                                }
                                VStack(spacing: 8) {
                                    Text(locManager.city ?? "—")
                                        .font(.largeTitle.bold())
                                        .foregroundColor(.white)

                                    if let cond = weatherSvc.condition {
                                        Image(systemName: cond.iconName)
                                            .font(.system(size: 60))
                                            .foregroundColor(.yellow)
                                        Text(cond.description).foregroundColor(.white)
                                    }

                                    if let temp = weatherSvc.currentTemp {
                                        Text("\(temp)°")
                                            .font(.system(size: 72, weight: .thin))
                                            .foregroundColor(.white)
                                    }

                                    if let min = weatherSvc.minTemp, let max = weatherSvc.maxTemp {
                                        Text("Mín \(min)°  /  Máx \(max)°")
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Próximos dias")
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    if weatherSvc.daily.isEmpty {
                                        ForEach(0..<5, id: \.self) { _ in skeletonRow }
                                    } else {
                                        ForEach(weatherSvc.daily.prefix(7)) { day in longCard(day) }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    
                }
            }
            .navigationTitle("Voltar")
            .navigationBarHidden(true)
            //.onAppear  { fetchIfPossible() }
            .onChange(of: locManager.lastLocation) { _ in fetchIfPossible() }
        }
    }

    // MARK: – Data fetch
    private func fetchIfPossible() {
        guard let loc = locManager.lastLocation else { return }
        guard weatherSvc.shouldFetch(for: loc) else { return }

        weatherSvc.fetchWeather(
            latitude: loc.coordinate.latitude,
            longitude: loc.coordinate.longitude
        )
    }

    // MARK: – Header (condição atual)
    private var header: some View {
        VStack(spacing: 8) {
            Text(locManager.city ?? "—")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            if let cond = weatherSvc.condition {
                Image(systemName: cond.iconName)
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                Text(cond.description).foregroundColor(.white)
            }

            if let temp = weatherSvc.currentTemp {
                Text("\(temp)°")
                    .font(.system(size: 72, weight: .thin))
                    .foregroundColor(.white)
            }

            if let min = weatherSvc.minTemp, let max = weatherSvc.maxTemp {
                Text("Mín \(min)°  /  Máx \(max)°")
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }

    // MARK: – Forecast cards
    private var longCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Próximos dias")
                .font(.headline)
                .foregroundColor(.white)

            if weatherSvc.daily.isEmpty {
                ForEach(0..<5, id: \.self) { _ in skeletonRow }
            } else {
                ForEach(weatherSvc.daily.prefix(7)) { day in longCard(day) }
            }
        }
    }

    private var skeletonRow: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.25))
            .frame(height: 56)
            .redacted(reason: .placeholder)
    }

    private func longCard(_ day: DailyForecast) -> some View {
        HStack {
            Text(shortWeekday(day.dateISO))
                .foregroundColor(.white)
                .frame(width: 100, alignment: .leading)

            Spacer()

            Image(systemName: WeatherCondition.from(code: day.code).iconName)
                .foregroundColor(.yellow)
                .frame(width: 24)


            Text("\(day.max)°")
                .foregroundColor(.white)
                .frame(width: 40, alignment: .trailing)
            Text("/ \(day.min)°")
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 42, alignment: .leading)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(Color.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func shortWeekday(_ iso: String) -> String {
        // Open‑Meteo devolve apenas "yyyy-MM-dd"; precisamos de DateFormatter comum
        let inF = DateFormatter()
        inF.locale = Locale(identifier: "en_US_POSIX")
        inF.dateFormat = "yyyy-MM-dd"
        let outF = DateFormatter()
        outF.locale = Locale(identifier: "pt_BR")
        outF.setLocalizedDateFormatFromTemplate("EEE dd") // seg 12
        if let date = inF.date(from: iso) {
            return outF.string(from: date).capitalized
        }
        return "—"
    }
}

#Preview {
    ClimaView()
        .previewDevice("iPhone 13")
}


