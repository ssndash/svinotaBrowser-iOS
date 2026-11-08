import Foundation
import WebKit

class VideoDownloadService {
    static let shared = VideoDownloadService()
    
    // Public reliable endpoints compatible with yt-dlp / cobalt protocol
    private let extractionEndpoints = [
        "https://api.cobalt.tools/api/json",
        "https://cobalt-api.kwiatekm.pl/api/json",
        "https://co.wuk.sh/api/json"
    ]
    
    func downloadVideo(from urlString: String, pageTitle: String? = nil, webView: WKWebView? = nil, viewModel: BrowserViewModel, completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: urlString), !urlString.isEmpty else {
            completion(false, "Некорректный адрес страницы")
            return
        }
        
        let host = url.host?.lowercased() ?? ""
        let cleanTitle = sanitizeFilename(pageTitle ?? url.lastPathComponent)
        
        // 1. If page contains a direct video link (mp4, webm, mov, m4v)
        let pathExt = url.pathExtension.lowercased()
        if ["mp4", "webm", "mov", "m4v", "mp3"].contains(pathExt) {
            downloadDirectMedia(url: url, filename: "\(cleanTitle).\(pathExt)", viewModel: viewModel, completion: completion)
            return
        }
        
        // 2. Reddit specific direct video extraction
        if host.contains("reddit.com") {
            tryRedditExtraction(url: url, title: cleanTitle, viewModel: viewModel) { success, msg in
                if success {
                    completion(true, msg)
                } else {
                    self.tryExtractorAPIs(pageUrl: urlString, title: cleanTitle, viewModel: viewModel, completion: completion)
                }
            }
            return
        }
        
        // 3. Try standard yt-dlp API instances (YouTube, Twitter/X, Reddit, TikTok, Instagram)
        tryExtractorAPIs(pageUrl: urlString, title: cleanTitle, viewModel: viewModel) { success, msg in
            if success {
                completion(true, msg)
            } else if let webView = webView {
                // 4. Fallback: Sniff <video> tag src directly from WebKit DOM
                self.sniffDOMVideo(webView: webView, title: cleanTitle, viewModel: viewModel, completion: completion)
            } else {
                completion(false, msg)
            }
        }
    }
    
    private func tryExtractorAPIs(pageUrl: String, title: String, viewModel: BrowserViewModel, endpointIndex: Int = 0, completion: @escaping (Bool, String) -> Void) {
        guard endpointIndex < extractionEndpoints.count else {
            completion(false, "Не удалось получить видеопоток через yt-dlp")
            return
        }
        
        guard let endpoint = URL(string: extractionEndpoints[endpointIndex]) else {
            tryExtractorAPIs(pageUrl: pageUrl, title: title, viewModel: viewModel, endpointIndex: endpointIndex + 1, completion: completion)
            return
        }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 12
        
        let body: [String: Any] = [
            "url": pageUrl,
            "vQuality": "720",
            "isAudioOnly": false
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                // Cobalt protocol: "url" or "stream"
                if let streamUrlStr = (json["url"] as? String) ?? (json["stream"] as? String),
                   let streamUrl = URL(string: streamUrlStr) {
                    self.downloadDirectMedia(url: streamUrl, filename: "\(title).mp4", viewModel: viewModel, completion: completion)
                    return
                }
            }
            
            // Try next endpoint on failure
            DispatchQueue.main.async {
                self.tryExtractorAPIs(pageUrl: pageUrl, title: title, viewModel: viewModel, endpointIndex: endpointIndex + 1, completion: completion)
            }
        }.resume()
    }
    
    private func tryRedditExtraction(url: URL, title: String, viewModel: BrowserViewModel, completion: @escaping (Bool, String) -> Void) {
        var jsonUrlStr = url.absoluteString
        if jsonUrlStr.hasSuffix("/") {
            jsonUrlStr = String(jsonUrlStr.dropLast())
        }
        jsonUrlStr += ".json"
        
        guard let jsonUrl = URL(string: jsonUrlStr) else {
            completion(false, "Invalid Reddit URL")
            return
        }
        
        var request = URLRequest(url: jsonUrl)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let first = arr.first,
                  let dataDict = first["data"] as? [String: Any],
                  let children = dataDict["children"] as? [[String: Any]],
                  let post = children.first?["data"] as? [String: Any],
                  let media = post["secure_media"] as? [String: Any] ?? post["media"] as? [String: Any],
                  let redditVideo = media["reddit_video"] as? [String: Any],
                  let fallbackUrlStr = redditVideo["fallback_url"] as? String,
                  let fallbackUrl = URL(string: fallbackUrlStr) else {
                completion(false, "Reddit video not found")
                return
            }
            
            self.downloadDirectMedia(url: fallbackUrl, filename: "\(title).mp4", viewModel: viewModel, completion: completion)
        }.resume()
    }
    
    private func sniffDOMVideo(webView: WKWebView, title: String, viewModel: BrowserViewModel, completion: @escaping (Bool, String) -> Void) {
        let js = """
        (function() {
            var vids = Array.from(document.querySelectorAll('video')).map(v => v.currentSrc || v.src).filter(Boolean);
            if (vids.length > 0) return vids[0];
            var sources = Array.from(document.querySelectorAll('video source')).map(s => s.src).filter(Boolean);
            if (sources.length > 0) return sources[0];
            return null;
        })();
        """
        webView.evaluateJavaScript(js) { result, _ in
            if let mediaUrlStr = result as? String, let mediaUrl = URL(string: mediaUrlStr) {
                let ext = mediaUrl.pathExtension.isEmpty ? "mp4" : mediaUrl.pathExtension
                self.downloadDirectMedia(url: mediaUrl, filename: "\(title).\(ext)", viewModel: viewModel, completion: completion)
            } else {
                completion(false, "На этой странице не обнаружено видеопотоков")
            }
        }
    }
    
    private func downloadDirectMedia(url: URL, filename: String, viewModel: BrowserViewModel, completion: @escaping (Bool, String) -> Void) {
        let finalFilename = filename.isEmpty ? "video_\(Int(Date().timeIntervalSince1970)).mp4" : filename
        DownloadManager.shared.startDownload(url: url, suggestedFilename: finalFilename, viewModel: viewModel, completion: completion)
    }
    
    private func sanitizeFilename(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "\\/:*?\"<>|")
        var clean = name.components(separatedBy: invalid).joined(separator: "_")
        clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.count > 50 {
            clean = String(clean.prefix(50))
        }
        return clean.isEmpty ? "video" : clean
    }
}
