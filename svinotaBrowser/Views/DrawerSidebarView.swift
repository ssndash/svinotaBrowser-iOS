import SwiftUI

struct DrawerSidebarView: View {
    @ObservedObject var viewModel: BrowserViewModel
    
    let colorPresets: [(String, String)] = [
        ("Midnight", "#1A1C24"),
        ("AMOLED Black", "#000000"),
        ("Slate", "#1E293B"),
        ("Emerald", "#064E3B"),
        ("Indigo", "#312E81"),
        ("Crimson", "#881337"),
        ("Amber", "#78350F"),
        ("Light Gray", "#E2E8F0")
    ]
    
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            
            VStack(alignment: .leading, spacing: 18) {
                Text(t("Home Customization", "Кастомизация", viewModel.appLang))
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(viewModel.colors.onSurface)
                    .padding(.top, 44)
                    .padding(.bottom, 4)
                
                // 1. System Default
                VStack(alignment: .leading, spacing: 6) {
                    Button(action: {
                        withAnimation {
                            viewModel.wallpaperType = "default"
                            viewModel.saveSettings()
                        }
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(viewModel.colors.surfaceVariant)
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 18))
                                    .foregroundColor(viewModel.colors.primary)
                            }
                            
                            Text(t("Default Theme", "Тема приложения", viewModel.appLang))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(viewModel.colors.onSurface)
                            
                            Spacer()
                            
                            if viewModel.wallpaperType == "default" {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(viewModel.colors.primary)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(10)
                        .background(viewModel.colors.surfaceVariant.opacity(viewModel.wallpaperType == "default" ? 0.9 : 0.4))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(viewModel.colors.primary, lineWidth: viewModel.wallpaperType == "default" ? 1.5 : 0)
                        )
                    }
                }
                
                // 2. Solid Color Palette
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(t("Solid Color", "Цвет фона", viewModel.appLang))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(viewModel.colors.onSurface)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.showColorPicker = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 13))
                                Text(t("More", "Другой", viewModel.appLang))
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(viewModel.colors.primary)
                        }
                    }
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(colorPresets, id: \.1) { name, hex in
                            let isSelected = viewModel.wallpaperType == "color" && viewModel.wallpaperColorHex.uppercased() == hex.uppercased()
                            Button(action: {
                                withAnimation {
                                    viewModel.wallpaperType = "color"
                                    viewModel.wallpaperColorHex = hex
                                    viewModel.saveSettings()
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                    
                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .shadow(color: .black.opacity(0.5), radius: 2)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                // Show Bookmarks toggle
                Toggle(isOn: $viewModel.showBookmarksHome) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t("Show Bookmarks", "Показывать закладки", viewModel.appLang))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(viewModel.colors.onSurface)
                        Text(t("Display saved links on home", "Ярлыки на главном экране", viewModel.appLang))
                            .font(.system(size: 11))
                            .foregroundColor(viewModel.colors.onSurfaceVariant)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: viewModel.colors.primary))
                .onChange(of: viewModel.showBookmarksHome) { _ in
                    viewModel.saveSettings()
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(width: 290)
            .background(viewModel.colors.surface)
            .cornerRadius(20, corners: [.topLeft, .bottomLeft])
            .shadow(color: Color.black.opacity(0.35), radius: 14, x: -6, y: 0)
        }
        .onDisappear {
            viewModel.saveSettings()
        }
    }
}

// Rounded corners extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
