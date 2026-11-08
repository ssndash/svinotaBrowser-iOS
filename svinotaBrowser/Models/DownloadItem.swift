import Foundation
import Combine
import SwiftUI

struct DownloadItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let filename: String
    let url: String
    var localPath: String? = nil
    var dateAdded: Date = Date()
    var fileSize: String = ""
    var progress: Double = 1.0 // 0.0 to 1.0
    var isDownloading: Bool = false
    
    var fileURL: URL? {
        if let localPath = localPath {
            return URL(fileURLWithPath: localPath)
        }
        return nil
    }
}

struct ActiveDownloadToast: Identifiable, Equatable {
    var id: UUID = UUID()
    var filename: String
    var progress: Double = 0.05
    var bytesText: String = ""
    var isFinished: Bool = false
}

class DownloadManager: NSObject, URLSessionDownloadDelegate {
    static let shared = DownloadManager()
    
    private var session: URLSession!
    private var activeTasks: [Int: (item: DownloadItem, viewModel: BrowserViewModel, completion: ((Bool, String) -> Void)?)] = [:]
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
    }
    
    func startDownload(url: URL, suggestedFilename: String? = nil, viewModel: BrowserViewModel, completion: ((Bool, String) -> Void)? = nil) {
        let rawName = suggestedFilename ?? (url.lastPathComponent.isEmpty ? "download_\(Int(Date().timeIntervalSince1970))" : url.lastPathComponent)
        let filename = sanitizeFilename(rawName)
        
        let item = DownloadItem(
            filename: filename,
            url: url.absoluteString,
            dateAdded: Date(),
            fileSize: "0 MB",
            progress: 0.05,
            isDownloading: true
        )
        
        viewModel.downloads.removeAll { $0.filename == filename }
        viewModel.downloads.insert(item, at: 0)
        viewModel.saveDownloads()
        
        // Show floating HUD above nav bar
        viewModel.activeDownloadToast = ActiveDownloadToast(
            filename: filename,
            progress: 0.05,
            bytesText: "Начало загрузки...",
            isFinished: false
        )
        
        let task = session.downloadTask(with: url)
        activeTasks[task.taskIdentifier] = (item, viewModel, completion)
        task.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let entry = activeTasks[downloadTask.taskIdentifier] else { return }
        let progress = totalBytesExpectedToWrite > 0 ? max(0.05, min(1.0, Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))) : 0.5
        
        let writtenStr = ByteCountFormatter.string(fromByteCount: totalBytesWritten, countStyle: .file)
        let totalStr = totalBytesExpectedToWrite > 0 ? ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: .file) : ""
        let sizeText = totalStr.isEmpty ? writtenStr : "\(writtenStr) / \(totalStr)"
        
        DispatchQueue.main.async {
            if let idx = entry.viewModel.downloads.firstIndex(where: { $0.id == entry.item.id }) {
                entry.viewModel.downloads[idx].progress = progress
                entry.viewModel.downloads[idx].fileSize = sizeText
            }
            if entry.viewModel.activeDownloadToast?.filename == entry.item.filename {
                entry.viewModel.activeDownloadToast?.progress = progress
                entry.viewModel.activeDownloadToast?.bytesText = sizeText
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let entry = activeTasks[downloadTask.taskIdentifier] else { return }
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let downloadsFolder = docs.appendingPathComponent("Downloads")
        try? FileManager.default.createDirectory(at: downloadsFolder, withIntermediateDirectories: true)
        let destination = downloadsFolder.appendingPathComponent(entry.item.filename)
        
        try? FileManager.default.removeItem(at: destination)
        try? FileManager.default.moveItem(at: location, to: destination)
        
        var sizeText = ""
        if let attrs = try? FileManager.default.attributesOfItem(atPath: destination.path),
           let bytes = attrs[.size] as? Int64 {
            sizeText = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
        }
        
        DispatchQueue.main.async {
            if let idx = entry.viewModel.downloads.firstIndex(where: { $0.id == entry.item.id }) {
                entry.viewModel.downloads[idx].isDownloading = false
                entry.viewModel.downloads[idx].progress = 1.0
                entry.viewModel.downloads[idx].localPath = destination.path
                if !sizeText.isEmpty {
                    entry.viewModel.downloads[idx].fileSize = sizeText
                }
            }
            entry.viewModel.saveDownloads()
            
            // Mark toast finished
            entry.viewModel.activeDownloadToast?.isFinished = true
            entry.viewModel.activeDownloadToast?.progress = 1.0
            entry.viewModel.activeDownloadToast?.bytesText = sizeText
            
            // Auto-hide toast after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    if entry.viewModel.activeDownloadToast?.filename == entry.item.filename {
                        entry.viewModel.activeDownloadToast = nil
                    }
                }
            }
            
            entry.completion?(true, "Скачивание завершено: \(entry.item.filename)")
            self.activeTasks.removeValue(forKey: downloadTask.taskIdentifier)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error, let entry = activeTasks[task.taskIdentifier] else { return }
        DispatchQueue.main.async {
            if let idx = entry.viewModel.downloads.firstIndex(where: { $0.id == entry.item.id }) {
                entry.viewModel.downloads[idx].isDownloading = false
            }
            entry.viewModel.activeDownloadToast = nil
            entry.completion?(false, "Ошибка загрузки: \(error.localizedDescription)")
            self.activeTasks.removeValue(forKey: task.taskIdentifier)
        }
    }
    
    private func sanitizeFilename(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "\\/:*?\"<>|")
        var clean = name.components(separatedBy: invalid).joined(separator: "_")
        clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.count > 60 {
            clean = String(clean.prefix(60))
        }
        return clean.isEmpty ? "file_\(Int(Date().timeIntervalSince1970))" : clean
    }
}
