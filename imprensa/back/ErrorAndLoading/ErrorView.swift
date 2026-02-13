import SwiftUI

struct ErrorView: View {
    let onReconnect: () -> Void
    var errorMessage: String? = nil
    
    var body: some View {
        let type: AppErrorScreenType = (errorMessage?.contains("conexão") == true || errorMessage?.contains("Internet") == true) ? .connection : .server
        
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Blue Bar
                Color(red: 26/255, green: 60/255, blue: 104/255)
                    .frame(height: 5)
                    .ignoresSafeArea(edges: .top)
                
                Spacer()
                
                // Top Logo (Diamond with Play)
                ZStack {
                    // Diamond Background
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(red: 26/255, green: 60/255, blue: 104/255), Color(red: 45/255, green: 90/255, blue: 154/255)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(45))
                        .overlay(
                            Rectangle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                .rotationEffect(.degrees(45))
                        )
                    
                    // Circular Play Logo
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "play.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                            .offset(x: 2)
                        
                        Circle()
                            .stroke(Color(red: 26/255, green: 60/255, blue: 104/255), lineWidth: 2)
                            .frame(width: 55, height: 55)
                    }
                }
                .padding(.bottom, 60)
                
                // Icon Area
                if type == .connection {
                    connectionIcon
                } else {
                    serverIcon
                }
                
                // Title
                Text(type.title)
                    .font(.custom("Spartan-Bold", size: 28))
                    .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
                    .padding(.top, 20)
                
                // Description
                Text(type.description)
                    .font(.custom("Spartan-Regular", size: 16))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 40)
                
                Spacer()
                
                // Reload Button
                Button(action: onReconnect) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .bold))
                        Text("RECARREGAR")
                            .font(.custom("Spartan-Bold", size: 18))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 30)
                    .background(
                        ZStack {
                            SlantedErrorButtonShape()
                                .fill(Color(red: 26/255, green: 60/255, blue: 104/255))
                            
                            SlantedErrorButtonShape()
                                .fill(Color(red: 26/255, green: 60/255, blue: 104/255).opacity(0.3))
                                .offset(x: 2, y: 3)
                                .zIndex(-1)
                        }
                    )
                }
                .padding(.bottom, 60)
            }
            
            // Side Triangles (as seen in image divider)
            HStack {
                Triangle()
                    .fill(Color(red: 135/255, green: 206/255, blue: 235/255))
                    .frame(width: 15, height: 30)
                    .rotationEffect(.degrees(90))
                    .offset(x: -5)
                Spacer()
                Triangle()
                    .fill(Color(red: 135/255, green: 206/255, blue: 235/255))
                    .frame(width: 15, height: 30)
                    .rotationEffect(.degrees(-90))
                    .offset(x: 5)
            }
        }
        .preferredColorScheme(.light)
        .transition(.opacity)
    }
    
    private var connectionIcon: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "wifi")
                .resizable()
                .scaledToFit()
                .frame(width: 120)
                .foregroundColor(Color(red: 26/255, green: 60/255, blue: 104/255))
            
            warningBadge
                .offset(x: 10, y: -10)
        }
    }
    
    private var serverIcon: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 5) {
                ForEach(0..<3) { _ in
                    Capsule()
                        .fill(Color(red: 26/255, green: 60/255, blue: 104/255))
                        .frame(width: 100, height: 25)
                }
            }
            
            warningBadge
                .offset(x: 10, y: -10)
        }
    }
    
    private var warningBadge: some View {
        ZStack {
            Triangle()
                .fill(Color(red: 135/255, green: 206/255, blue: 235/255))
                .frame(width: 50, height: 45)
            
            Text("!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .offset(y: 4)
        }
    }
}

enum AppErrorScreenType {
    case connection
    case server
    
    var title: String {
        switch self {
        case .connection: return "CONEXÃO PERDIDA"
        case .server: return "OOOPS!"
        }
    }
    
    var description: String {
        switch self {
        case .connection:
            return "Parece que você está sem conexão com a internet. Verifique sua rede Wi-Fi ou dados móveis e tente novamente."
        case .server:
            return "Estamos enfrentando dificuldades técnicas e voltaremos assim que possível. Tente novamente em alguns instantes."
        }
    }
}

struct SlantedErrorButtonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let slant: CGFloat = 10
        path.move(to: CGPoint(x: slant, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width - slant, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
