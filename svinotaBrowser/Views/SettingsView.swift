import SwiftUI

enum SettingsSubpage: String, Identifiable {
    case search
    case appearance
    case privacy
    case about
    
    var id: String { rawValue }
}

struct SettingsView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var activeSubpage: SettingsSubpage? = nil
    @State private var showCustomEngineDialog: Bool = false
    @State private var showCustomUADialog: Bool = false
    @State private var showClearDataAlert: Bool = false
    @State private var tempCustomUA: String = ""
    
    let searchEngines = [
        ("DuckDuckGo", "https://duckduckgo.com/?q="),
        ("Google", "https://google.com/search?q="),
        ("Yandex", "https://yandex.ru/search/?text="),
        ("Perplexity", "https://www.perplexity.ai/?q=")
    ]
    
    var body: some View {
        ZStack {
            viewModel.colors.surface.ignoresSafeArea()
            
            if let subpage = activeSubpage {
                subpageView(for: subpage)
            } else {
                rootSettingsView
            }
            
            // Custom Search Engine Dialog
            if showCustomEngineDialog {
                CustomEngineDialog(viewModel: viewModel, isPresented: $showCustomEngineDialog)
                    .zIndex(20)
            }
        }
        .sheet(isPresented: $showCustomUADialog) {
            NavigationView {
                Form {
                    Section(header: Text("User-Agent")) {
                        TextEditor(text: $tempCustomUA)
                            .frame(height: 120)
                            .font(.system(size: 13, design: .monospaced))
                    }
                }
                .navigationTitle(t("Custom User-Agent", "Свой User-Agent", viewModel.appLang))
                .navigationBarItems(
                    leading: Button(t("Cancel", "Отмена", viewModel.appLang)) {
                        showCustomUADialog = false
                    },
                    trailing: Button(t("Save", "Сохранить", viewModel.appLang)) {
                        let trimmed = tempCustomUA.trimmingCharacters(in: .whitespacesAndNewlines)
                        viewModel.customUserAgent = trimmed
                        viewModel.userAgentPreset = 3
                        viewModel.saveSettings()
                        showCustomUADialog = false
                    }
                )
            }
        }
        .alert(isPresented: $showClearDataAlert) {
            Alert(
                title: Text(t("Clear Browsing Data", "Очистить данные", viewModel.appLang)),
                message: Text(t("Are you sure you want to clear browsing history and downloads?", "Вы уверены, что хотите удалить историю и загрузки?", viewModel.appLang)),
                primaryButton: .destructive(Text(t("Clear", "Очистить", viewModel.appLang))) {
                    viewModel.history.removeAll()
                    UserDefaults.standard.removeObject(forKey: "history")
                    viewModel.clearDownloads()
                    viewModel.saveDownloads()
                    UserDefaults.standard.synchronize()
                },
                secondaryButton: .cancel(Text(t("Cancel", "Отмена", viewModel.appLang)))
            )
        }
        .onDisappear {
            viewModel.saveSettings()
        }
    }
    
    // MARK: - Root Settings Page (Divided into sections with chevrons)
    private var rootSettingsView: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 16) {
                Button(action: {
                    viewModel.saveSettings()
                    viewModel.showFullSettings = false
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(viewModel.colors.onSurface)
                }
                
                Text(t("Settings", "Настройки", viewModel.appLang))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(viewModel.colors.onSurface)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 14)
            .background(viewModel.colors.surface)
            
            ScrollView {
                VStack(spacing: 12) {
                    Spacer().frame(height: 6)
                    
                    // 1) Search Engine
                    settingsNavigationRow(
                        icon: "magnifyingglass",
                        title: t("Search Engine", "Поисковая система", viewModel.appLang),
                        subtitle: currentEngineName
                    ) {
                        withAnimation { activeSubpage = .search }
                    }
                    
                    // 2) Appearance
                    settingsNavigationRow(
                        icon: "paintbrush.fill",
                        title: t("Appearance", "Внешний вид", viewModel.appLang),
                        subtitle: currentAppearanceSummary
                    ) {
                        withAnimation { activeSubpage = .appearance }
                    }
                    
                    // 3) Privacy & Security
                    settingsNavigationRow(
                        icon: "shield.lefthalf.filled",
                        title: t("Privacy & Security", "Конфиденциальность и безопасность", viewModel.appLang),
                        subtitle: t("Ad Blocker, Data cleanup", "Блокировщик рекламы, очистка данных", viewModel.appLang)
                    ) {
                        withAnimation { activeSubpage = .privacy }
                    }
                    
                    // 4) About
                    settingsNavigationRow(
                        icon: "info.circle.fill",
                        title: t("About", "О программе", viewModel.appLang),
                        subtitle: "svinotaBrowser 1.0 • SSNDash Team"
                    ) {
                        withAnimation { activeSubpage = .about }
                    }
                    
                    Spacer().frame(height: 30)
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private func settingsNavigationRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.colors.primaryContainer)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.colors.primary)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(viewModel.colors.onSurface)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(viewModel.colors.onSurfaceVariant)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(viewModel.colors.onSurfaceVariant.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(viewModel.colors.surfaceVariant)
            .cornerRadius(18)
        }
    }
    
    private var currentEngineName: String {
        for (name, url) in searchEngines {
            if viewModel.searchEngine == url { return name }
        }
        if viewModel.searchEngine == viewModel.customSearchUrl {
            return viewModel.customSearchEngineName.isEmpty ? "Custom" : viewModel.customSearchEngineName
        }
        return "DuckDuckGo"
    }
    
    private var currentAppearanceSummary: String {
        let themeName: String
        switch viewModel.themeMode {
        case .light: themeName = t("Light", "Светлая", viewModel.appLang)
        case .dark: themeName = t("Dark", "Тёмная", viewModel.appLang)
        case .amoled: themeName = "AMOLED"
        }
        let pos = viewModel.barPosition == 1 ? t("Top bar", "Сверху", viewModel.appLang) : t("Bottom bar", "Снизу", viewModel.appLang)
        return "\(themeName) • \(pos)"
    }
    
    // MARK: - Subpage Switcher
    @ViewBuilder
    private func subpageView(for subpage: SettingsSubpage) -> some View {
        switch subpage {
        case .search:
            searchEngineSubpage
        case .appearance:
            appearanceSubpage
        case .privacy:
            privacySubpage
        case .about:
            aboutSubpage
        }
    }
    
    // MARK: - 1) Search Engine Subpage
    private var searchEngineSubpage: some View {
        VStack(spacing: 0) {
            subpageHeader(title: t("Search Engine", "Поисковая система", viewModel.appLang)) {
                Button(action: {
                    showCustomEngineDialog = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(viewModel.colors.primary)
                        .font(.system(size: 20, weight: .bold))
                }
            }
            
            ScrollView {
                VStack(spacing: 8) {
                    Spacer().frame(height: 8)
                    
                    ForEach(searchEngines, id: \.1) { (name, url) in
                        Button(action: {
                            viewModel.searchEngine = url
                            viewModel.saveSettings()
                        }) {
                            HStack(spacing: 14) {
                                Image(systemName: viewModel.searchEngine == url ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(viewModel.colors.primary)
                                    .font(.system(size: 20))
                                
                                Text(name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(viewModel.colors.onSurface)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(viewModel.colors.surfaceVariant)
                            .cornerRadius(14)
                        }
                    }
                    
                    if viewModel.customSearchUrl != "https://" && !viewModel.customSearchUrl.isEmpty {
                        HStack(spacing: 14) {
                            Button(action: {
                                viewModel.searchEngine = viewModel.customSearchUrl
                                viewModel.saveSettings()
                            }) {
                                HStack(spacing: 14) {
                                    Image(systemName: viewModel.searchEngine == viewModel.customSearchUrl ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(viewModel.colors.primary)
                                        .font(.system(size: 20))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(viewModel.customSearchEngineName.isEmpty ? t("Custom", "Свой", viewModel.appLang) : viewModel.customSearchEngineName)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(viewModel.colors.onSurface)
                                        Text(viewModel.customSearchUrl)
                                            .font(.system(size: 11))
                                            .foregroundColor(viewModel.colors.onSurfaceVariant)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                }
                            }
                            
                            Button(action: {
                                viewModel.customSearchUrl = "https://"
                                viewModel.customSearchEngineName = ""
                                if viewModel.searchEngine == viewModel.customSearchUrl {
                                    viewModel.searchEngine = "https://duckduckgo.com/?q="
                                }
                                viewModel.saveSettings()
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16))
                                    .foregroundColor(viewModel.colors.error)
                                    .padding(8)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(viewModel.colors.surfaceVariant)
                        .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - 2) Appearance Subpage
    private var appearanceSubpage: some View {
        VStack(spacing: 0) {
            subpageHeader(title: t("Appearance", "Внешний вид", viewModel.appLang))
            
            ScrollView {
                VStack(spacing: 16) {
                    Spacer().frame(height: 6)
                    
                    // A) Navigation Bar Position
                    appearanceCard(title: t("Navigation bar position", "Положение навигационной панели", viewModel.appLang)) {
                        HStack(spacing: 24) {
                            radioButton(
                                isSelected: viewModel.barPosition == 0,
                                label: t("Bottom", "Снизу", viewModel.appLang)
                            ) { viewModel.barPosition = 0 }
                            
                            radioButton(
                                isSelected: viewModel.barPosition == 1,
                                label: t("Top", "Сверху", viewModel.appLang)
                            ) { viewModel.barPosition = 1 }
                        }
                    }
                    
                    // B) Navigation Bar Elements Layout
                    appearanceCard(title: t("Navigation bar layout", "Расположение кнопки меню", viewModel.appLang)) {
                        HStack(spacing: 24) {
                            radioButton(
                                isSelected: viewModel.navBarLayout == 0,
                                label: t("Menu Right", "Справа (обычно)", viewModel.appLang)
                            ) { viewModel.navBarLayout = 0 }
                            
                            radioButton(
                                isSelected: viewModel.navBarLayout == 1,
                                label: t("Menu Left", "Слева", viewModel.appLang)
                            ) { viewModel.navBarLayout = 1 }
                        }
                    }
                    
                    // C) Search Bar Visibility
                    appearanceCard(title: t("Search Bar", "Строка поиска", viewModel.appLang)) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(t("Hide search bar", "Скрыть строку поиска", viewModel.appLang))
                                    .font(.system(size: 15))
                                    .foregroundColor(viewModel.colors.onSurface)
                                Spacer()
                                Toggle("", isOn: $viewModel.isSearchBarHidden)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: viewModel.colors.primary))
                            }
                            Text(t("Only the small circular menu button remains at the bottom", "Останется только маленькая кнопка меню", viewModel.appLang))
                                .font(.system(size: 11))
                                .foregroundColor(viewModel.colors.onSurfaceVariant)
                        }
                    }
                    
                    // D) Startup Behavior
                    appearanceCard(title: t("On startup", "При запуске браузера", viewModel.appLang)) {
                        HStack(spacing: 24) {
                            radioButton(
                                isSelected: viewModel.startupBehavior == 0,
                                label: t("Last page", "Последняя вкладка", viewModel.appLang)
                            ) { viewModel.startupBehavior = 0 }
                            
                            radioButton(
                                isSelected: viewModel.startupBehavior == 1,
                                label: t("New tab", "Новая вкладка", viewModel.appLang)
                            ) { viewModel.startupBehavior = 1 }
                        }
                    }
                    
                    // E) Start Page (Default Home vs Custom URL)
                    appearanceCard(title: t("Start page", "Стартовая страница", viewModel.appLang)) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 24) {
                                radioButton(
                                    isSelected: viewModel.homePageType == 0,
                                    label: t("Home page", "Главная страница", viewModel.appLang)
                                ) {
                                    viewModel.homePageType = 0
                                    viewModel.saveSettings()
                                }
                                
                                radioButton(
                                    isSelected: viewModel.homePageType == 1,
                                    label: t("Custom URL", "Свой адрес", viewModel.appLang)
                                ) {
                                    viewModel.homePageType = 1
                                    viewModel.saveSettings()
                                    if !viewModel.effectiveStartPageUrl.isEmpty && viewModel.activeTab?.url.isEmpty == true {
                                        viewModel.navigate(to: viewModel.effectiveStartPageUrl)
                                    }
                                }
                            }
                            
                            if viewModel.homePageType == 1 {
                                HStack(spacing: 8) {
                                    TextField(
                                        t("e.g. https://google.com", "например: google.com", viewModel.appLang),
                                        text: $viewModel.customHomePageUrl,
                                        onCommit: {
                                            viewModel.saveSettings()
                                            if viewModel.homePageType == 1 && viewModel.activeTab?.url.isEmpty == true {
                                                viewModel.navigate(to: viewModel.effectiveStartPageUrl)
                                            }
                                        }
                                    )
                                    .font(.system(size: 14))
                                    .padding(10)
                                    .background(viewModel.colors.surface)
                                    .cornerRadius(10)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    
                                    if !viewModel.customHomePageUrl.isEmpty {
                                        Button(action: {
                                            viewModel.saveSettings()
                                            if viewModel.activeTab?.url.isEmpty == true {
                                                viewModel.navigate(to: viewModel.effectiveStartPageUrl)
                                            }
                                        }) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(viewModel.colors.primary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // F) Theme Mode
                    appearanceCard(title: t("Theme", "Тема оформления", viewModel.appLang)) {
                        HStack(spacing: 20) {
                            radioButton(
                                isSelected: viewModel.themeMode == .light,
                                label: t("Light", "Светлая", viewModel.appLang)
                            ) { viewModel.themeMode = .light }
                            
                            radioButton(
                                isSelected: viewModel.themeMode == .dark,
                                label: t("Dark", "Тёмная", viewModel.appLang)
                            ) { viewModel.themeMode = .dark }
                            
                            radioButton(
                                isSelected: viewModel.themeMode == .amoled,
                                label: "AMOLED"
                            ) { viewModel.themeMode = .amoled }
                        }
                    }
                    
                    // G) User-Agent
                    appearanceCard(title: "User-Agent") {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 16) {
                                radioButton(isSelected: viewModel.userAgentPreset == 0, label: "Safari") {
                                    viewModel.userAgentPreset = 0
                                }
                                radioButton(isSelected: viewModel.userAgentPreset == 1, label: "Chrome") {
                                    viewModel.userAgentPreset = 1
                                }
                                radioButton(isSelected: viewModel.userAgentPreset == 2, label: "Android") {
                                    viewModel.userAgentPreset = 2
                                }
                                radioButton(isSelected: viewModel.userAgentPreset == 3, label: t("Custom", "Свой", viewModel.appLang)) {
                                    viewModel.userAgentPreset = 3
                                    if viewModel.customUserAgent.isEmpty {
                                        tempCustomUA = ""
                                        showCustomUADialog = true
                                    }
                                }
                            }
                            
                            if viewModel.userAgentPreset == 3 {
                                Button(action: {
                                    tempCustomUA = viewModel.customUserAgent
                                    showCustomUADialog = true
                                }) {
                                    HStack {
                                        Text(viewModel.customUserAgent.isEmpty ? t("Tap to enter User-Agent", "Нажмите для ввода User-Agent", viewModel.appLang) : viewModel.customUserAgent)
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(viewModel.colors.primary)
                                            .lineLimit(2)
                                        Spacer()
                                        Image(systemName: "pencil")
                                            .font(.system(size: 14))
                                            .foregroundColor(viewModel.colors.primary)
                                    }
                                    .padding(8)
                                    .background(viewModel.colors.surface)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // H) Language
                    appearanceCard(title: t("Language", "Язык интерфейса", viewModel.appLang)) {
                        HStack(spacing: 24) {
                            radioButton(
                                isSelected: viewModel.appLang == "ru",
                                label: "Русский"
                            ) { viewModel.appLang = "ru" }
                            
                            radioButton(
                                isSelected: viewModel.appLang == "en",
                                label: "English"
                            ) { viewModel.appLang = "en" }
                        }
                    }
                    
                    // I) Dark Reader (MANDATORY: PLACED DIRECTLY UNDER LANGUAGE)
                    appearanceCard(title: t("Dark Reader", "Dark Reader (Тёмная тема сайтов)", viewModel.appLang)) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(t("Force Dark Mode on Websites", "Принудительная тёмная тема для всех сайтов", viewModel.appLang))
                                    .font(.system(size: 14))
                                    .foregroundColor(viewModel.colors.onSurface)
                                Spacer()
                                Toggle("", isOn: $viewModel.isDarkReaderEnabled)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: viewModel.colors.primary))
                            }
                            Text(t("Smart inversion of web page colors for comfortable night reading", "Инвертирует цвета страниц для комфортного чтения ночью", viewModel.appLang))
                                .font(.system(size: 11))
                                .foregroundColor(viewModel.colors.onSurfaceVariant)
                        }
                    }
                    
                    // J) Menu Items Customization
                    appearanceCard(title: t("Menu customization", "Настройка пунктов меню", viewModel.appLang)) {
                        VStack(spacing: 12) {
                            toggleRow(
                                title: t("Quick actions (History, Bookmarks, Downloads)", "Быстрые кнопки (История, Закладки, Загрузки)", viewModel.appLang),
                                isOn: $viewModel.menuShowQuickRow
                            )
                            Divider()
                            toggleRow(
                                title: t("Desktop site", "Версия для ПК", viewModel.appLang),
                                isOn: $viewModel.menuShowDesktopSite
                            )
                            Divider()
                            toggleRow(
                                title: t("Add to Bookmarks", "Добавить в закладки", viewModel.appLang),
                                isOn: $viewModel.menuShowAddBookmark
                            )
                            Divider()
                            toggleRow(
                                title: t("Download Video (yt-dlp)", "Скачать видео (yt-dlp)", viewModel.appLang),
                                isOn: $viewModel.menuShowDownloadVideo
                            )
                            Divider()
                            toggleRow(
                                title: t("Dark Reader", "Dark Reader (Тёмная тема сайтов)", viewModel.appLang),
                                isOn: $viewModel.menuShowDarkReader
                            )
                            Divider()
                            toggleRow(
                                title: t("Hide/show search bar", "Скрыть/показать строку поиска", viewModel.appLang),
                                isOn: $viewModel.menuShowHideSearchBar
                            )
                        }
                    }
                    
                    Spacer().frame(height: 30)
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - 3) Privacy & Security Subpage
    private var privacySubpage: some View {
        VStack(spacing: 0) {
            subpageHeader(title: t("Privacy & Security", "Конфиденциальность и безопасность", viewModel.appLang))
            
            ScrollView {
                VStack(spacing: 16) {
                    Spacer().frame(height: 6)
                    
                    // Ad Blocker (Clean subtitle without adblock.turtlecute.org 100%)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(t("Ad Blocker", "Блокировщик рекламы", viewModel.appLang))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(viewModel.colors.onSurface)
                            Spacer()
                            Toggle("", isOn: $viewModel.isAdBlockerEnabled)
                                .labelsHidden()
                                .toggleStyle(SwitchToggleStyle(tint: viewModel.colors.primary))
                        }
                        
                        Text(t("Blocks ads, trackers, and analytics scripts", "Блокирует баннеры, трекеры и рекламные сети", viewModel.appLang))
                            .font(.system(size: 12))
                            .foregroundColor(viewModel.colors.onSurfaceVariant)
                    }
                    .padding(16)
                    .background(viewModel.colors.surfaceVariant)
                    .cornerRadius(16)
                    
                    // Clear Browsing Data
                    Button(action: {
                        showClearDataAlert = true
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(t("Clear browsing data", "Очистить историю и загрузки", viewModel.appLang))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(viewModel.colors.error)
                                Text(t("Deletes history and downloads list", "Удаляет историю посещений и список файлов", viewModel.appLang))
                                    .font(.system(size: 12))
                                    .foregroundColor(viewModel.colors.onSurfaceVariant)
                            }
                            Spacer()
                            Image(systemName: "trash.fill")
                                .font(.system(size: 18))
                                .foregroundColor(viewModel.colors.error)
                        }
                        .padding(16)
                        .background(viewModel.colors.surfaceVariant)
                        .cornerRadius(16)
                    }
                    
                    Spacer().frame(height: 30)
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - 4) About Subpage (No "Check for Updates" button)
    private var aboutSubpage: some View {
        VStack(spacing: 0) {
            subpageHeader(title: t("About", "О программе", viewModel.appLang))
            
            ScrollView {
                VStack(spacing: 18) {
                    Spacer().frame(height: 24)
                    
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 88, height: 88)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
                    
                    Text("svinotaBrowser")
                        .font(.custom("ComicNeue-Bold", size: 30))
                        .foregroundColor(viewModel.colors.onSurface)
                    
                    Text("\(t("Version", "Версия", viewModel.appLang)) 1.0")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(viewModel.colors.onSurfaceVariant)
                    
                    Spacer().frame(height: 10)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(t("Developer", "Разработчик", viewModel.appLang))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(viewModel.colors.primary)
                        
                        Text("SSNDash Team")
                            .font(.system(size: 15))
                            .foregroundColor(viewModel.colors.onSurface)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(viewModel.colors.surfaceVariant)
                    .cornerRadius(16)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(t("License", "Лицензия", viewModel.appLang))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(viewModel.colors.primary)
                        
                        Text(t(
                            "This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3.0.",
                            "Свободное программное обеспечение под лицензией GNU Affero General Public License v3.0.",
                            viewModel.appLang
                        ))
                        .font(.system(size: 13))
                        .foregroundColor(viewModel.colors.onSurfaceVariant)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(viewModel.colors.surfaceVariant)
                    .cornerRadius(16)
                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Reusable UI Helpers
    private func subpageHeader<Trailing: View>(title: String, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) -> some View {
        HStack(spacing: 14) {
            Button(action: {
                withAnimation {
                    activeSubpage = nil
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .semibold))
                    Text(t("Back", "Назад", viewModel.appLang))
                        .font(.system(size: 16))
                }
                .foregroundColor(viewModel.colors.primary)
            }
            
            Spacer()
            
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(viewModel.colors.onSurface)
                .lineLimit(1)
            
            Spacer()
            
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(viewModel.colors.surface)
    }
    
    private func appearanceCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(viewModel.colors.primary)
            
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(viewModel.colors.surfaceVariant)
        .cornerRadius(16)
    }
    
    private func radioButton(isSelected: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(viewModel.colors.primary)
                    .font(.system(size: 18))
                
                Text(label)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(viewModel.colors.onSurface)
            }
        }
    }
    
    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(viewModel.colors.onSurface)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: viewModel.colors.primary))
        }
    }
}
