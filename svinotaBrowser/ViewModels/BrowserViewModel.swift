import Foundation
import SwiftUI
import Combine

struct SavedSettings: Codable {
    var themeMode: Int
    var searchEngine: String
    var appLang: String
    var barPosition: Int
    var customSearchUrl: String
    var customSearchEngineName: String?
    var startupBehavior: Int
    var wallpaperType: String
    var wallpaperColorHex: String
    var showBookmarksHome: Bool
    var isAdBlockerEnabled: Bool?
    var isDarkReaderEnabled: Bool?
    var userAgentPreset: Int?
    var customUserAgent: String?
    var navBarLayout: Int?
    var isSearchBarHidden: Bool?
    var homePageType: Int?
    var customHomePageUrl: String?
    var menuShowQuickRow: Bool?
    var menuShowDesktopSite: Bool?
    var menuShowAddBookmark: Bool?
    var menuShowDownloadVideo: Bool?
    var menuShowDarkReader: Bool?
    var menuShowHideSearchBar: Bool?
}

struct SavedTab: Codable {
    var id: Int64
    var url: String
    var title: String?
}

struct SavedTabsState: Codable {
    var activeTabId: Int64
    var tabs: [SavedTab]
}

class BrowserViewModel: ObservableObject {
    // Preferences & Settings
    @Published var themeMode: ThemeMode {
        didSet {
            saveSettings()
        }
    }
    @Published var searchEngine: String {
        didSet {
            saveSettings()
        }
    }
    @Published var appLang: String {
        didSet {
            saveSettings()
        }
    }
    @Published var barPosition: Int { // 0: Bottom, 1: Top
        didSet {
            saveSettings()
        }
    }
    @Published var customSearchUrl: String {
        didSet {
            saveSettings()
        }
    }
    @Published var customSearchEngineName: String {
        didSet {
            saveSettings()
        }
    }
    
    // Navigation Bar Layout: 0 = Menu on right (default), 1 = Menu on left
    @Published var navBarLayout: Int {
        didSet {
            saveSettings()
        }
    }
    
    // Minimalist Search Bar: hide search bar completely
    @Published var isSearchBarHidden: Bool {
        didSet {
            saveSettings()
        }
    }
    
