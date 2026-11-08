import SwiftUI

struct MenuSheetView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @State private var downloadMessage: String? = nil
    @State private var showDownloadAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Material 3 drag handle
            Capsule()
                .fill(viewModel.colors.onSurfaceVariant.opacity(0.4))
                .frame(width: 32, height: 4)
                .padding(.top, 16)
                .padding(.bottom, 20)
            
            if viewModel.currentMenuPage == "main" {
                mainMenuView
            } else if viewModel.currentMenuPage == "history" {
                historyView
            } else if viewModel.currentMenuPage == "bookmarks" {
                bookmarksView
            } else if viewModel.currentMenuPage == "downloads" {
                downloadsView
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .background(viewModel.colors.surface)
        .cornerRadius(28, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.3), radius: 16, y: -4)
        .alert(isPresented: $showDownloadAlert) {
            Alert(
                title: Text(t("Video Downloader", "Загрузчик видео (yt-dlp)", viewModel.appLang)),
                message: Text(downloadMessage ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // Main Menu (Material 3 Cards)
    var mainMenuView: some View {
        VStack(spacing: 12) {
            // 3-button row: History, Bookmarks, Downloads
            if viewModel.menuShowQuickRow {
                HStack(spacing: 10) {
                    // History
                    Button(action: {
                        viewModel.currentMenuPage = "history"
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 24))
                                .foregroundColor(viewModel.colors.primary)
                            Text(t("History", "История", viewModel.appLang))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(viewModel.colors.onSurfaceVariant)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 84)
                        .background(viewModel.colors.surfaceVariant)
                        .cornerRadius(16)
                    }
                    
                    // Bookmarks
                    Button(action: {
                        viewModel.currentMenuPage = "bookmarks"
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 24))
                                .foregroundColor(viewModel.colors.primary)
                            Text(t("Bookmarks", "Закладки", viewModel.appLang))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(viewModel.colors.onSurfaceVariant)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 84)
                        .background(viewModel.colors.surfaceVariant)
                        .cornerRadius(16)
                    }
                    
                    // Downloads
                    Button(action: {
                        viewModel.currentMenuPage = "downloads"
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(viewModel.colors.primary)
                            Text(t("Downloads", "Загрузки", viewModel.appLang))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(viewModel.colors.onSurfaceVariant)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 84)
                        .background(viewModel.colors.surfaceVariant)
                        .cornerRadius(16)
                    }
                }
            }
            
            // Desktop site toggle (if on web page)
            if viewModel.menuShowDesktopSite, let active = viewModel.activeTab, !active.url.isEmpty {
                Button(action: {
                    active.isDesktopMode.toggle()
                    if let webView = active.webView {
                        let desktopUA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
                        webView.customUserAgent = active.isDesktopMode ? desktopUA : nil
                        webView.reload()
                    }
                    viewModel.showMenuSheet = false
                }) {
                    HStack(spacing: 14) {
                        Image(systemName: "desktopcomputer")
                            .font(.system(size: 20))
                            .foregroundColor(viewModel.colors.primary)
                        Text(t("Desktop site", "Версия для ПК", viewModel.appLang))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(viewModel.colors.onSurface)
                        Spacer()
                        if active.isDesktopMode {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(viewModel.colors.primary)
                        }
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 56)
                    .background(viewModel.colors.surfaceVariant)
                    .cornerRadius(16)
                }
            }
            
            // Actions for current page (Bookmark & Video Download)
            if let active = viewModel.activeTab, !active.url.isEmpty {
                // Add to Bookmarks
                if viewModel.menuShowAddBookmark {
                    Button(action: {
                        viewModel.showMenuSheet = false
                        viewModel.showAddBookmarkDialog = true
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 20))
                                .foregroundColor(viewModel.colors.primary)
                            Text(t("Add to Bookmarks", "Добавить в закладки", viewModel.appLang))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(viewModel.colors.onSurface)
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 52)
                        .background(viewModel.colors.surfaceVariant)
                        .cornerRadius(16)
                    }
                }
                
                // Download Video via yt-dlp
                if viewModel.menuShowDownloadVideo {
                    Button(action: {
                        downloadMessage = t("Searching for video stream via yt-dlp...", "Поиск видеопотока через yt-dlp...", viewModel.appLang)
                        showDownloadAlert = true
                        viewModel.downloadCurrentPageVideo { success, msg in
                            downloadMessage = msg
                        }
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: "arrow.down.to.line.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(viewModel.colors.primary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t("Download Video (yt-dlp)", "Скачать видео (yt-dlp)", viewModel.appLang))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(viewModel.colors.onSurface)
                                Text(t("YouTube, Twitter/X, Reddit, TikTok", "YouTube, Twitter/X, Reddit, TikTok", viewModel.appLang))
                                    .font(.system(size: 11))
                                    .foregroundColor(viewModel.colors.onSurfaceVariant)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 54)
                        .background(viewModel.colors.surfaceVariant)
                        .cornerRadius(16)
                    }
                }
            }
            
            // Dark Reader toggle row (Auto-reloads web pages)
            if viewModel.menuShowDarkReader {
                Button(action: {
                    viewModel.isDarkReaderEnabled.toggle()
                }) {
                    HStack(spacing: 14) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 20))
                            .foregroundColor(viewModel.isDarkReaderEnabled ? viewModel.colors.primary : viewModel.colors.onSurfaceVariant)
                        Text(t("Dark Reader", "Dark Reader (Тёмная тема сайтов)", viewModel.appLang))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(viewModel.colors.onSurface)
                        Spacer()
                        Toggle("", isOn: $viewModel.isDarkReaderEnabled)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: viewModel.colors.primary))
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 52)
                    .background(viewModel.colors.surfaceVariant)
                    .cornerRadius(16)
                }
            }
            
            // Hide/Show Search Bar toggle row
            if viewModel.menuShowHideSearchBar {
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.isSearchBarHidden.toggle()
                        viewModel.showMenuSheet = false
                    }
                }) {
                    HStack(spacing: 14) {
                        Image(systemName: viewModel.isSearchBarHidden ? "magnifyingglass.circle.fill" : "eye.slash.fill")
                            .font(.system(size: 20))
                            .foregroundColor(viewModel.colors.primary)
                        Text(viewModel.isSearchBarHidden
                            ? t("Show search bar", "Показать строку поиска", viewModel.appLang)
                            : t("Hide search bar", "Скрыть строку поиска", viewModel.appLang))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(viewModel.colors.onSurface)
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 52)
                    .background(viewModel.colors.surfaceVariant)
                    .cornerRadius(16)
                }
            }
            
            // Settings button
            Button(action: {
                viewModel.showMenuSheet = false
                viewModel.showFullSettings = true
            }) {
                HStack(spacing: 14) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.colors.primary)
                    Text(t("Settings", "Настройки", viewModel.appLang))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(viewModel.colors.onSurface)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(viewModel.colors.onSurfaceVariant)
                }
                .padding(.horizontal, 18)
                .frame(height: 56)
                .background(viewModel.colors.surfaceVariant)
                .cornerRadius(16)
            }
        }
    }
    
    // History Page
    var historyView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button(action: {
                    viewModel.currentMenuPage = "main"
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(viewModel.colors.primary)
                }
                Text(t("History", "История", viewModel.appLang))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(viewModel.colors.onSurface)
                Spacer()
            }
            .padding(.bottom, 2)
            
            if viewModel.history.isEmpty {
                Text(t("No history yet", "История пуста", viewModel.appLang))
                    .font(.system(size: 14))
                    .foregroundColor(viewModel.colors.onSurfaceVariant)
                    .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.history.reversed(), id: \.self) { urlString in
                            let domain = URL(string: urlString)?.host ?? urlString
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(domain)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(viewModel.colors.onSurface)
                                        .lineLimit(1)
                                    Text(urlString)
                                        .font(.system(size: 12))
                                        .foregroundColor(viewModel.colors.onSurfaceVariant)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Button(action: {
                                    viewModel.deleteHistoryItem(urlString)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(viewModel.colors.onSurfaceVariant)
                                        .font(.system(size: 16))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(viewModel.colors.surfaceVariant)
                            .cornerRadius(14)
                            .onTapGesture {
                                viewModel.navigate(to: urlString)
                                viewModel.showMenuSheet = false
                            }
                        }
                    }
                }
                .frame(maxHeight: 260)
            }
        }
    }
    
    // Bookmarks Page
    var bookmarksView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button(action: {
                    viewModel.currentMenuPage = "main"
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(viewModel.colors.primary)
                }
                Text(t("Bookmarks", "Закладки", viewModel.appLang))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(viewModel.colors.onSurface)
                Spacer()
                Button(action: {
                    viewModel.showMenuSheet = false
                    viewModel.showAddBookmarkDialog = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(viewModel.colors.primary)
                }
            }
            .padding(.bottom, 2)
            
            ScrollView {
                VStack(spacing: 8) {
                    // Default SSNDash item
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SSNDash")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(viewModel.colors.onSurface)
                            Text("https://ssndash.github.io")
                                .font(.system(size: 12))
                                .foregroundColor(viewModel.colors.onSurfaceVariant)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(viewModel.colors.surfaceVariant)
                    .cornerRadius(14)
                    .onTapGesture {
                        viewModel.navigate(to: "https://ssndash.github.io")
                        viewModel.showMenuSheet = false
                    }
                    
                    // User bookmarks
                    ForEach(viewModel.bookmarks, id: \.self) { item in
                        let bookmark = BookmarkItem.from(composite: item)
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(bookmark.name.isEmpty ? (URL(string: bookmark.url)?.host ?? bookmark.url) : bookmark.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(viewModel.colors.onSurface)
                                    .lineLimit(1)
                                Text(bookmark.url)
                                    .font(.system(size: 12))
                                    .foregroundColor(viewModel.colors.onSurfaceVariant)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Button(action: {
                                viewModel.deleteBookmark(item)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(viewModel.colors.onSurfaceVariant)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(viewModel.colors.surfaceVariant)
                        .cornerRadius(14)
                        .onTapGesture {
                            viewModel.navigate(to: bookmark.url)
                            viewModel.showMenuSheet = false
                        }
                    }
                }
            }
            .frame(maxHeight: 260)
        }
    }
    
    // Integrated Downloads Page
    var downloadsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button(action: {
                    viewModel.currentMenuPage = "main"
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(viewModel.colors.primary)
                }
                Text(t("Downloads", "Загрузки", viewModel.appLang))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(viewModel.colors.onSurface)
                Spacer()
                if !viewModel.downloads.isEmpty {
                    Button(action: {
                        viewModel.clearDownloads()
                    }) {
                        Text(t("Clear All", "Очистить", viewModel.appLang))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(viewModel.colors.error)
                    }
                }
            }
            .padding(.bottom, 2)
            
            if viewModel.downloads.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 36))
                        .foregroundColor(viewModel.colors.onSurfaceVariant.opacity(0.6))
                    Text(t("No downloads yet", "Нет загрузок", viewModel.appLang))
                        .font(.system(size: 14))
                        .foregroundColor(viewModel.colors.onSurfaceVariant)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.downloads) { item in
                            HStack(spacing: 12) {
                                Image(systemName: fileIcon(for: item.filename))
                                    .font(.system(size: 22))
                                    .foregroundColor(viewModel.colors.primary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.filename)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(viewModel.colors.onSurface)
                                        .lineLimit(1)
                                    
                                    HStack(spacing: 6) {
                                        if !item.fileSize.isEmpty {
                                            Text(item.fileSize)
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(viewModel.colors.primary)
                                        }
                                        Text(item.url)
                                            .font(.system(size: 11))
                                            .foregroundColor(viewModel.colors.onSurfaceVariant)
                                            .lineLimit(1)
                                    }
                                    
                                    if item.isDownloading {
                                        VStack(alignment: .leading, spacing: 3) {
                                            ProgressView(value: item.progress)
                                                .progressViewStyle(LinearProgressViewStyle(tint: viewModel.colors.primary))
                                                .frame(height: 3)
                                            
                                            HStack {
                                                Text("\(Int(item.progress * 100))%")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(viewModel.colors.primary)
                                                Spacer()
                                            }
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.removeDownload(id: item.id)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(viewModel.colors.error)
                                        .font(.system(size: 16))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(viewModel.colors.surfaceVariant)
                            .cornerRadius(14)
                            .onTapGesture {
                                if let localPath = item.localPath, FileManager.default.fileExists(atPath: localPath) {
                                    openFile(at: localPath)
                                } else if let url = URL(string: item.url) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 260)
            }
        }
    }
    
    private func fileIcon(for name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "png", "jpg", "jpeg", "gif", "webp", "heic":
            return "photo.fill"
        case "mp4", "mov", "mkv", "webm":
            return "film.fill"
        case "mp3", "m4a", "wav", "aac", "flac":
            return "music.note"
        case "zip", "rar", "7z", "tar", "gz":
            return "doc.zipper"
        case "pdf":
            return "doc.richtext.fill"
        case "ipa", "apk", "dmg", "deb":
            return "shippingbox.fill"
        default:
            return "doc.fill"
        }
    }
    
    private func openFile(at path: String) {
        let url = URL(fileURLWithPath: path)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        top.present(activityVC, animated: true)
    }
}
