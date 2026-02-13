import SwiftUI

struct BannerCarouselView: View {
    let geo: GeometryProxy
    @State private var currentIndex = 0
    let banners = [
        "weather_card",
        "card_view_your_playlists_main",
        "card_view_whatsapp_main",
        "card_view_facebook_main",
        "card_view_instagram_main",
        "card_view_youtube_main"
    ]
    let onTap: (String) -> Void
    
    // Timer para auto-scroll (opcional, mas comum em carrosséis)
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0..<banners.count, id: \.self) { index in
                        GeometryReader { cardGeo in
                            let isPad = UIDevice.current.userInterfaceIdiom == .pad
                            let cardWidth = geo.size.width * (isPad ? 0.45 : 0.80)
                            let cardHeight = geo.size.height * (isPad ? 0.30 : 0.22)
                            
                            Group {
                                Button(action: {
                                    onTap(banners[index])
                                }) {
                                    if index == 0 {
                                        WeatherCardView(width: cardWidth, height: cardHeight)
                                            .cornerRadius(12)
                                    } else {
                                        Image(banners[index])
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: cardWidth, height: cardHeight)
                                            .cornerRadius(12)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .onAppear {
                                updateIndex(cardGeo: cardGeo, index: index, totalWidth: geo.size.width)
                            }
                            .onChange(of: cardGeo.frame(in: .global).minX) { _ in
                                updateIndex(cardGeo: cardGeo, index: index, totalWidth: geo.size.width)
                            }
                        }
                        .frame(width: geo.size.width * (UIDevice.current.userInterfaceIdiom == .pad ? 0.45 : 0.80), 
                               height: geo.size.height * (UIDevice.current.userInterfaceIdiom == .pad ? 0.32 : 0.24))
                    }
                }
                .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 20 : 10)
            }
            .frame(height: geo.size.height * (UIDevice.current.userInterfaceIdiom == .pad ? 0.32 : 0.24))
            
            // Indicador de página (Bolinhas)
            HStack(spacing: 8) {
                ForEach(0..<banners.count, id: \.self) { index in
                    if index == currentIndex {
                        Capsule()
                            .fill(Color(red: 129/255, green: 51/255, blue: 90/255))
                            .frame(width: 24, height: 8)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
    }
    
    private func updateIndex(cardGeo: GeometryProxy, index: Int, totalWidth: CGFloat) {
        let midX = cardGeo.frame(in: .global).midX
        let center = totalWidth / 2
        // Se o centro do card estiver perto do centro da tela, ele é o atual
        if abs(midX - center) < (totalWidth * 0.3) {
            if currentIndex != index {
                currentIndex = index
            }
        }
    }
}
