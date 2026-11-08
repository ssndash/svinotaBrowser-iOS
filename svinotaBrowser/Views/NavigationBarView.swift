import SwiftUI

struct NavigationBarView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        Group {
            if viewModel.isBarCollapsed && !viewModel.isSearchBarHidden {
                // Collapsed state: Small sleek strip with address (NO menu button)
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.isBarCollapsed = false
                            isFieldFocused = true
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(viewModel.colors.onSurfaceVariant)
                            
                            let displayAddress = URL(string: viewModel.inputUrl)?.host ?? viewModel.inputUrl
                            Text(displayAddress.isEmpty ? t("Search or type URL", "Поиск или адрес", viewModel.appLang) : displayAddress)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(viewModel.colors.onSurface)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .background(viewModel.colors.surfaceVariant.opacity(0.95))
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.16), radius: 8, x: 0, y: 2)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 4)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.85).combined(with: .opacity),
                    removal: .scale(scale: 0.85).combined(with: .opacity)
                ))
            } else if viewModel.isSearchBarHidden {
                // Minimalist Mode: Only small circular Menu button visible
                HStack {
                    if viewModel.navBarLayout == 1 {
                        menuButton
                        Spacer()
                    } else {
                        Spacer()
                        menuButton
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                    removal: .opacity.combined(with: .scale(scale: 0.9))
                ))
            } else {
                // Expanded state: Search Bar Capsule + Menu Button (Layout configurable)
                HStack(spacing: 8) {
                    if viewModel.navBarLayout == 1 {
                        menuButton
                        searchBarCapsule
                    } else {
                        searchBarCapsule
                        menuButton
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                    removal: .opacity.combined(with: .scale(scale: 0.9))
                ))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.isBarCollapsed)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.isSearchBarHidden)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.navBarLayout)
    }
    
    // Main Search M3 Surface Capsule (Elevation level 2)
    private var searchBarCapsule: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(viewModel.colors.onSurfaceVariant)
                .font(.system(size: 16, weight: .medium))
                .padding(.leading, 12)
                .onTapGesture {
                    isFieldFocused = true
                }
            
            TextField(
                t("Search...", "Поиск...", viewModel.appLang),
                text: $viewModel.inputUrl
            )
            .font(.system(size: 15))
            .foregroundColor(viewModel.colors.onSurface)
            .keyboardType(.webSearch)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .focused($isFieldFocused)
            .onSubmit {
                viewModel.navigate(to: viewModel.inputUrl)
                isFieldFocused = false
            }
            
            if let active = viewModel.activeTab, !active.url.isEmpty {
                Button(action: {
                    active.webView?.reload()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(viewModel.colors.onSurfaceVariant)
                        .font(.system(size: 15, weight: .medium))
                }
                .padding(.trailing, 4)
            }
            
            // Tab Count Button (M3 Outline Pill)
            Button(action: {
                isFieldFocused = false
                viewModel.showTabsSheet = true
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(
                            viewModel.colors.onSurfaceVariant,
                            lineWidth: 1.5
                        )
                        .frame(width: 24, height: 24)
                    
                    Text("\(viewModel.tabs.count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(viewModel.colors.onSurfaceVariant)
                }
            }
            .padding(.trailing, 12)
        }
        .frame(height: 56)
        .background(viewModel.colors.surfaceVariant)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 3)
    }
    
    // Circular M3 Menu Floating Button (Tone Elevation)
    private var menuButton: some View {
        Button(action: {
            isFieldFocused = false
            viewModel.currentMenuPage = "main"
            viewModel.showMenuSheet = true
        }) {
            ZStack {
                Circle()
                    .fill(viewModel.colors.surfaceVariant)
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 3)
                
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(viewModel.colors.onSurface)
            }
        }
    }
}
