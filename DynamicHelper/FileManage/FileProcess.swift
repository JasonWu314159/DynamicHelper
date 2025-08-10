//
//  FileProcess.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/23/25.
//
import AppKit
import QuickLookThumbnailing

import UniformTypeIdentifiers



var fileStorage:FileStorage = FileStorage()

class FileStorage: ObservableObject {
//    static let shared = FileStorage()
    
    static let mainDir = "CopiedItems"
    static var storageFolder: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDataDirectory = baseURL
            .appendingPathComponent("DynamicHelper")
            .appendingPathComponent(Self.mainDir)
        return appDataDirectory
    }
    
    struct FileEntry: Identifiable, Equatable {
        let id = UUID()
        let RealUrl: URL
        let fileName: String
        
        var isClicked: Bool = false
        
        var icon: NSImage = NSImage()
        

        var storageURL: URL {
            return FileStorage.storageFolder.appendingPathComponent(fileName)
        }
        
        init(url: URL) {
//            assert(!Thread.isMainThread)
            
            self.RealUrl = url
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
                print("can't copyItem from \(url) to \(storageURL)")
            }
            print("storageURL:\(storageURL)")
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
    var lastScrollPos: CGFloat = 0
    
    init(){
//        appendFileEntry
    }
    
    func handleDrop(providers: [NSItemProvider] , airDropViewSpace:ViewSpace) -> Bool {
        if airDropViewSpace.frame.contains(getMousePoint()) {
            return AirDropFunc.handleAirDrop(providers: providers)
        }
        
        var found = false
        
        for provider in providers {
            print("🔍 Registered type identifiers: \(provider.registeredTypeIdentifiers)")
            if provider.hasItemConformingToTypeIdentifier("public.rtf"){
                
            }
            else if provider.hasItemConformingToTypeIdentifier("public.html"){
                
            }
            else if provider.hasItemConformingToTypeIdentifier("public.item") {
                print("haha")
                found = true
                provider.loadItem(forTypeIdentifier: "public.item", options: nil) { (item, error) in
                    DispatchQueue.main.async {
                        if let data = item as? Data,
                           let url = NSURL(absoluteURLWithDataRepresentation: data, relativeTo: nil) as URL? {
                            self.appendFileEntry(from: url)
                        } else if let url = item as? URL {
                            self.appendFileEntry(from: url)
                            print("is URL")
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
            if url.path.hasPrefix(FileStorage.storageFolder.resolvingSymlinksInPath().path){return}
            if self.FileisExist(url:url){return}
            DispatchQueue.main.async {
                if !fileStorage.Files.contains(entry) {
                    fileStorage.Files.append(entry)
                    print(url.hasDirectoryPath ? "📁 新增資料夾：\(url.lastPathComponent)" : "📄 新增檔案：\(url.lastPathComponent)")
                }
            }
        }
    }
    
    
    func FileisExist(url:URL)->Bool{
        var isExist:Bool = false
        for file in self.Files{
            if file.RealUrl == url{
                isExist = true
                return isExist
            }
        }
        return isExist
    }
    
    static func createUnifiedItemProvider(for srcURL: URL) -> NSItemProvider {
        print("srcURL \(srcURL)")
        let provider = NSItemProvider()
        
        
        provider.suggestedName = srcURL.lastPathComponent
        
//        let fileUTI = UTType(filenameExtension: srcURL.pathExtension) ?? .data
//        let delegate = FilePromiseWriter(srcURL: srcURL)
//        let promise = NSFilePromiseProvider(fileType: fileUTI.identifier, delegate: delegate)
//        provider.registerObject(promise as! NSItemProviderWriting, visibility: .all)
        
        // ---- A) file-url / url ----
        // 讓收件端可以以 URL 方式取用
        provider.registerObject(srcURL as NSURL, visibility: .all)
        
        // ---- B) data ----
        // 有些 App 直接要位元組資料
        if let data = try? Data(contentsOf: srcURL) {
            provider.registerDataRepresentation(forTypeIdentifier: UTType.data.identifier, visibility: .all) { completion in
                completion(data, nil)
                return nil
            }
            
            // ---- C) image（若為影像檔）----
            if let type = UTType(filenameExtension: srcURL.pathExtension),
               type.conforms(to: .image) {
                // 儘量維持原格式（例如 heic/png/jpeg）
                let typeID = type.identifier
                provider.registerDataRepresentation(forTypeIdentifier: typeID, visibility: .all) { completion in
                    completion(data, nil)
                    return nil
                }
            }
        }
        
        // ---- D) file representation（promised file）----
        // 允許對方直接向你「索取一個臨時檔」，系統會在需要時呼叫 loadHandler
        // 用 .data 作為最泛型別；若知道更精確的 UTI 可改成它（如 .image/.pdf）
        let promisedType = (UTType(filenameExtension: srcURL.pathExtension) ?? .data).identifier
        provider.registerFileRepresentation(forTypeIdentifier: promisedType,
                                            fileOptions: [],
                                            visibility: .all) { completion in
            
            let tmp = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension(srcURL.pathExtension.isEmpty ? "bin" : srcURL.pathExtension)
            do {
                try FileManager.default.copyItem(at: srcURL, to: tmp)
                // isInPlace=false 表示給的是「副本」
                completion(tmp, false, nil)
            } catch {
                completion(nil, false, error)
            }
            return nil
        }
        print(provider)
        return provider
    }

}

class AirDropFunc{
    
    static func handleAirDrop(providers: [NSItemProvider]) -> Bool{
        var fileURLs: [URL] = []
        
        let group = DispatchGroup()
        
        for provider in providers {
            print("🔍 Registered type identifiers: \(provider.registeredTypeIdentifiers)")
            if provider.hasItemConformingToTypeIdentifier("public.item") {
                group.enter()
                provider.loadItem(forTypeIdentifier: "public.item", options: nil) { (item, error) in
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




