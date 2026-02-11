import SwiftUI

struct LocalizacaoHorarioView: View {
    // Serviços
    @StateObject private var locManager  = LocationManager()
    @StateObject private var dateTimeSvc = DateTimeService()

    private let gradient = LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)

    var body: some View {
        ZStack {
            gradient.ignoresSafeArea()

            VStack(spacing: 32) {

                // ---------------- Localização ----------------
                VStack(spacing: 4) {
                    if let city = locManager.city,
                       let uf   = locManager.state {
                        Text(city)
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        Text(uf)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        // skeleton enquanto faz reverse-geocoding
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 180, height: 28)
                            .redacted(reason: .placeholder)
                    }
                }

                // ---------------- Data & Hora ----------------
                VStack(spacing: 8) {
                    // Dia da semana (ex.: SEG)
                    Text(dateTimeSvc.weekdayAbbrev)
                        .font(.system(size: 56, weight: .thin))
                        .foregroundColor(.yellow)

                    // Data completa (dd/MM/yyyy)
                    Text(dateTimeSvc.dateString)
                        .font(.title2)
                        .foregroundColor(.white)

                    // Horário (HH:mm) – atualiza a cada minuto
                    Text(dateTimeSvc.timeString)
                        .font(.system(size: 72, weight: .thin))
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
    }
}

#Preview {
    LocalizacaoHorarioView()
}
