import SwiftUI

struct MarqueeText: View {
    let text: String
    let font: Font
    let color: Color
    
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Text(text)
                    .font(font)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .background(GeometryReader { textGeo in
                        Color.clear
                            .preference(key: TextWidthPreferenceKey.self, value: textGeo.size.width)
                    })
                    .offset(x: offset)
                
                if textWidth > containerWidth {
                    Text(text)
                        .font(font)
                        .foregroundColor(color)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .offset(x: offset + textWidth + 40) // 40 is the gap
                }
            }
            .onPreferenceChange(TextWidthPreferenceKey.self) { width in
                textWidth = width
                containerWidth = geo.size.width
                startAnimation()
            }
            .clipped()
        }
    }
    
    private func startAnimation() {
        guard textWidth > 0 && containerWidth > 0 else { return }
        guard textWidth > containerWidth else { 
            offset = 0
            return 
        }
        
        // Reset offset
        offset = 0
        
        let duration = Double(textWidth) / 20.0 // Slower speed for better readability
        
        let animation = Animation.linear(duration: duration)
            .repeatForever(autoreverses: false)
            .delay(1.0) // Short delay before starting
        
        withAnimation(animation) {
            offset = -(textWidth + 40)
        }
    }
}

private struct TextWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
