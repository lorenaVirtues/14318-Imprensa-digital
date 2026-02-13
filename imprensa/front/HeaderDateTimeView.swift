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
                    .font(.custom("Spartan-Bold", size: 14))
                    .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                    .padding(.bottom, 4)
            }
            
            Text(dateString)
                .font(.custom("Spartan-Bold", size: 12))
                .foregroundColor(Color(red: 45/255, green: 90/255, blue: 154/255)) // Lighter blue
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
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEE, dd 'de' MMM"
        return formatter.string(from: currentTime).uppercased().replacingOccurrences(of: ".", with: "")
    }
}
