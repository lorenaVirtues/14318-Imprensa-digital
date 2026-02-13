import SwiftUI

extension View {
    func appFont(weight: Font.Weight = .regular, size: CGFloat) -> some View {
        self.modifier(AppFontModifier(weight: weight, size: size))
    }
}

struct AppFontModifier: ViewModifier {
    @AppStorage("fontScale") var fontScale: Double = 1.0
    @AppStorage("isBoldText") var isBoldText: Bool = false
    
    var weight: Font.Weight
    var size: CGFloat
    
    func body(content: Content) -> some View {
        let finalWeight: Font.Weight = isBoldText ? .bold : weight
        let finalSize = size * CGFloat(fontScale)
        
        let fontName: String = {
            if finalWeight == .bold {
                return "Spartan-Bold"
            } else if finalWeight == .semibold {
                return "Spartan-SemiBold"
            } else if finalWeight == .medium {
                // Se não tiver Medium, usa SemiBold ou Regular
                return "Spartan-SemiBold"
            } else {
                return "Spartan-Regular"
            }
        }()
        
        return content.font(.custom(fontName, size: finalSize))
    }
}
