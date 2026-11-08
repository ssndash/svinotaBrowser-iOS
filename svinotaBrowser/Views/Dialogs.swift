import SwiftUI

struct ColorPickerDialog: View {
    @ObservedObject var viewModel: BrowserViewModel
    @Binding var isPresented: Bool
    
    let colorsPreset: [(String, Color)] = [
        ("#F44336", Color(hex: "#F44336")),
        ("#E91E63", Color(hex: "#E91E63")),
        ("#9C27B0", Color(hex: "#9C27B0")),
        ("#673AB7", Color(hex: "#673AB7")),
        ("#3F51B5", Color(hex: "#3F51B5")),
        ("#2196F3", Color(hex: "#2196F3")),
        ("#00BCD4", Color(hex: "#00BCD4")),
        ("#009688", Color(hex: "#009688")),
        ("#4CAF50", Color(hex: "#4CAF50")),
        ("#8BC34A", Color(hex: "#8BC34A")),
        ("#CDDC39", Color(hex: "#CDDC39")),
        ("#FFEB3B", Color(hex: "#FFEB3B")),
        ("#FFC107", Color(hex: "#FFC107")),
        ("#FF9800", Color(hex: "#FF9800")),
        ("#FF5722", Color(hex: "#FF5722")),
        ("#607D8B", Color(hex: "#607D8B"))
    ]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 16) {
                Text(t("Choose Background Color", "Выберите цвет фона", viewModel.appLang))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(viewModel.colors.onSurface)
                
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(colorsPreset, id: \.0) { hex, color in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color)
                            .frame(width: 44, height: 44)
                            .onTapGesture {
                                viewModel.wallpaperType = "color"
                                viewModel.wallpaperColorHex = hex
                                viewModel.saveSettings()
                                isPresented = false
                            }
                    }
                }
                .padding(.vertical, 8)
                
                HStack {
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Text(t("Cancel", "Отмена", viewModel.appLang))
                            .foregroundColor(viewModel.colors.primary)
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
            }
            .padding(20)
            .background(viewModel.colors.surface)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.2), radius: 10)
            .padding(.horizontal, 32)
        }
    }
}

struct AddBookmarkDialog: View {
    @ObservedObject var viewModel: BrowserViewModel
    @Binding var isPresented: Bool
    
    @State private var name: String = ""
    @State private var url: String = ""
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 16) {
                Text(t("Add Bookmark", "Новая закладка", viewModel.appLang))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(viewModel.colors.onSurface)
                
                VStack(spacing: 12) {
                    TextField(t("Name", "Название", viewModel.appLang), text: $name)
                        .padding(10)
                        .background(viewModel.colors.surfaceVariant)
                        .cornerRadius(8)
                    
                    TextField("URL", text: $url)
                        .padding(10)
                        .background(viewModel.colors.surfaceVariant)
                        .cornerRadius(8)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                HStack(spacing: 16) {
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Text(t("Cancel", "Отмена", viewModel.appLang))
                            .foregroundColor(viewModel.colors.primary)
                    }
                    
                    Button(action: {
                        if !url.trimmingCharacters(in: .whitespaces).isEmpty {
                            viewModel.addBookmark(name: name, url: url)
                            isPresented = false
                        }
                    }) {
                        Text("OK")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(viewModel.colors.primary)
                    }
                }
            }
            .padding(20)
            .background(viewModel.colors.surface)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.2), radius: 10)
            .padding(.horizontal, 32)
        }
        .onAppear {
            if let active = viewModel.activeTab, !active.url.isEmpty {
                self.url = active.url
                self.name = active.title.isEmpty ? (URL(string: active.url)?.host ?? active.url) : active.title
            }
        }
    }
}

struct CustomEngineDialog: View {
    @ObservedObject var viewModel: BrowserViewModel
    @Binding var isPresented: Bool
    
    @State private var name: String = ""
    @State private var url: String = ""
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 16) {
                Text(t("Custom Search Engine", "Свой поисковик", viewModel.appLang))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(viewModel.colors.onSurface)
                
                VStack(spacing: 12) {
                    TextField(t("Name (e.g. Brave)", "Название (например: Brave)", viewModel.appLang), text: $name)
                        .padding(10)
                        .background(viewModel.colors.surfaceVariant)
                        .cornerRadius(8)
                    
                    TextField(t("URL (e.g. https://search.brave.com/search?q=)", "URL с ?q= (например: https://.../?q=)", viewModel.appLang), text: $url)
                        .padding(10)
                        .background(viewModel.colors.surfaceVariant)
                        .cornerRadius(8)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                HStack(spacing: 16) {
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Text(t("Cancel", "Отмена", viewModel.appLang))
                            .foregroundColor(viewModel.colors.primary)
                    }
                    
                    Button(action: {
                        let trimmedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedUrl.isEmpty {
                            let formattedUrl = (trimmedUrl.hasPrefix("http://") || trimmedUrl.hasPrefix("https://")) ? trimmedUrl : "https://\(trimmedUrl)"
                            let engineTitle = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Custom" : name.trimmingCharacters(in: .whitespacesAndNewlines)
                            viewModel.customSearchEngineName = engineTitle
                            viewModel.customSearchUrl = formattedUrl
                            viewModel.searchEngine = formattedUrl
                            viewModel.saveSettings()
                            isPresented = false
                        }
                    }) {
                        Text("OK")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(viewModel.colors.primary)
                    }
                }
            }
            .padding(20)
            .background(viewModel.colors.surface)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.2), radius: 10)
            .padding(.horizontal, 32)
        }
        .onAppear {
            if !viewModel.customSearchUrl.isEmpty && viewModel.customSearchUrl != "https://" {
                self.url = viewModel.customSearchUrl
                self.name = viewModel.customSearchEngineName
            } else {
                self.url = "https://"
                self.name = ""
            }
        }
    }
}
