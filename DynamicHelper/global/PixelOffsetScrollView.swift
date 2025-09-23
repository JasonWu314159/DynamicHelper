//
//  PixelOffsetScrollView.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/9/23.
//
import SwiftUI
import AppKit

struct HiddenIndicatorHScroll<Content: View>: NSViewRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        // 關閉捲軸顯示，但仍可用觸控板/滑鼠手勢滾動
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.scrollerStyle = .overlay

        // 內容寬度大於可視範圍時才能水平滾動
        let hosting = NSHostingView(rootView: content)
        hosting.translatesAutoresizingMaskIntoConstraints = false

        let docView = NSView()
        docView.translatesAutoresizingMaskIntoConstraints = false
        docView.addSubview(hosting)

        // Auto Layout：讓 hosting 填滿 docView 高度，寬度由內容自然撐開
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: docView.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: docView.bottomAnchor),
            hosting.leadingAnchor.constraint(equalTo: docView.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: docView.trailingAnchor),

            // 允許水平方向比可視範圍更寬
            docView.heightAnchor.constraint(equalTo: hosting.heightAnchor)
        ])

        scrollView.documentView = docView
        scrollView.hasHorizontalRuler = false
        scrollView.hasVerticalRuler = false
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.allowsMagnification = false
        scrollView.horizontalScrollElasticity = .automatic
        scrollView.verticalScrollElasticity = .none

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let hosting = (nsView.documentView?.subviews.first { $0 is NSHostingView<Content> }) as? NSHostingView<Content> {
            hosting.rootView = content
        }
    }
}
