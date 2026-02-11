import Foundation

final class DateTimeService: ObservableObject {
    @Published var weekdayAbbrev: String = ""   // "SEG", "SEX", ...
    @Published var weekdayFull: String = ""     // "Sexta-feira"
    @Published var dateString: String = ""      // "01 de Agosto, 2025"
    @Published var timeString: String = ""      // "17:15"
    @Published var periodOfDay: String = ""
    @Published var shortDate: String = ""   // "17/11/2025"

    private var timer: Timer?

    init() {
        update()
        // dispara a cada minuto, alinhado ao início do minuto
        let now = Date()
        let secondsToNextMinute = 60 - Calendar.current.component(.second, from: now)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(secondsToNextMinute)) { [weak self] in
            self?.timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                self?.update()
            }
            self?.update()
        }
    }

    deinit { timer?.invalidate() }

    @objc private func update() {
        let now = Date()
        let locale = Locale(identifier: "pt_BR")

        // Hora no formato "17h15"
        let dfTime = DateFormatter()
        dfTime.locale = locale
        dfTime.dateFormat = "HH':'mm"
        timeString = dfTime.string(from: now)

        // Data no formato "01 de Agosto, 2025"
        let dfDate = DateFormatter()
        dfDate.locale = locale
        dfDate.dateFormat = "dd 'de' MMMM, yyyy"
        dateString = dfDate.string(from: now)
            .replacingOccurrences(of: " de ", with: " de ") // garante espaçamento correto
            .capitalizingFirstLetter(locale: locale)
        
        let dfShort = DateFormatter()
        dfShort.locale = locale
        dfShort.dateFormat = "dd/MM/yyyy"
        shortDate = dfShort.string(from: now)


        // Período do dia
        let hour = Calendar.current.component(.hour, from: now)
        if hour >= 6 && hour < 12 {
            periodOfDay = "MANHÃ"
        } else if hour >= 12 && hour < 18 {
            periodOfDay = "TARDE"
        } else {
            periodOfDay = "NOITE"
        }

        // Abreviação do dia ("SEG", "SAB", ...)
        weekdayAbbrev = makeWeekdayAbbrev(now, locale: locale)

        // Dia da semana em extenso separado ("Sexta-feira")
        weekdayFull = makeWeekdayFull(now, locale: locale)
    }

    // MARK: - Helpers

    private func makeWeekdayAbbrev(_ date: Date, locale: Locale) -> String {
        let df = DateFormatter()
        df.locale = locale
        df.dateFormat = "EEE"
        let raw = df.string(from: date)
            .replacingOccurrences(of: ".", with: "")
            .folding(options: .diacriticInsensitive, locale: locale)
        return raw.uppercased() // "SEG", "SAB", etc.
    }

    private func makeWeekdayFull(_ date: Date, locale: Locale) -> String {
        let df = DateFormatter()
        df.locale = locale
        df.dateFormat = "EEEE" // "sexta-feira", "sábado"
        return df.string(from: date).capitalizingFirstLetter(locale: locale) // "Sexta-feira"
    }
}

private extension String {
    func capitalizingFirstLetter(locale: Locale) -> String {
        guard let first = self.first else { return self }
        let head = String(first).uppercased(with: locale)
        let tail = self.dropFirst()
        return head + tail
    }
}
