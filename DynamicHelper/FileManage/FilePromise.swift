//
//  FilePromise.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/8/9.
//

import AppKit
import UniformTypeIdentifiers


// File Promise 寫檔委派：僅在這裡寫入 Safari 指定的 url
final class FilePromiseWriter: NSObject, NSFilePromiseProviderDelegate {
    private let srcURL: URL
    private let fileType: UTType
    private let fileName: String

    init(srcURL: URL) {
        self.srcURL = srcURL
        self.fileType = UTType(filenameExtension: srcURL.pathExtension) ?? .data
        self.fileName = srcURL.lastPathComponent
        super.init()
    }

    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider,
                             fileNameForType fileType: String) -> String {
        return fileName // 必須含副檔名
    }

    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider,
                             writePromiseTo url: URL,
                             completionHandler: @escaping (Error?) -> Void) {
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            do {
                try FileManager.default.copyItem(at: srcURL, to: url)
                completionHandler(nil)
            } catch {
                if let data = try? Data(contentsOf: srcURL) {
                    try data.write(to: url, options: .atomic)
                    completionHandler(nil)
                } else {
                    completionHandler(error)
                }
            }
        } catch {
            completionHandler(error)
        }
    }

    func operationQueue(for filePromiseProvider: NSFilePromiseProvider) -> OperationQueue {
        OperationQueue()
    }
}


