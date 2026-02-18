import SwiftUI

struct WeatherCardView: View {
    @EnvironmentObject var weatherSvc: WeatherService
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        ZStack {
            // Background Image Priority
            Image(weatherSvc.condition?.cardBackgroundName ?? "card_view_weather_main")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width * 0.8, height: height * 0.9, alignment: .top)
                .border(Color.red)
            
            // Content Overlay
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    // Temperature
                    HStack(alignment: .top, spacing: 0) {
                        if let temp = weatherSvc.currentTemp {
                            Text("\(temp)")
                                .font(.custom("Spartan-Bold", size: 30))
                                .foregroundColor(.white)
                        } else {
                            Text("--")
                                .font(.custom("Spartan-Bold", size: 40))
                                .foregroundColor(.white)
                        }
                        
                        Text("°C")
                            .font(.custom("Spartan-Bold", size: 14))
                            .foregroundColor(.white)
                            .padding(.top, 10)
                    }
                    .padding(.top, 10) // Offset to center in the blue box part
                    
                    Text("Pred. \(weatherSvc.condition?.description ?? "—")")
                        .font(.custom("Spartan-Regular", size: 14))
                        .foregroundColor(.white)
                    
                    // Min/Max indicator
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(weatherSvc.maxTemp ?? 0)° | \(weatherSvc.minTemp ?? 0)°")
                            .font(.custom("Spartan-Bold", size: 12))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .cornerRadius(4)
                    .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                    .padding(.top, 5)
                    
                    // Stats
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            HStack(spacing: 2) {
                                Image("ic_precipitation")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14)
                                Text("| \(weatherSvc.precipProbPct ?? 0)%")
                            }
                            
                            HStack(spacing: 2) {
                                Image("ic_humidity")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14)
                                Text("| \(weatherSvc.humidityPct ?? 0)%")
                            }
                        }
                        
                        HStack(spacing: 2) {
                            Image("ic_wind")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                            Text("| \(weatherSvc.windKmh ?? 0)km/h")
                        }
                    }
                    .font(.custom("Spartan-Regular", size: 13))
                    .foregroundColor(.white)
                    .padding(.top, 5)
                }
                .padding(.leading, 40) // Adjusted to align inside the blue part
                .padding(.top, 25)
                .frame(width: width * 0.45, height: height * 0.5)
                Spacer()
            }
        }
        .frame(width: width, height: height)
    }
}
