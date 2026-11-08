import Foundation
import SwiftUI
import WebKit

// MARK: - Tab Model
class TabItem: ObservableObject, Identifiable {
    let id: Int64
    @Published var url: String
    @Published var title: String
    @Published var favicon: UIImage?
    @Published var isDesktopMode: Bool
    @Published var isLoading: Bool
    @Published var canGoBack: Bool
    @Published var canGoForward: Bool
    @Published var siteThemeColor: Color? = nil
    
    // Reference to WKWebView instance for tab state persistence
    var webView: WKWebView?
    
    init(
        id: Int64 = Int64(Date().timeIntervalSince1970 * 1000) + Int64.random(in: 0...999),
        url: String = "",
        title: String = "",
        favicon: UIImage? = nil,
        isDesktopMode: Bool = false,
        isLoading: Bool = false,
        canGoBack: Bool = false,
        canGoForward: Bool = false
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.favicon = favicon
        self.isDesktopMode = isDesktopMode
        self.isLoading = isLoading
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
    }
}

// MARK: - Bookmark Model
struct BookmarkItem: Identifiable, Codable, Equatable {
    var id: String { compositeValue }
    let name: String
    let url: String
    
    var compositeValue: String {
        return "\(name)||| \(url)"
    }
    
    static func from(composite: String) -> BookmarkItem {
        let parts = composite.components(separatedBy: "|||")
        let name = parts.first?.trimmingCharacters(in: .whitespaces) ?? ""
        let url = (parts.count > 1 ? parts[1] : composite).trimmingCharacters(in: .whitespaces)
        return BookmarkItem(name: name, url: url)
    }
}
