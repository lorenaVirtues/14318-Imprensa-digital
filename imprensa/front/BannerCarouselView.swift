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
                let isLandscape = geo.size.width > geo.size.height
                let leadingPadding: CGFloat = isLandscape ? geo.size.width * 0.3 : geo.size.width * 0.04
                
                HStack(spacing: UIDevice.current.userInterfaceIdiom == .phone ? -70 : 25) {
                    ForEach(0..<banners.count, id: \.self) { index in
                        GeometryReader { cardGeo in
                            let isPad = UIDevice.current.userInterfaceIdiom == .pad
                            let isLandscape = geo.size.width > geo.size.height
                            
                            let cardWidth: CGFloat = {
                                if isLandscape { return geo.size.width * (isPad ? 0.30 : 0.40) }
                                return geo.size.width * (isPad ? 0.45 : 0.80)
                            }()
                            
                            let cardHeight: CGFloat = {
                                if isLandscape { return geo.size.height * (isPad ? 0.35 : 0.40) }
                                return geo.size.height * (isPad ? 0.30 : 0.22)
                            }()
                            
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
                                updateIndex(cardGeo: cardGeo, index: index, totalWidth: geo.size.width, leadingPadding: leadingPadding)
                            }
                            .onChange(of: cardGeo.frame(in: .global).minX) { _ in
                                updateIndex(cardGeo: cardGeo, index: index, totalWidth: geo.size.width, leadingPadding: leadingPadding)
                            }
                        }
                        .frame(width: {
                            let isLandscape = geo.size.width > geo.size.height
                            let isPad = UIDevice.current.userInterfaceIdiom == .pad
                            if isLandscape { return geo.size.width * (isPad ? 0.30 : 0.40) }
                            return geo.size.width * (isPad ? 0.45 : 0.80)
                        }(), 
                        height: {
                            let isLandscape = geo.size.width > geo.size.height
                            let isPad = UIDevice.current.userInterfaceIdiom == .pad
                            if isLandscape { return geo.size.height * (isPad ? 0.35 : 0.40) }
                            return geo.size.height * (isPad ? 0.32 : 0.24)
                        }())
                    }
                }
                .padding(.leading, leadingPadding)
                .padding(.trailing, 80) // Padding extra no final para permitir que o último card role bem
            }
            .frame(height: {
                let isLandscape = geo.size.width > geo.size.height
                let isPad = UIDevice.current.userInterfaceIdiom == .pad
                if isLandscape { return geo.size.height * (isPad ? 0.35 : 0.40) }
                return geo.size.height * (isPad ? 0.32 : 0.24)
            }())
            
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
    
    private func updateIndex(cardGeo: GeometryProxy, index: Int, totalWidth: CGFloat, leadingPadding: CGFloat) {
        let minX = cardGeo.frame(in: .global).minX
        // Com o espaçamento negativo (-70), o ponto onde o card é considerado "ativo" no leading 
        // precisa ser um pouco mais flexível.
        let threshold: CGFloat = 80 
        
        if abs(minX - leadingPadding) < threshold {
            if currentIndex != index {
                currentIndex = index
            }
        }
    }
}
