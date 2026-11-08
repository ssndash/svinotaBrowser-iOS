import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = BrowserViewModel()
    
    var body: some View {
        GeometryReader { geo in
            let topSafeArea = max(geo.safeAreaInsets.top, 44)
            let isBrowsingWeb = viewModel.activeTab?.url.isEmpty == false
            let isWide = geo.size.width > 600
            let navBarMaxWidth: CGFloat = isWide ? min(geo.size.width - 64, 760) : 540
            let sheetMaxWidth: CGFloat = isWide ? min(geo.size.width - 64, 680) : 540
            
            ZStack(alignment: .top) {
                // Background
                backgroundView
                    .ignoresSafeArea()
                
                // Web Content or Home View
                ZStack {
                    if let active = viewModel.activeTab {
                        if active.url.isEmpty {
                            HomeView(viewModel: viewModel)
                        } else {
                            // Native WebKit View that starts strictly below the status bar (or below top nav bar)
                            NativeWebView(tab: active, viewModel: viewModel)
                                .padding(.top, viewModel.barPosition == 1 ? (topSafeArea + 64) : topSafeArea)
                                .ignoresSafeArea(edges: .bottom)
                            
                            // Expressive Loading Overlay
                            if active.isLoading {
                                VStack {
                                    HStack {
                                        Spacer()
                                        ZStack {
                                            Circle()
                                                .fill(viewModel.colors.surfaceVariant)
                                                .frame(width: 44, height: 44)
                                                .shadow(color: Color.black.opacity(0.15), radius: 6)
                                            
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: viewModel.colors.primary))
                                        }
                                        Spacer()
                                    }
                                    .padding(.top, (viewModel.barPosition == 1 ? (topSafeArea + 76) : (topSafeArea + 16)))
                                    Spacer()
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                                .animation(.easeInOut(duration: 0.2), value: active.isLoading)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Top Status Bar Adaptive Background (Adapts dynamically to the website's theme/header color)
                if isBrowsingWeb && viewModel.barPosition == 0 {
                    VStack(spacing: 0) {
                        (viewModel.activeSiteThemeColor ?? viewModel.colors.surface)
                            .frame(height: topSafeArea)
                            .animation(.easeInOut(duration: 0.25), value: viewModel.activeSiteThemeColor)
                            .overlay(
                                VStack {
                                    Spacer()
                                    Divider()
                                        .opacity(0.12)
                                }
                            )
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(edges: .top)
                    .allowsHitTesting(false)
                    .zIndex(8)
                }
                
                // Transparent dismiss layer when keyboard is open
                if viewModel.keyboardHeight > 0 {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .zIndex(4)
                }
                
                // Floating Navigation Bar (Top or Bottom)
                VStack(spacing: 0) {
                    if viewModel.barPosition == 1 {
                        VStack(spacing: 0) {
                            // Top safe area spacer matching status bar
                            Color.clear
                                .frame(height: topSafeArea)
                            
                            NavigationBarView(viewModel: viewModel)
                                .frame(maxWidth: navBarMaxWidth)
                                .padding(.top, 4)
                                .padding(.bottom, 4)
                            
                            if let toast = viewModel.activeDownloadToast {
                                DownloadToastView(toast: toast, viewModel: viewModel)
                                    .frame(maxWidth: navBarMaxWidth)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 6)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .background(
                            (isBrowsingWeb ? (viewModel.activeSiteThemeColor ?? viewModel.colors.surface) : viewModel.colors.surface)
                                .ignoresSafeArea(edges: .top)
                                .animation(.easeInOut(duration: 0.25), value: viewModel.activeSiteThemeColor)
                                .overlay(
                                    VStack {
                                        Spacer()
                                        Divider()
                                            .opacity(0.12)
                                    }
                                )
                        )
                        .offset(y: (viewModel.isBarVisible || viewModel.activeTab?.url.isEmpty == true) ? 0 : -(topSafeArea + 80))
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: viewModel.isBarVisible)
                        
                        Spacer()
                    } else {
                        Spacer()
                        
                        if let toast = viewModel.activeDownloadToast {
                            DownloadToastView(toast: toast, viewModel: viewModel)
                                .frame(maxWidth: navBarMaxWidth)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        NavigationBarView(viewModel: viewModel)
                            .frame(maxWidth: navBarMaxWidth)
                            .padding(.bottom, viewModel.keyboardHeight > 0 ? (viewModel.keyboardHeight + 8) : max(geo.safeAreaInsets.bottom, 12))
                    }
                }
                .frame(maxWidth: .infinity)
                .zIndex(9)
                
                // Bottom Sheet Modal overlay: Menu
                if viewModel.showMenuSheet {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                viewModel.showMenuSheet = false
                            }
                        }
                        .zIndex(10)
                    
                    VStack {
                        Spacer()
                        MenuSheetView(viewModel: viewModel)
                            .frame(maxWidth: sheetMaxWidth)
                            .cornerRadius(24, corners: [.topLeft, .topRight])
                    }
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(edges: .bottom)
                    .transition(.move(edge: .bottom))
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.showMenuSheet)
                    .zIndex(11)
                }
                
                // Bottom Sheet Modal overlay: Tabs
                if viewModel.showTabsSheet {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                viewModel.showTabsSheet = false
                            }
                        }
                        .zIndex(10)
                    
                    VStack {
                        Spacer()
                        TabsSheetView(viewModel: viewModel)
                            .frame(maxWidth: sheetMaxWidth)
                            .cornerRadius(24, corners: [.topLeft, .topRight])
                    }
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(edges: .bottom)
                    .transition(.move(edge: .bottom))
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.showTabsSheet)
                    .zIndex(11)
                }
                
                // Drawer sidebar for Wallpaper Settings
                if viewModel.showDrawer {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                viewModel.showDrawer = false
                            }
                        }
                        .zIndex(12)
                    
                    DrawerSidebarView(viewModel: viewModel)
                        .transition(.move(edge: .trailing))
                        .zIndex(13)
                }
                
                // Color Picker Dialog
                if viewModel.showColorPicker {
                    ColorPickerDialog(viewModel: viewModel, isPresented: $viewModel.showColorPicker)
                        .zIndex(15)
                }
                
                // Add Bookmark Dialog
                if viewModel.showAddBookmarkDialog {
                    AddBookmarkDialog(viewModel: viewModel, isPresented: $viewModel.showAddBookmarkDialog)
                        .zIndex(15)
                }
            }
        }
        .ignoresSafeArea()
        .fullScreenCover(isPresented: $viewModel.showFullSettings) {
            SettingsView(viewModel: viewModel)
        }
        .preferredColorScheme({
            if viewModel.activeTab?.url.isEmpty == false, let siteColor = viewModel.activeSiteThemeColor {
                return siteColor.isLight ? .light : .dark
            }
            return viewModel.themeMode.isDark ? .dark : .light
        }())
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if let active = viewModel.activeTab, active.url.isEmpty {
            switch viewModel.wallpaperType {
            case "color":
                Color(hex: viewModel.wallpaperColorHex)
            default:
                viewModel.colors.surface
            }
        } else {
            viewModel.colors.surface
        }
    }
}

// MARK: - Download Progress Toast
struct DownloadToastView: View {
    let toast: ActiveDownloadToast
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.isFinished ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(toast.isFinished ? .green : viewModel.colors.primary)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(toast.filename)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(viewModel.colors.onSurface)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if !toast.bytesText.isEmpty {
                        Text(toast.bytesText)
                            .font(.system(size: 11))
                            .foregroundColor(viewModel.colors.onSurfaceVariant)
                    }
                    if !toast.isFinished {
                        Text("• \(Int(toast.progress * 100))%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(viewModel.colors.primary)
                    }
                }
                
                if !toast.isFinished {
                    ProgressView(value: toast.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: viewModel.colors.primary))
                        .frame(height: 3)
                }
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    viewModel.activeDownloadToast = nil
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(viewModel.colors.onSurfaceVariant)
                    .padding(6)
                    .background(viewModel.colors.onSurfaceVariant.opacity(0.12))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(viewModel.colors.surfaceVariant)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
    }
}
