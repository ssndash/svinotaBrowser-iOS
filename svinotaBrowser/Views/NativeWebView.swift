import SwiftUI
import WebKit

struct NativeWebView: UIViewRepresentable {
    @ObservedObject var tab: TabItem
    @ObservedObject var viewModel: BrowserViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        if let existing = tab.webView {
            existing.navigationDelegate = context.coordinator
            existing.uiDelegate = context.coordinator
            existing.scrollView.delegate = context.coordinator
            existing.scrollView.contentInsetAdjustmentBehavior = .never
            context.coordinator.setupObservations(for: existing)
            return existing
        }
        
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        
        if viewModel.isAdBlockerEnabled {
            let adScript = WKUserScript(
                source: AdBlockerService.shared.adBlockScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
            config.userContentController.addUserScript(adScript)
        }
        
        if viewModel.isDarkReaderEnabled {
            let darkScript = WKUserScript(
                source: AdBlockerService.shared.darkReaderScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
            config.userContentController.addUserScript(darkScript)
        }
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.scrollView.delegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = true
        webView.backgroundColor = .white
        
        let targetUA = viewModel.effectiveUserAgent(for: tab)
        webView.customUserAgent = targetUA
        
        context.coordinator.setupObservations(for: webView)
        
        tab.webView = webView
        
        if !tab.url.isEmpty, let url = URL(string: tab.url) {
            var request = URLRequest(url: url)
            if let ua = targetUA {
                request.setValue(ua, forHTTPHeaderField: "User-Agent")
            }
            webView.load(request)
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        tab.webView = uiView
        
        // Handle User-Agent updates dynamically
        let targetUA = viewModel.effectiveUserAgent(for: tab)
        if uiView.customUserAgent != targetUA {
            uiView.customUserAgent = targetUA
        }
        
        // If webView has no current URL and tab.url is not empty, load it
        if !tab.url.isEmpty, let targetUrl = URL(string: tab.url) {
            let currentUrlStr = uiView.url?.absoluteString ?? ""
            if currentUrlStr.isEmpty || currentUrlStr == "about:blank" {
                var request = URLRequest(url: targetUrl)
                if let ua = targetUA {
                    request.setValue(ua, forHTTPHeaderField: "User-Agent")
                }
                uiView.load(request)
            }
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate {
        var parent: NativeWebView
        var lastScrollY: CGFloat = 0
        var themeColorObservation: NSKeyValueObservation?
        var urlObservation: NSKeyValueObservation?
        
        init(_ parent: NativeWebView) {
            self.parent = parent
        }
        
        func setupObservations(for webView: WKWebView) {
            setupThemeColorObservation(for: webView)
            setupUrlObservation(for: webView)
        }
        
        func setupUrlObservation(for webView: WKWebView) {
            urlObservation = webView.observe(\.url, options: [.new]) { [weak self] wv, _ in
                guard let self = self else { return }
                if let newUrl = wv.url?.absoluteString,
                   !newUrl.isEmpty,
                   !newUrl.starts(with: "about:"),
                   !newUrl.starts(with: "data:") {
                    DispatchQueue.main.async {
                        self.parent.tab.url = newUrl
                        if self.parent.tab.id == self.parent.viewModel.activeTabId {
                            self.parent.viewModel.inputUrl = newUrl
                        }
                        self.parent.viewModel.saveTabsState()
                    }
                }
            }
        }
        
        func setupThemeColorObservation(for webView: WKWebView) {
            if #available(iOS 15.0, *) {
                themeColorObservation = webView.observe(\.themeColor, options: [.initial, .new]) { [weak self] wv, _ in
                    guard let self = self else { return }
                    if let uiColor = wv.themeColor {
                        let color = Color(uiColor)
                        DispatchQueue.main.async {
                            self.parent.tab.siteThemeColor = color
                            if self.parent.tab.id == self.parent.viewModel.activeTabId {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    self.parent.viewModel.activeSiteThemeColor = color
                                }
                            }
                        }
                    }
                }
            }
        }
        
        func extractSiteThemeColor(from webView: WKWebView) {
            if #available(iOS 15.0, *) {
                if let uiColor = webView.themeColor {
                    let color = Color(uiColor)
                    self.parent.tab.siteThemeColor = color
                    if self.parent.tab.id == self.parent.viewModel.activeTabId {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            self.parent.viewModel.activeSiteThemeColor = color
                        }
                    }
                    return
                }
            }
            
            let js = """
            (function() {
                var meta = document.querySelector('meta[name="theme-color"]');
                if (meta && meta.content) return meta.content;
                var header = document.querySelector('header, [role="banner"], nav, .header, #header');
                if (header) {
                    var hBg = window.getComputedStyle(header).backgroundColor;
                    if (hBg && hBg !== 'rgba(0, 0, 0, 0)' && hBg !== 'transparent') return hBg;
                }
                var bodyBg = window.getComputedStyle(document.body).backgroundColor;
                if (bodyBg && bodyBg !== 'rgba(0, 0, 0, 0)' && bodyBg !== 'transparent') return bodyBg;
                var docBg = window.getComputedStyle(document.documentElement).backgroundColor;
                if (docBg && docBg !== 'rgba(0, 0, 0, 0)' && docBg !== 'transparent') return docBg;
                return null;
            })();
            """
            webView.evaluateJavaScript(js) { [weak self] result, _ in
                guard let self = self, let colorStr = result as? String, !colorStr.isEmpty else { return }
                if let uiColor = UIColor.fromCSSColor(colorStr) {
                    let color = Color(uiColor)
                    DispatchQueue.main.async {
                        self.parent.tab.siteThemeColor = color
                        if self.parent.tab.id == self.parent.viewModel.activeTabId {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                self.parent.viewModel.activeSiteThemeColor = color
                            }
                        }
                    }
                }
            }
        }
        
