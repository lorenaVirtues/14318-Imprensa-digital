import SwiftUI

struct ErrorView: View {
    let onReconnect: () -> Void
    var body: some View {
        VStack {
            Spacer()
            VStack {
             /*   LottieView(animationName: "failed", participatesInGlobalPause: false)
                    .frame(width: (UIDevice.current.userInterfaceIdiom == .phone) ? 88 : 300,
                           height: (UIDevice.current.userInterfaceIdiom == .phone) ? 88 : 300)*/
                
               Text("Não é possível conectar-se ao streaming de áudio. Verifique sua conexão com a Internet. Se o problema persistir, entre em contato com o suporte.")
                    .foregroundColor(.black)
                    .font(.custom("", size: (UIDevice.current.userInterfaceIdiom == .phone) ? 16 : 25))
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    onReconnect()
                }) {
                    Text("Tentar outra vez")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
            }
            .padding(40)
            .background(Color.white)
            .cornerRadius(20)
            Spacer()
        }
        .frame(maxWidth: .infinity , maxHeight: .infinity)
        .background(Color.black.opacity(0.6))
        .edgesIgnoringSafeArea(.all)
        .transition(.opacity)
    }
}
