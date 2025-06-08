//
//  FileProcess.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/23/25.
//
import AppKit
import QuickLookThumbnailing

import UniformTypeIdentifiers

func generateThumbnail(for url: URL, size: CGSize) -> NSImage? {
    let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: NSScreen.main?.backingScaleFactor ?? 2.0, representationTypes: .all)

    var image: NSImage?

    let semaphore = DispatchSemaphore(value: 0)

    QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { (thumbnail, error) in
        if let cgImage = thumbnail?.cgImage {
            image = NSImage(cgImage: cgImage, size: size)
        }
        semaphore.signal()
    }

    _ = semaphore.wait(timeout: .now() + 1)

    return image
}

func loadUncroppedImage(for url: URL, size: CGSize) -> NSImage? {
    guard let image = NSImage(contentsOf: url) else { return nil }
    image.size = size
    return image
}

struct FileEntry: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    var icon: NSImage {
        let ext = url.pathExtension.lowercased()
        let isImage = ["png", "jpg", "jpeg", "heic", "bmp", "gif", "tiff"].contains(ext)
        
        if isImage, let fullImage = loadUncroppedImage(for: url, size: NSSize(width: 64, height: 64)) {
            return fullImage
        } else if let thumbnail = generateThumbnail(for: url, size: NSSize(width: 64, height: 64)) {
            return thumbnail
        } else {
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            icon.size = NSSize(width: 64, height: 64)
            return icon
        }
    }
//    var isSelected: Bool = false
}

class FileStorage: ObservableObject {
    @Published var Files: [FileEntry] = []
//    
//    func compactMap()->[FileEntry]{
//        var compacted:[FileEntry]=[]
//        for i in Files{
//            if i.isSelected{
//                compacted += [i]
//            }
//        }
//        return compacted
//    }
}

func handleDrop(providers: [NSItemProvider]) -> Bool {
    if AirDropViewSpace.frame.contains(getMousePoint()) {
        return handleAirDrop(providers: providers)
    }

    var found = false

    for provider in providers {
        if provider.hasItemConformingToTypeIdentifier("public.file-url") {
            found = true
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                DispatchQueue.main.async {
                    if let data = item as? Data,
                       let url = NSURL(absoluteURLWithDataRepresentation: data, relativeTo: nil) as URL? {
                        appendFileEntry(from: url)
                    } else if let url = item as? URL {
                        appendFileEntry(from: url)
                    }
                }
            }
        }
    }

    return found
}


func handleAirDrop(providers: [NSItemProvider]) -> Bool{
    var fileURLs: [URL] = []

        let group = DispatchGroup()

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                group.enter()
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                    if let data = item as? Data,
                       let url = NSURL(absoluteURLWithDataRepresentation: data, relativeTo: nil) as URL? {
                        fileURLs.append(url)
                    } else if let url = item as? URL {
                        fileURLs.append(url)
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            if !fileURLs.isEmpty {
                sendFilesViaAirDrop(fileURLs)
            }
        }

        return true
}


func sendFilesViaAirDrop(_ urls: [URL]) {
    if let service = NSSharingService(named: .sendViaAirDrop) {
        service.perform(withItems: urls)
    } else {
        print("❌ 無法啟用 AirDrop 傳送")
    }
}

func appendFileEntry(from url: URL) {
    let entry = FileEntry(url: url)
    if !fileStorage.Files.contains(entry) {
        fileStorage.Files.append(entry)
        print(url.hasDirectoryPath ? "📁 新增資料夾：\(url.lastPathComponent)" : "📄 新增檔案：\(url.lastPathComponent)")
    }
}


func createTemporaryCopy(of url: URL) -> URL? {
    let tmpFolder = URL(fileURLWithPath: NSTemporaryDirectory())
    let tmpURL = tmpFolder.appendingPathComponent(UUID().uuidString).appendingPathExtension(url.pathExtension)
    
    do {
        try FileManager.default.copyItem(at: url, to: tmpURL)
        try FileManager.default.removeItem(at: url) // 刪掉原始檔案
        
        // 延遲 60 秒後自動刪除
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            do {
                try FileManager.default.removeItem(at: tmpURL)
                print("🗑 自動刪除暫存檔案：\(tmpURL.lastPathComponent)")
            } catch {
                print("⚠️ 刪除暫存檔案失敗：\(error)")
            }
        }
        return tmpURL
    } catch {
        print("❌ 搬移至暫存失敗：\(error)")
        return nil
    }
}



func createUnifiedItemProvider(for fileURL: URL) -> NSItemProvider {
    let provider = NSItemProvider()
    let filenameWithoutExtension = fileURL.deletingPathExtension().lastPathComponent
    let filename = fileURL.lastPathComponent
    
    // ✅ 設定建議檔名
    provider.suggestedName = filename

    // ✅ 提供 public.file-url 給 Finder 和網頁
    provider.registerFileRepresentation(forTypeIdentifier: "public.file-url", fileOptions: [], visibility: .all) { completion in
        completion(fileURL, true, nil)
        return nil
    }

    // ✅ 額外加上 public.data（有些網頁會讀這個）
    provider.registerDataRepresentation(forTypeIdentifier: "public.data", visibility: .all) { completion in
        do {
            let data = try Data(contentsOf: fileURL)
            completion(data, nil)
        } catch {
            completion(nil, error)
        }
        return nil
    }

    // ✅ 提供 public.url 也可以幫助部分網站識別
    provider.registerItem(forTypeIdentifier: "public.url", loadHandler: { completion, _, _ in
        completion?(fileURL as NSURL, nil)
    })

    // ✅ 也提供 filename 本身的資料（可選）
    provider.registerItem(forTypeIdentifier: "public.text", loadHandler: { completion, _, _ in
        completion?(filename as NSString, nil)
    })

    return provider
}
