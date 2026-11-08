import SwiftUI

// MARK: - Theme Mode Enum
// 0: Light (Material), 1: Dark (Material), 2: AMOLED
enum ThemeMode: Int, CaseIterable {
    case light = 0
    case dark = 1
    case amoled = 2
    
    var isDark: Bool {
        return self != .light
    }
    
    func title(lang: String) -> String {
        if lang == "ru" {
            switch self {
            case .light: return "Светлая"
            case .dark: return "Тёмная"
            case .amoled: return "AMOLED"
            }
        } else {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .amoled: return "AMOLED"
            }
        }
    }
}

// MARK: - App Color Scheme
struct AppColors {
    let surface: Color
    let surfaceVariant: Color
    let onSurface: Color
    let onSurfaceVariant: Color
    let primary: Color
    let primaryContainer: Color
    let onPrimaryContainer: Color
    let errorContainer: Color
    let onErrorContainer: Color
    var error: Color { Color(red: 0.85, green: 0.15, blue: 0.15) }
    
    static func forMode(_ mode: ThemeMode) -> AppColors {
        switch mode {
        case .light:
            // Material Light theme
            return AppColors(
                surface: Color(red: 0.96, green: 0.97, blue: 0.98),
                surfaceVariant: Color(red: 0.88, green: 0.90, blue: 0.93),
                onSurface: Color(red: 0.10, green: 0.11, blue: 0.12),
                onSurfaceVariant: Color(red: 0.25, green: 0.27, blue: 0.30),
                primary: Color(red: 0.25, green: 0.45, blue: 0.85), // Dynamic blueish
                primaryContainer: Color(red: 0.82, green: 0.89, blue: 0.98),
                onPrimaryContainer: Color(red: 0.05, green: 0.18, blue: 0.45),
                errorContainer: Color(red: 1.0, green: 0.85, blue: 0.84),
                onErrorContainer: Color(red: 0.55, green: 0.0, blue: 0.0)
            )
        case .dark:
            // Material Dark theme
            return AppColors(
                surface: Color(red: 0.12, green: 0.13, blue: 0.15),
                surfaceVariant: Color(red: 0.18, green: 0.20, blue: 0.24),
                onSurface: Color(red: 0.92, green: 0.94, blue: 0.96),
                onSurfaceVariant: Color(red: 0.75, green: 0.78, blue: 0.82),
                primary: Color(red: 0.60, green: 0.76, blue: 1.0), // Dynamic blue
                primaryContainer: Color(red: 0.15, green: 0.28, blue: 0.48),
                onPrimaryContainer: Color(red: 0.82, green: 0.89, blue: 0.98),
                errorContainer: Color(red: 0.38, green: 0.0, blue: 0.02),
                onErrorContainer: Color(red: 1.0, green: 0.85, blue: 0.84)
            )
        case .amoled:
            return AppColors(
                surface: Color.black,
                surfaceVariant: Color(red: 0.07, green: 0.07, blue: 0.07),
                onSurface: Color.white,
                onSurfaceVariant: Color(red: 0.88, green: 0.88, blue: 0.88),
                primary: Color(red: 0.72, green: 0.72, blue: 0.72),
                primaryContainer: Color(red: 0.15, green: 0.15, blue: 0.15),
                onPrimaryContainer: Color.white,
                errorContainer: Color(red: 0.30, green: 0.0, blue: 0.0),
                onErrorContainer: Color.white
            )
        }
    }
}

// MARK: - Localizer Helper
func t(_ en: String, _ ru: String, _ lang: String) -> String {
    return lang == "ru" ? ru : en
}

// MARK: - Color Utilities for Adaptive Status Bar
extension Color {
    var isLight: Bool {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return false
        }
        let r = components[0]
        let g = components[1]
        let b = components[2]
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.55
    }
}

extension UIColor {
    static func fromCSSColor(_ css: String) -> UIColor? {
        let trimmed = css.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.hasPrefix("#") {
            var hex = String(trimmed.dropFirst())
            if hex.count == 3 {
                hex = hex.map { "\($0)\($0)" }.joined()
            }
            guard let intVal = UInt64(hex, radix: 16) else { return nil }
            if hex.count == 6 {
                let r = CGFloat((intVal >> 16) & 0xFF) / 255.0
                let g = CGFloat((intVal >> 8) & 0xFF) / 255.0
                let b = CGFloat(intVal & 0xFF) / 255.0
                return UIColor(red: r, green: g, blue: b, alpha: 1.0)
            } else if hex.count == 8 {
                let r = CGFloat((intVal >> 24) & 0xFF) / 255.0
                let g = CGFloat((intVal >> 16) & 0xFF) / 255.0
                let b = CGFloat((intVal >> 8) & 0xFF) / 255.0
                let a = CGFloat(intVal & 0xFF) / 255.0
                return UIColor(red: r, green: g, blue: b, alpha: a)
            }
            return nil
        }
        
        if trimmed.hasPrefix("rgb") {
            let nums = trimmed.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .filter { !$0.isEmpty }
                .compactMap { Double($0) }
            if nums.count >= 3 {
                let r = CGFloat(nums[0]) / 255.0
                let g = CGFloat(nums[1]) / 255.0
                let b = CGFloat(nums[2]) / 255.0
                let a = nums.count >= 4 ? CGFloat(nums[3]) : 1.0
                return UIColor(red: r, green: g, blue: b, alpha: a)
            }
        }
        return nil
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
