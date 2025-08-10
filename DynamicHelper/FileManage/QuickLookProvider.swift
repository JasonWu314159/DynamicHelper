//
//  QuickLookProvider.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/8/9.
//

import AppKit
import QuickLookUI

final class QuickLookProvider: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    var items: [URL] = []

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int { items.count }
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem {
        return items[index] as NSURL
    }
}


class MainWindowController: NSWindowController {
    let qlProvider = QuickLookProvider()

    override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool { true }

    override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
        panel.dataSource = qlProvider
        panel.delegate = qlProvider
    }

    override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
        panel.dataSource = nil
        panel.delegate = nil
    }

    func toggleQuickLook(urls: [URL]) {
        qlProvider.items = urls
        if let panel = QLPreviewPanel.shared() {
            if panel.isVisible {
                panel.orderOut(nil)
            } else {
                // 把控制權交給當前 first responder（就是這個 window controller）
                self.window?.makeFirstResponder(self)
                panel.makeKeyAndOrderFront(nil)
            }
        }
    }
}