    var effectiveStartPageUrl: String {
        if homePageType == 1 {
            let trimmed = customHomePageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed.lowercased().hasPrefix("http") ? trimmed : "https://\(trimmed)"
            }
        }
        return ""
    }
    
    // Start Page: 0 = Built-in Home, 1 = Custom URL
    @Published var homePageType: Int {
        didSet {
            saveSettings()
            if homePageType == 1 {
                let startUrl = effectiveStartPageUrl
                if !startUrl.isEmpty && activeTab?.url.isEmpty == true {
                    navigate(to: startUrl)
                }
            }
        }
    }
    @Published var customHomePageUrl: String {
        didSet {
            saveSettings()
            if homePageType == 1 {
                let startUrl = effectiveStartPageUrl
                if !startUrl.isEmpty && activeTab?.url.isEmpty == true {
                    navigate(to: startUrl)
                }
            }
        }
    }
    
    // Menu items customization (toggles to hide/show items in menu sheet)
    @Published var menuShowQuickRow: Bool { didSet { saveSettings() } }
    @Published var menuShowDesktopSite: Bool { didSet { saveSettings() } }
    @Published var menuShowAddBookmark: Bool { didSet { saveSettings() } }
    @Published var menuShowDownloadVideo: Bool { didSet { saveSettings() } }
    @Published var menuShowDarkReader: Bool { didSet { saveSettings() } }
    @Published var menuShowHideSearchBar: Bool { didSet { saveSettings() } }
    
    // Active download HUD toast above navigation bar
    @Published var activeDownloadToast: ActiveDownloadToast? = nil
    
    // Dark Reader (Force dark mode on websites)
    @Published var isDarkReaderEnabled: Bool {
        didSet {
            saveSettings()
            reloadAllTabs()
        }
    }
    
    func reloadAllTabs() {
        for tab in tabs {
            tab.webView?.reload()
        }
    }
    
    // Startup Behavior (0: Last opened page, 1: New tab / Home)
    @Published var startupBehavior: Int {
        didSet {
            saveSettings()
        }
    }
    
    // Wallpaper & Home Customization Settings (Persistent to disk)
    @Published var wallpaperType: String { // "default", "color"
        didSet {
            saveSettings()
        }
    }
    @Published var wallpaperColorHex: String {
        didSet {
            saveSettings()
        }
    }
    @Published var wallpaperBase64: String? {
        didSet {
            saveWallpaperImage(wallpaperBase64)
        }
    }
    @Published var showBookmarksHome: Bool {
        didSet {
            saveSettings()
        }
    }
    
    // Ad Blocker
    @Published var isAdBlockerEnabled: Bool {
        didSet {
            saveSettings()
        }
    }
    
    // User Agent: 0 = Mobile Safari (Default), 1 = Desktop Chrome, 2 = Mobile Android, 3 = Custom
    @Published var userAgentPreset: Int {
        didSet {
            saveSettings()
            updateAllTabsUserAgent()
        }
    }
    @Published var customUserAgent: String {
        didSet {
            saveSettings()
            if userAgentPreset == 3 {
                updateAllTabsUserAgent()
            }
        }
    }
    
    static let desktopChromeUA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    static let androidChromeUA = "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36"
    
    func effectiveUserAgent(for tab: TabItem) -> String? {
        if tab.isDesktopMode {
            return BrowserViewModel.desktopChromeUA
        }
        switch userAgentPreset {
        case 1:
            return BrowserViewModel.desktopChromeUA
        case 2:
            return BrowserViewModel.androidChromeUA
        case 3:
            let trimmed = customUserAgent.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        default:
            return nil
        }
    }
    
    func updateAllTabsUserAgent() {
        for tab in tabs {
            let targetUA = effectiveUserAgent(for: tab)
            tab.webView?.customUserAgent = targetUA
        }
    }
    
    // Tabs & Navigation State
    @Published var tabs: [TabItem] = []
    @Published var activeTabId: Int64 = 0
    @Published var inputUrl: String = ""
    @Published var isBarVisible: Bool = true
    @Published var isBarCollapsed: Bool = false
    
    // History, Bookmarks & Downloads
    @Published var history: [String] = []
    @Published var bookmarks: [String] = []
    @Published var downloads: [DownloadItem] = []
    
    // UI Navigation Overlays
    @Published var showDrawer: Bool = false
    @Published var showColorPicker: Bool = false
    @Published var showTabsSheet: Bool = false
    @Published var showMenuSheet: Bool = false
    @Published var showFullSettings: Bool = false
    @Published var showAddBookmarkDialog: Bool = false
    @Published var currentMenuPage: String = "main" // "main", "history", "bookmarks", "downloads"
    
    // Keyboard State
    @Published var keyboardHeight: CGFloat = 0
    private var keyboardCancellables = Set<AnyCancellable>()
    
    // Adaptive Site Theme Color
    @Published var activeSiteThemeColor: Color? = nil
    
    var activeTab: TabItem? {
        tabs.first(where: { $0.id == activeTabId }) ?? tabs.first
    }
    
    var colors: AppColors {
        AppColors.forMode(themeMode)
    }
    
    private static var settingsFileUrl: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("svinota_settings.json")
    }
    
    private static var tabsFileUrl: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("svinota_tabs.json")
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(themeMode.rawValue, forKey: "theme_mode")
        defaults.set(searchEngine, forKey: "search_engine")
        defaults.set(appLang, forKey: "app_lang")
        defaults.set(barPosition, forKey: "bar_position")
        defaults.set(customSearchUrl, forKey: "custom_search")
        defaults.set(customSearchEngineName, forKey: "custom_search_name")
        defaults.set(startupBehavior, forKey: "startup_behavior")
        defaults.set(wallpaperType, forKey: "wp_type")
        defaults.set(wallpaperColorHex, forKey: "wp_color")
        defaults.set(showBookmarksHome, forKey: "show_bookmarks_home")
        defaults.set(isAdBlockerEnabled, forKey: "ad_blocker_enabled")
        defaults.set(isDarkReaderEnabled, forKey: "dark_reader_enabled")
        defaults.set(userAgentPreset, forKey: "user_agent_preset")
        defaults.set(customUserAgent, forKey: "custom_user_agent")
        defaults.set(navBarLayout, forKey: "navbar_layout")
        defaults.set(isSearchBarHidden, forKey: "is_search_bar_hidden")
        defaults.set(homePageType, forKey: "homepage_type")
        defaults.set(customHomePageUrl, forKey: "custom_homepage_url")
        defaults.set(menuShowQuickRow, forKey: "menu_show_quick_row")
        defaults.set(menuShowDesktopSite, forKey: "menu_show_desktop_site")
        defaults.set(menuShowAddBookmark, forKey: "menu_show_add_bookmark")
        defaults.set(menuShowDownloadVideo, forKey: "menu_show_download_video")
        defaults.set(menuShowDarkReader, forKey: "menu_show_dark_reader")
        defaults.set(menuShowHideSearchBar, forKey: "menu_show_hide_search_bar")
        defaults.synchronize()
        
        // Immediate atomic disk write to Documents/svinota_settings.json
        let settings = SavedSettings(
            themeMode: themeMode.rawValue,
            searchEngine: searchEngine,
            appLang: appLang,
            barPosition: barPosition,
            customSearchUrl: customSearchUrl,
            customSearchEngineName: customSearchEngineName,
            startupBehavior: startupBehavior,
            wallpaperType: wallpaperType,
            wallpaperColorHex: wallpaperColorHex,
            showBookmarksHome: showBookmarksHome,
            isAdBlockerEnabled: isAdBlockerEnabled,
            isDarkReaderEnabled: isDarkReaderEnabled,
            userAgentPreset: userAgentPreset,
            customUserAgent: customUserAgent,
            navBarLayout: navBarLayout,
            isSearchBarHidden: isSearchBarHidden,
            homePageType: homePageType,
            customHomePageUrl: customHomePageUrl,
            menuShowQuickRow: menuShowQuickRow,
            menuShowDesktopSite: menuShowDesktopSite,
            menuShowAddBookmark: menuShowAddBookmark,
            menuShowDownloadVideo: menuShowDownloadVideo,
            menuShowDarkReader: menuShowDarkReader,
            menuShowHideSearchBar: menuShowHideSearchBar
        )
        if let data = try? JSONEncoder().encode(settings), let url = BrowserViewModel.settingsFileUrl {
            try? data.write(to: url, options: .atomic)
        }
    }
    
    init() {
        let defaults = UserDefaults.standard
        let systemLang = Locale.preferredLanguages.first?.hasPrefix("ru") == true ? "ru" : "en"
        
        // 1. Try to load from Documents/svinota_settings.json first (100% immune to cfprefsd wipe/caching)
        if let url = BrowserViewModel.settingsFileUrl,
           let data = try? Data(contentsOf: url),
           let saved = try? JSONDecoder().decode(SavedSettings.self, from: data) {
            
            self.themeMode = ThemeMode(rawValue: saved.themeMode) ?? .light
            self.searchEngine = saved.searchEngine
            self.appLang = saved.appLang
            self.barPosition = saved.barPosition
            self.customSearchUrl = saved.customSearchUrl
            self.customSearchEngineName = saved.customSearchEngineName ?? "Custom"
            self.startupBehavior = saved.startupBehavior
            self.wallpaperType = saved.wallpaperType
            self.wallpaperColorHex = saved.wallpaperColorHex
            self.showBookmarksHome = saved.showBookmarksHome
            self.isAdBlockerEnabled = saved.isAdBlockerEnabled ?? true
            self.isDarkReaderEnabled = saved.isDarkReaderEnabled ?? false
            self.userAgentPreset = saved.userAgentPreset ?? 0
            self.customUserAgent = saved.customUserAgent ?? ""
            self.navBarLayout = saved.navBarLayout ?? 0
            self.isSearchBarHidden = saved.isSearchBarHidden ?? false
            self.homePageType = saved.homePageType ?? 0
            self.customHomePageUrl = saved.customHomePageUrl ?? ""
            self.menuShowQuickRow = saved.menuShowQuickRow ?? true
            self.menuShowDesktopSite = saved.menuShowDesktopSite ?? true
            self.menuShowAddBookmark = saved.menuShowAddBookmark ?? true
            self.menuShowDownloadVideo = saved.menuShowDownloadVideo ?? true
            self.menuShowDarkReader = saved.menuShowDarkReader ?? true
            self.menuShowHideSearchBar = saved.menuShowHideSearchBar ?? true
            
        } else {
            // 2. Fallback to UserDefaults
            if let savedTheme = defaults.object(forKey: "theme_mode") as? Int {
                if savedTheme == 0 {
                    self.themeMode = .light
                } else if savedTheme == 1 || savedTheme == 3 {
                    self.themeMode = .dark
                } else if savedTheme == 2 || savedTheme >= 4 {
                    self.themeMode = .amoled
                } else {
                    self.themeMode = ThemeMode(rawValue: savedTheme) ?? .light
                }
            } else {
                self.themeMode = .light
            }
            
            self.searchEngine = defaults.string(forKey: "search_engine") ?? "https://duckduckgo.com/?q="
            self.appLang = defaults.string(forKey: "app_lang") ?? systemLang
            self.barPosition = defaults.integer(forKey: "bar_position")
            self.customSearchUrl = defaults.string(forKey: "custom_search") ?? "https://"
            self.customSearchEngineName = defaults.string(forKey: "custom_search_name") ?? "Custom"
            self.startupBehavior = defaults.integer(forKey: "startup_behavior")
            
            self.wallpaperType = defaults.string(forKey: "wp_type") ?? "default"
            self.wallpaperColorHex = defaults.string(forKey: "wp_color") ?? "#1A1C24"
            self.showBookmarksHome = defaults.object(forKey: "show_bookmarks_home") != nil ? defaults.bool(forKey: "show_bookmarks_home") : true
            self.isAdBlockerEnabled = defaults.object(forKey: "ad_blocker_enabled") != nil ? defaults.bool(forKey: "ad_blocker_enabled") : true
            self.isDarkReaderEnabled = defaults.bool(forKey: "dark_reader_enabled")
            self.userAgentPreset = defaults.integer(forKey: "user_agent_preset")
            self.customUserAgent = defaults.string(forKey: "custom_user_agent") ?? ""
            self.navBarLayout = defaults.integer(forKey: "navbar_layout")
            self.isSearchBarHidden = defaults.bool(forKey: "is_search_bar_hidden")
            self.homePageType = defaults.integer(forKey: "homepage_type")
            self.customHomePageUrl = defaults.string(forKey: "custom_homepage_url") ?? ""
            self.menuShowQuickRow = defaults.object(forKey: "menu_show_quick_row") != nil ? defaults.bool(forKey: "menu_show_quick_row") : true
            self.menuShowDesktopSite = defaults.object(forKey: "menu_show_desktop_site") != nil ? defaults.bool(forKey: "menu_show_desktop_site") : true
            self.menuShowAddBookmark = defaults.object(forKey: "menu_show_add_bookmark") != nil ? defaults.bool(forKey: "menu_show_add_bookmark") : true
            self.menuShowDownloadVideo = defaults.object(forKey: "menu_show_download_video") != nil ? defaults.bool(forKey: "menu_show_download_video") : true
            self.menuShowDarkReader = defaults.object(forKey: "menu_show_dark_reader") != nil ? defaults.bool(forKey: "menu_show_dark_reader") : true
            self.menuShowHideSearchBar = defaults.object(forKey: "menu_show_hide_search_bar") != nil ? defaults.bool(forKey: "menu_show_hide_search_bar") : true
        }
        
        // Load persistent image from Documents folder or UserDefaults
        self.wallpaperBase64 = BrowserViewModel.loadWallpaperImage()
        
        self.history = defaults.stringArray(forKey: "history") ?? []
        self.bookmarks = BrowserViewModel.loadSavedBookmarks()
        
        // Restore downloads
        loadDownloads()
        
        // Determine default starting URL based on homePageType setting
        let defaultStartUrl: String
        if self.homePageType == 1 && !self.customHomePageUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let t = self.customHomePageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
            defaultStartUrl = t.lowercased().hasPrefix("http") ? t : "https://\(t)"
        } else {
            defaultStartUrl = ""
        }
        
        // Restore tabs based on startup behavior
        if self.startupBehavior == 1 {
            // User selected: always open a clean new tab on launch
            let initialTab = TabItem(url: defaultStartUrl)
            tabs = [initialTab]
            activeTabId = initialTab.id
        } else {
            var restored = false
            // 1. Try restoring from Documents/svinota_tabs.json (atomic file persistence)
            if let fileUrl = BrowserViewModel.tabsFileUrl,
               let data = try? Data(contentsOf: fileUrl),
               let state = try? JSONDecoder().decode(SavedTabsState.self, from: data),
               !state.tabs.isEmpty {
                for item in state.tabs {
                    tabs.append(TabItem(id: item.id, url: item.url, title: item.title ?? ""))
                }
                if tabs.contains(where: { $0.id == state.activeTabId }) {
                    activeTabId = state.activeTabId
                } else {
                    activeTabId = tabs.first?.id ?? 0
                }
                restored = true
            }
            
            // 2. Fallback to UserDefaults
            if !restored {
                if let savedTabs = defaults.string(forKey: "opened_tabs_json"),
                   let data = savedTabs.data(using: .utf8),
                   let jsonArr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]], !jsonArr.isEmpty {
                    for item in jsonArr {
                        let id = (item["id"] as? NSNumber)?.int64Value ?? Int64(Date().timeIntervalSince1970 * 1000)
                        let url = item["url"] as? String ?? ""
                        tabs.append(TabItem(id: id, url: url))
                    }
                }
                
                if tabs.isEmpty {
                    let initialTab = TabItem(url: defaultStartUrl)
                    tabs.append(initialTab)
                    activeTabId = initialTab.id
                } else {
                    let savedActiveId = defaults.object(forKey: "active_tab_id") as? NSNumber
                    if let saved = savedActiveId?.int64Value, tabs.contains(where: { $0.id == saved }) {
                        activeTabId = saved
                    } else {
                        activeTabId = tabs.first?.id ?? 0
                    }
                }
            }
        }
        
        inputUrl = activeTab?.url ?? ""
        setupKeyboardObservers()
        setupLifecycleObservers()
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification))
            .sink { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
                
                let screenHeight = UIScreen.main.bounds.height
                let isHiding = endFrame.origin.y >= screenHeight
                let newHeight: CGFloat = isHiding ? 0 : max(0, endFrame.height)
                
                let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
                withAnimation(.easeOut(duration: duration)) {
                    self.keyboardHeight = newHeight
                }
            }
            .store(in: &keyboardCancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] notification in
                guard let self = self else { return }
                let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
                withAnimation(.easeOut(duration: duration)) {
                    self.keyboardHeight = 0
                }
            }
            .store(in: &keyboardCancellables)
    }
    
    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.saveTabsState()
            self?.saveSettings()
        }
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.saveTabsState()
            self?.saveSettings()
        }
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            self?.saveTabsState()
            self?.saveSettings()
        }
    }
    
    // File-based Wallpaper image storage to ensure it never gets lost on app restart
    private static var wallpaperFileUrl: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("wallpaper_custom.jpg")
    }
    
    private func saveWallpaperImage(_ base64: String?) {
        guard let base64 = base64, let data = Data(base64Encoded: base64) else {
            if let url = BrowserViewModel.wallpaperFileUrl {
                try? FileManager.default.removeItem(at: url)
            }
            UserDefaults.standard.removeObject(forKey: "wp_base64")
            UserDefaults.standard.synchronize()
            return
        }
        
        if let url = BrowserViewModel.wallpaperFileUrl {
            try? data.write(to: url)
        }
        UserDefaults.standard.set(base64, forKey: "wp_base64")
        UserDefaults.standard.synchronize()
    }
    
    private static func loadWallpaperImage() -> String? {
        if let url = wallpaperFileUrl, let data = try? Data(contentsOf: url) {
            return data.base64EncodedString()
        }
        return UserDefaults.standard.string(forKey: "wp_base64")
    }
    
    func saveTabsState() {
        // 1. Sync live webView URL into tab models
        for tab in tabs {
            if let liveUrl = tab.webView?.url?.absoluteString,
               !liveUrl.isEmpty,
               !liveUrl.starts(with: "about:"),
               !liveUrl.starts(with: "data:") {
                tab.url = liveUrl
            }
        }
        
        // 2. Write to Documents/svinota_tabs.json atomically
        let savedList = tabs.map { SavedTab(id: $0.id, url: $0.url, title: $0.title) }
        let state = SavedTabsState(activeTabId: activeTabId, tabs: savedList)
        if let data = try? JSONEncoder().encode(state), let fileUrl = BrowserViewModel.tabsFileUrl {
            try? data.write(to: fileUrl, options: .atomic)
        }
        
        // 3. Write to UserDefaults as backup
        var arr: [[String: Any]] = []
        for tab in tabs {
            arr.append([
                "id": NSNumber(value: tab.id),
                "url": tab.url
            ])
        }
        if let data = try? JSONSerialization.data(withJSONObject: arr),
           let jsonString = String(data: data, encoding: .utf8) {
            UserDefaults.standard.set(jsonString, forKey: "opened_tabs_json")
        }
        UserDefaults.standard.set(NSNumber(value: activeTabId), forKey: "active_tab_id")
        UserDefaults.standard.synchronize()
    }
    
    func addNewTab(url: String = "") {
        let targetUrl = url.isEmpty ? effectiveStartPageUrl : url
        let newTab = TabItem(url: targetUrl)
        tabs.append(newTab)
        activeTabId = newTab.id
        inputUrl = targetUrl
        activeSiteThemeColor = nil
        saveTabsState()
        if !targetUrl.isEmpty {
            addToHistory(url: targetUrl)
        }
    }
    
    func closeTab(id: Int64) {
        if tabs.count > 1 {
            if activeTabId == id {
                let remaining = tabs.filter { $0.id != id }
                activeTabId = remaining.last?.id ?? 0
                inputUrl = activeTab?.url ?? ""
                activeSiteThemeColor = activeTab?.siteThemeColor
            }
            tabs.removeAll { $0.id == id }
        } else {
            let startUrl = effectiveStartPageUrl
            activeTab?.url = startUrl
            activeTab?.favicon = nil
            activeTab?.siteThemeColor = nil
            inputUrl = startUrl
            activeSiteThemeColor = nil
            if !startUrl.isEmpty, let active = activeTab, let webView = active.webView, let url = URL(string: startUrl) {
                var request = URLRequest(url: url)
                if let ua = effectiveUserAgent(for: active) {
                    request.setValue(ua, forHTTPHeaderField: "User-Agent")
                }
                webView.load(request)
            }
        }
        saveTabsState()
    }
    
    func closeAllTabs() {
        let startUrl = effectiveStartPageUrl
        let n = TabItem(url: startUrl)
        tabs = [n]
        activeTabId = n.id
        inputUrl = startUrl
        activeSiteThemeColor = nil
        saveTabsState()
        if !startUrl.isEmpty {
            addToHistory(url: startUrl)
        }
    }
    
    func switchTab(id: Int64) {
        activeTabId = id
        inputUrl = activeTab?.url ?? ""
        activeSiteThemeColor = activeTab?.siteThemeColor
        saveTabsState()
    }
    
    func navigate(to rawInput: String) {
        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let urlRegex = "^(https?://)?([\\w-]+\\.)+[\\w-]{2,}(/.*)?$"
        let isUrl = trimmed.range(of: urlRegex, options: .regularExpression) != nil && !trimmed.contains(" ")
        
        let targetUrl: String
        if isUrl {
            targetUrl = trimmed.lowercased().hasPrefix("http") ? trimmed : "https://\(trimmed)"
        } else {
            targetUrl = "\(searchEngine)\(trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed)"
        }
        
        activeTab?.url = targetUrl
        inputUrl = targetUrl
        saveTabsState()
        addToHistory(url: targetUrl)
        
        // Explicitly load URL in WKWebView if active
        if let webView = activeTab?.webView, let url = URL(string: targetUrl) {
            var request = URLRequest(url: url)
            if activeTab?.isDesktopMode == true {
                request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
            }
            webView.load(request)
        }
    }
    
    func addToHistory(url: String) {
        guard !url.isEmpty, !url.starts(with: "about:"), !url.starts(with: "data:") else { return }
        var current = history.filter { $0 != url }
        current.append(url)
        if current.count > 50 {
            current = Array(current.suffix(50))
        }
        history = current
        UserDefaults.standard.set(history, forKey: "history")
        UserDefaults.standard.synchronize()
    }
    
    func deleteHistoryItem(_ url: String) {
        history.removeAll { $0 == url }
        UserDefaults.standard.set(history, forKey: "history")
        UserDefaults.standard.synchronize()
    }
    
    private static var bookmarksFileUrl: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("svinota_bookmarks.json")
    }
    
    func saveBookmarks() {
        UserDefaults.standard.set(bookmarks, forKey: "bookmarks")
        UserDefaults.standard.synchronize()
        if let url = BrowserViewModel.bookmarksFileUrl, let data = try? JSONEncoder().encode(bookmarks) {
            try? data.write(to: url, options: .atomic)
        }
    }
    
    static func loadSavedBookmarks() -> [String] {
        if let url = BrowserViewModel.bookmarksFileUrl,
           let data = try? Data(contentsOf: url),
           let list = try? JSONDecoder().decode([String].self, from: data) {
            return list
        }
        return UserDefaults.standard.stringArray(forKey: "bookmarks") ?? []
    }
    
    func addBookmark(name: String, url: String) {
        let trimmedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUrl.isEmpty else { return }
        let formatted = (trimmedUrl.lowercased().hasPrefix("http://") || trimmedUrl.lowercased().hasPrefix("https://")) ? trimmedUrl : "https://\(trimmedUrl)"
        var title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty {
            title = URL(string: formatted)?.host ?? formatted
        }
        let composite = "\(title)|||\(formatted)"
        bookmarks.removeAll { $0 == composite }
        bookmarks.append(composite)
        saveBookmarks()
    }
    
    func deleteBookmark(_ item: String) {
        bookmarks.removeAll { $0 == item }
        saveBookmarks()
    }
    
    // yt-dlp Video Downloader
    func downloadCurrentPageVideo(completion: @escaping (Bool, String) -> Void) {
        guard let active = activeTab, !active.url.isEmpty else {
            completion(false, "Откройте страницу с видео")
            return
        }
        VideoDownloadService.shared.downloadVideo(
            from: active.url,
            pageTitle: active.title.isEmpty ? active.url : active.title,
            webView: active.webView,
            viewModel: self,
            completion: completion
        )
    }
    
    // MARK: - In-App Downloads
    private static var downloadsFileUrl: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("svinota_downloads.json")
    }
    
    func saveDownloads() {
        if let data = try? JSONEncoder().encode(downloads) {
            UserDefaults.standard.set(data, forKey: "browser_downloads")
            UserDefaults.standard.synchronize()
            if let url = BrowserViewModel.downloadsFileUrl {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
    
    func loadDownloads() {
        if let url = BrowserViewModel.downloadsFileUrl,
           let data = try? Data(contentsOf: url),
           let saved = try? JSONDecoder().decode([DownloadItem].self, from: data) {
            self.downloads = saved.map { var it = $0; it.isDownloading = false; return it }
        } else if let data = UserDefaults.standard.data(forKey: "browser_downloads"),
                  let saved = try? JSONDecoder().decode([DownloadItem].self, from: data) {
            self.downloads = saved.map { var it = $0; it.isDownloading = false; return it }
        }
    }
    
    func addDownload(filename: String, url: String, localPath: String? = nil, size: String = "") {
        let item = DownloadItem(filename: filename, url: url, localPath: localPath, dateAdded: Date(), fileSize: size)
        DispatchQueue.main.async {
            self.downloads.insert(item, at: 0)
            self.saveDownloads()
        }
    }
    
    func removeDownload(id: UUID) {
        if let item = downloads.first(where: { $0.id == id }), let localPath = item.localPath {
            try? FileManager.default.removeItem(atPath: localPath)
        }
        downloads.removeAll { $0.id == id }
        saveDownloads()
    }
    
    func clearDownloads() {
        for item in downloads {
            if let localPath = item.localPath {
                try? FileManager.default.removeItem(atPath: localPath)
            }
        }
        downloads.removeAll()
        saveDownloads()
    }
}
