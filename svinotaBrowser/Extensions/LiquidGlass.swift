import SwiftUI

// MARK: - BlurView (UIBlurEffect)
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - Liquid Glass Modifier
struct LiquidGlass: ViewModifier {
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.65
    var shadowRadius: CGFloat = 8
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // 1. UIKit native backdrop blur
                    BlurView(style: colorScheme == .dark ? .systemMaterialDark : .systemMaterialLight)
                    
                    // 2. Translucent tinted fill
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            colorScheme == .dark
                                ? Color(white: 0.12).opacity(opacity)
                                : Color.white.opacity(opacity)
                        )
                    
                    // 3. Specular highlight border (liquid shimmer)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.35 : 0.75),
                                    Color.white.opacity(0.0),
                                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.15),
                radius: shadowRadius,
                x: 0,
                y: 4
            )
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 20, opacity: Double = 0.65, shadowRadius: CGFloat = 8) -> some View {
        modifier(LiquidGlass(cornerRadius: cornerRadius, opacity: opacity, shadowRadius: shadowRadius))
    }
}
