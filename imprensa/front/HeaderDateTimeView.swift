import SwiftUI

struct HeaderDateTimeView: View {
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack(alignment: .bottom, spacing: 2) {
                Text(timeString)
                    .font(.custom("Spartan-Bold", size: 28))
                    .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255)) // Dark blue from logo
                
                Text("h")
                    .font(.custom("Spartan-Regular", size: 14))
                    .foregroundColor(Color.black)
                    .padding(.bottom, 4)
            }
            
            HStack(spacing: 0) {
                Text(dayOfWeekString)
                    .font(.custom("Spartan-Bold", size: 12))
                    .foregroundColor(Color("dia"))
                
                Text(restOfDateString)
                    .font(.custom("Spartan-Regular", size: 12))
                    .foregroundColor(Color.black)
            }
        }
        .onReceive(timer) { input in
            currentTime = input
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: currentTime)
    }
    
    private var dayOfWeekString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEE"
        return formatter.string(from: currentTime).uppercased().replacingOccurrences(of: ".", with: "")
    }
    
    private var restOfDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = ", dd 'de' MMM"
        return formatter.string(from: currentTime).uppercased().replacingOccurrences(of: ".", with: "")
    }
}
