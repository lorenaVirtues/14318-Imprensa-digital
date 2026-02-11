import SwiftUI

struct LoaderView: View {
    var tintColor: Color = .blue
    var scaleSize: CGFloat = 1.0
    
    var body: some View {
        VStack {
       /*     LottieView(animationName: "loading", participatesInGlobalPause: false)
                .frame(width: (UIDevice.current.userInterfaceIdiom == .phone) ? 100 : 300, height: (UIDevice.current.userInterfaceIdiom == .phone) ? 100 : 300)*/
            Text("Carregando...")
                .foregroundColor(.white)
                .font(.custom("Montserrat-Bold", size: (UIDevice.current.userInterfaceIdiom == .phone) ? 16 : 25))
                .padding(.top, 10)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.6))
        .edgesIgnoringSafeArea(.all)
        .transition(.opacity)
        
    }
}