        func handleFileDownload(url: URL, suggestedFilename: String? = nil) {
            DownloadManager.shared.startDownload(url: url, suggestedFilename: suggestedFilename, viewModel: parent.viewModel)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                if parent.viewModel.isAdBlockerEnabled && AdBlockerService.shared.isAdRequest(url: url) {
                    decisionHandler(.cancel)
                    return
                }
                
                let ext = url.pathExtension.lowercased()
                let downloadableExts = ["zip", "apk", "pdf", "dmg", "tar", "gz", "rar", "7z", "mp3", "mp4", "jpg", "jpeg", "png", "ipa", "deb"]
                if downloadableExts.contains(ext) {
                    handleFileDownload(url: url)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if let response = navigationResponse.response as? HTTPURLResponse,
               let disposition = response.allHeaderFields["Content-Disposition"] as? String,
               disposition.contains("attachment") {
                if let url = response.url {
                    let filename = response.suggestedFilename ?? "download"
                    handleFileDownload(url: url, suggestedFilename: filename)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.tab.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            DispatchQueue.main.async {
                if let urlString = webView.url?.absoluteString,
                   !urlString.starts(with: "about:"),
                   !urlString.starts(with: "data:") {
                    self.parent.tab.url = urlString
                    if self.parent.tab.id == self.parent.viewModel.activeTabId {
                        self.parent.viewModel.inputUrl = urlString
                    }
                    self.parent.viewModel.saveTabsState()
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.tab.isLoading = false
                self.parent.tab.canGoBack = webView.canGoBack
                self.parent.tab.canGoForward = webView.canGoForward
                
                if let urlString = webView.url?.absoluteString,
                   !urlString.starts(with: "about:"),
                   !urlString.starts(with: "data:") {
                    self.parent.tab.url = urlString
                    if self.parent.tab.id == self.parent.viewModel.activeTabId {
                        self.parent.viewModel.inputUrl = urlString
                    }
                    self.parent.viewModel.saveTabsState()
                    self.parent.viewModel.addToHistory(url: urlString)
                }
                
                // Fetch favicon
                if let host = webView.url?.host, let faviconUrl = URL(string: "https://\(host)/favicon.ico") {
                    URLSession.shared.dataTask(with: faviconUrl) { data, _, _ in
                        if let data = data, let img = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self.parent.tab.favicon = img
                            }
                        }
                    }.resume()
                }
                
                self.extractSiteThemeColor(from: webView)
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.tab.isLoading = false
                self.loadCustomErrorHtml(in: webView)
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.tab.isLoading = false
                self.loadCustomErrorHtml(in: webView)
            }
        }
        
        private func loadCustomErrorHtml(in webView: WKWebView) {
            let names = ["tvrshk", "KS51", "guganator3000", "Letexe", "michael dodo pizza", "Timofya453"]
            let randomName = names.randomElement() ?? "KS51"
            let lang = parent.viewModel.appLang
            let errorTitle = t("Error!", "Ошибка!", lang)
            let errorMsg = t("couldn't find this site.", "не смог найти этот сайт.", lang)
            let retryBtn = t("Try again", "Попробовать снова", lang)
            let isDark = parent.viewModel.themeMode.isDark
            let bgHex = isDark ? "#1C1C1E" : "#FFFFFF"
            let textHex = isDark ? "#FFFFFF" : "#000000"
            
            let html = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body {
                        background-color: \(bgHex);
                        color: \(textHex);
                        display: flex;
                        flex-direction: column;
                        align-items: center;
                        justify-content: center;
                        height: 100vh;
                        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                        text-align: center;
                        margin: 0;
                        padding: 20px;
                        box-sizing: border-box;
                    }
                    h1 { color: #0077ff; margin-bottom: 8px; font-size: 28px; }
                    p { font-size: 17px; margin-top: 0; }
                    button {
                        padding: 14px 28px;
                        border-radius: 25px;
                        border: none;
                        background: #0077ff;
                        color: white;
                        font-weight: bold;
                        font-size: 16px;
                        margin-top: 24px;
                        cursor: pointer;
                    }
                </style>
            </head>
            <body>
                <h1>\(errorTitle)</h1>
                <p>\(randomName) \(errorMsg)</p>
                <button onclick="location.reload()">\(retryBtn)</button>
            </body>
            </html>
            """
            webView.loadHTMLString(html, baseURL: nil)
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let y = scrollView.contentOffset.y
            let diff = y - lastScrollY
            
            // Only collapse when actively on a website
            guard parent.viewModel.activeTab?.url.isEmpty == false else {
                if parent.viewModel.isBarCollapsed {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        parent.viewModel.isBarCollapsed = false
                    }
                }
                return
            }
            
            // Ignore rubber-banding at extreme top/bottom
            if y <= 0 || y >= (scrollView.contentSize.height - scrollView.frame.height) {
                return
            }
            
            if diff > 8 && y > 30 {
                // Scrolling down -> collapse into small strip with address (no menu button)
                if !parent.viewModel.isBarCollapsed {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        parent.viewModel.isBarCollapsed = true
                    }
                }
            } else if diff < -8 {
                // Scrolling up -> expand back with smooth spring animation
                if parent.viewModel.isBarCollapsed {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        parent.viewModel.isBarCollapsed = false
                    }
                }
            }
            lastScrollY = y
        }
        
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            let alert = UIAlertController(title: webView.url?.host, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
            findTopViewController()?.present(alert, animated: true)
        }
        
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            let alert = UIAlertController(title: webView.url?.host, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
            findTopViewController()?.present(alert, animated: true)
        }
        
        private func findTopViewController() -> UIViewController? {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let root = scene.windows.first?.rootViewController else { return nil }
            var top = root
            while let presented = top.presentedViewController {
                top = presented
            }
            return top
        }
    }
}
