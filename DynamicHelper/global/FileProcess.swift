//
//  FileProcess.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/23/25.
//
import AppKit
import QuickLookThumbnailing

import UniformTypeIdentifiers


class FileStorage: ObservableObject {
//    static let shared = FileStorage()
    
    struct FileEntry: Identifiable, Equatable {
        let id = UUID()
        let url: URL
        let fileName: String
        
        var icon: NSImage = NSImage()
        
        static let mainDir = "CopiedItems"

        var storageURL: URL {
            let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appDataDirectory = baseURL
                .appendingPathComponent("DynamicHelper")
                .appendingPathComponent(Self.mainDir)

            return appDataDirectory.appendingPathComponent(fileName)
        }
        
        init(url: URL) {
//            assert(!Thread.isMainThread)
            
            self.url = url
            self.fileName = url.lastPathComponent

            do {
                try FileManager.default.createDirectory(
                at: storageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true)
            }catch{
                print("can't create directory")
            }
            do{
                try FileManager.default.copyItem(at: url, to: storageURL)
            }catch{
                print("can't copyItem")
            }
            print(storageURL)
            icon = FileStorage.FileEntry.getIcon(url: storageURL)
        }
        
        static func getIcon(url u:URL) -> NSImage {
            let ext = u.pathExtension.lowercased()
            let isImage = ["png", "jpg", "jpeg", "heic", "bmp", "gif", "tiff"].contains(ext)
            
            if isImage, let fullImage = loadUncroppedImage(for: u, size: NSSize(width: 64, height: 64)) {
                return fullImage
            } else if let thumbnail = generateThumbnail(for: u, size: NSSize(width: 64, height: 64)) {
                return thumbnail
            } else {
                let icon = NSWorkspace.shared.icon(forFile: u.path)
                icon.size = NSSize(width: 64, height: 64)
                return icon
            }
        }
        
        
        static func generateThumbnail(for url: URL, size: CGSize) -> NSImage? {
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

        static func loadUncroppedImage(for url: URL, size: CGSize) -> NSImage? {
            guard let image = NSImage(contentsOf: url) else { return nil }
            image.size = size
            return image
        }
        
    //    var isSelected: Bool = false
    }
    
    
    @Published var Files: [FileEntry] = []
    
    init(){
//        appendFileEntry
    }
    
    func handleDrop(providers: [NSItemProvider] , airDropViewSpace:ViewSpace) -> Bool {
        if airDropViewSpace.frame.contains(getMousePoint()) {
            return AirDropFunc.handleAirDrop(providers: providers)
        }
        
        var found = false
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                found = true
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                    DispatchQueue.main.async {
                        if let data = item as? Data,
                           let url = NSURL(absoluteURLWithDataRepresentation: data, relativeTo: nil) as URL? {
                            self.appendFileEntry(from: url)
                        } else if let url = item as? URL {
                            self.appendFileEntry(from: url)
                        }
                    }
                }
            }
        }
        
        return found
    }
    
    
    func appendFileEntry(from url: URL) {
        DispatchQueue.global().async {
            let entry = FileEntry(url: url)
            DispatchQueue.main.async {
                if !fileStorage.Files.contains(entry) {
                    fileStorage.Files.append(entry)
                    print(url.hasDirectoryPath ? "📁 新增資料夾：\(url.lastPathComponent)" : "📄 新增檔案：\(url.lastPathComponent)")
                }
            }
        }
    }

}

class AirDropFunc{
    
    static func handleAirDrop(providers: [NSItemProvider]) -> Bool{
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
    
    static func sendFilesViaAirDrop(_ urls: [URL]) {
        if let service = NSSharingService(named: .sendViaAirDrop) {
            service.perform(withItems: urls)
        } else {
            print("❌ 無法啟用 AirDrop 傳送")
        }
    }
    
}




