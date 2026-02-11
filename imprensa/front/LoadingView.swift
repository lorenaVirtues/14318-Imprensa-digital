
import SwiftUI

struct LoadingView: View {
    @State private var animate = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.8)
            .stroke(Color("azulEscuro"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .frame(width: 30, height: 30)
            .rotationEffect(.degrees(animate ? 360 : 0))
            .onAppear {
                withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
    }
}
