import SwiftUI

struct TabsSheetView: View {
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Material 3 drag handle
            Capsule()
                .fill(viewModel.colors.onSurfaceVariant.opacity(0.4))
                .frame(width: 32, height: 4)
                .padding(.top, 16)
            
            // Top action bar: + New Tab, Close All
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.addNewTab()
                    viewModel.showTabsSheet = false
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                        Text(t("New Tab", "Новая вкладка", viewModel.appLang))
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(viewModel.colors.onPrimaryContainer)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(viewModel.colors.primaryContainer)
                    .clipShape(Capsule())
                }
                
                Button(action: {
                    viewModel.closeAllTabs()
                    viewModel.showTabsSheet = false
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(viewModel.colors.onErrorContainer)
                        .frame(width: 50, height: 50)
                        .background(viewModel.colors.errorContainer)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            
            // Tab list
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.tabs) { tab in
                        let isCurrent = tab.id == viewModel.activeTabId
                        
                        HStack(spacing: 12) {
                            // Favicon or Safari Icon
                            if let favicon = tab.favicon {
                                Image(uiImage: favicon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)
                                    .cornerRadius(4)
                            } else {
                                Image(systemName: "safari")
                                    .font(.system(size: 20))
                                    .foregroundColor(viewModel.colors.primary)
                                    .frame(width: 22, height: 22)
                            }
                            
                            // Title & URL
                            VStack(alignment: .leading, spacing: 2) {
                                let displayTitle = tab.url.isEmpty
                                    ? t("New Tab", "Новая вкладка", viewModel.appLang)
                                    : (URL(string: tab.url)?.host ?? tab.url)
                                
                                Text(displayTitle)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(viewModel.colors.onSurface)
                                    .lineLimit(1)
                                
                                if !tab.url.isEmpty {
                                    Text(tab.url)
                                        .font(.system(size: 11))
                                        .foregroundColor(viewModel.colors.onSurfaceVariant.opacity(0.8))
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            // Close tab button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.closeTab(id: tab.id)
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(viewModel.colors.onSurfaceVariant)
                                    .frame(width: 32, height: 32)
                                    .background(viewModel.colors.surfaceVariant.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            isCurrent
                            ? viewModel.colors.primaryContainer.opacity(0.6)
                            : viewModel.colors.surfaceVariant
                        )
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    isCurrent ? viewModel.colors.primary : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .onTapGesture {
                            viewModel.switchTab(id: tab.id)
                            viewModel.showTabsSheet = false
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(maxHeight: 280)
        }
        .padding(.bottom, 16)
        .background(viewModel.colors.surface)
        .cornerRadius(28, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.3), radius: 16, y: -4)
    }
}
