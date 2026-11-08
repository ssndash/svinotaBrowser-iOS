import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        GeometryReader { geo in
            let isWide = geo.size.width > 600
            let maxContentWidth: CGFloat = isWide ? min(geo.size.width - 48, 880) : 520
            let columnsCount = isWide ? (geo.size.width > 900 ? 8 : 6) : 4
            let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: columnsCount)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Top header row: Logo + title + Edit button
                    HStack(alignment: .center) {
                        HStack(spacing: 12) {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: isWide ? 60 : 52, height: isWide ? 60 : 52)
                                .cornerRadius(15)
                            
                            Text("svinotaBrowser")
                                .font(.custom("ComicNeue-Bold", size: isWide ? 42 : 36))
                                .foregroundColor(
                                    viewModel.wallpaperType != "default" ? .white : viewModel.colors.onSurface
                                )
                                .shadow(color: viewModel.wallpaperType != "default" ? Color.black.opacity(0.6) : Color.clear, radius: 2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        
                        Spacer()
                        
                        // Edit Wallpaper pencil icon (clean, no background)
                        Button(action: {
                            withAnimation {
                                viewModel.showDrawer = true
                            }
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: isWide ? 22 : 20, weight: .semibold))
                                .foregroundColor(
                                    viewModel.wallpaperType != "default" ? .white : viewModel.colors.primary
                                )
                        }
                        .padding(.trailing, isWide ? 32 : 24)
                    }
                    .padding(.leading, isWide ? 32 : 24)
                    .padding(.top, viewModel.barPosition == 1 ? (isWide ? 140 : 130) : (isWide ? 76 : 64))
                    .padding(.bottom, isWide ? 44 : 36)
                    
                    // Bookmarks grid on home
                    if viewModel.showBookmarksHome {
                        LazyVGrid(columns: columns, spacing: 20) {
                            // Default built-in bookmark: SSNDash
                            Button(action: {
                                viewModel.navigate(to: "https://ssndash.github.io")
                            }) {
                                VStack(spacing: 6) {
                                    Image("SSNDashLogo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(14)
                                    
                                    Text("SSNDash")
                                        .font(.system(size: 12))
                                        .foregroundColor(
                                            viewModel.wallpaperType != "default" ? .white : viewModel.colors.onSurface
                                        )
                                        .shadow(color: viewModel.wallpaperType != "default" ? Color.black.opacity(0.6) : Color.clear, radius: 2)
                                        .lineLimit(1)
                                }
                            }
                            
                            // User saved bookmarks
                            ForEach(viewModel.bookmarks, id: \.self) { bookmarkString in
                                let bookmark = BookmarkItem.from(composite: bookmarkString)
                                Button(action: {
                                    viewModel.navigate(to: bookmark.url)
                                }) {
                                    VStack(spacing: 6) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(viewModel.colors.primaryContainer)
                                                .frame(width: 60, height: 60)
                                            
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(viewModel.colors.primary)
                                        }
                                        
                                        let displayName = bookmark.name.isEmpty
                                            ? (URL(string: bookmark.url)?.host ?? bookmark.url)
                                            : bookmark.name
                                        
                                        Text(displayName)
                                            .font(.system(size: 12))
                                            .foregroundColor(
                                                viewModel.wallpaperType != "default" ? .white : viewModel.colors.onSurface
                                            )
                                            .shadow(color: viewModel.wallpaperType != "default" ? Color.black.opacity(0.6) : Color.clear, radius: 2)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, isWide ? 32 : 24)
                    }
                    
                    Spacer(minLength: 140)
                }
                .frame(maxWidth: maxContentWidth)
                .frame(maxWidth: .infinity)
            }
        }
    }
}
