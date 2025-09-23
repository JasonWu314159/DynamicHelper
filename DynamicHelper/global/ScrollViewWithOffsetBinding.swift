//
//  ScrollViewWithOffsetBinding.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/4/30.
//

import SwiftUI
import AppKit

struct ScrollViewWithOffsetBinding<Content: View>: NSViewRepresentable {
    @Binding var offset: CGFloat
    @Binding var AnimateTime: CGFloat?
    let scrollWay: Axis
    var content: () -> Content
    
    var onScrollEnded: (() -> Void)? = nil
    
    init(offsetX: Binding<CGFloat>, AnimateTime: Binding<CGFloat?>? = nil, onScrollEnded: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) {
        self._offset = offsetX
        self.scrollWay = .horizontal
        self.content = content
        self._AnimateTime = AnimateTime ?? .constant(nil)
        self.onScrollEnded = onScrollEnded
    }
    
    init(offsetY: Binding<CGFloat>, AnimateTime: Binding<CGFloat?>? = nil, onScrollEnded: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) {
        self._offset = offsetY
        self.scrollWay = .vertical
        self.content = content
        self._AnimateTime = AnimateTime ?? .constant(nil)
        self.onScrollEnded = onScrollEnded
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = TrackingScrollView()
        
        scrollView.drawsBackground = false
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        if(scrollWay == .horizontal){
            scrollView.verticalScrollElasticity = .none
        }else{
            scrollView.horizontalScrollElasticity = .none
        }
        
//        let hosting = NSHostingView(rootView: content())
//        hosting.translatesAutoresizingMaskIntoConstraints = true
//        let clip = scrollView.contentView
//        hosting.frame = NSRect(origin: .zero, size: clip.bounds.size)
//        if scrollWay == .horizontal {
//            hosting.autoresizingMask = [.height]   // 交叉軸跟 clip；滾動軸可自由延伸
//        } else {
//            hosting.autoresizingMask = [.width]
//        }
//        scrollView.documentView = hosting
        
        let documentView = NSHostingView(rootView: content())
        documentView.translatesAutoresizingMaskIntoConstraints = true
        
        scrollView.documentView = documentView
        
        
//         Auto Layout
        if(scrollWay == .horizontal){
            NSLayoutConstraint.activate([
                documentView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
                documentView.bottomAnchor.constraint(equalTo: scrollView.contentView.bottomAnchor),
                documentView.heightAnchor.constraint(equalTo: scrollView.contentView.heightAnchor)
            ])
        }else{
            NSLayoutConstraint.activate([
                documentView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
                documentView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
                documentView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),
            ])
        }
        
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.boundsDidChange(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
        
        context.coordinator.scrollView = scrollView
        
        scrollView.onScrollGestureEnded = {
//            print(1)
            context.coordinator.parent.onScrollEnded?()
        }
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let currentOffset = if scrollWay == .horizontal {
            scrollView.contentView.bounds.origin.x
        }else{
            scrollView.contentView.bounds.origin.y
        }
        
        // ✅ 維持滾動位置
        if abs(currentOffset - offset) > 1 {
            if scrollWay == .horizontal {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = AnimateTime ?? 0
                    scrollView.contentView.animator().setBoundsOrigin(NSPoint(x: offset, y: 0))
                }
            } else if scrollWay == .vertical {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = AnimateTime ?? 0
                    scrollView.contentView.animator().setBoundsOrigin(NSPoint(x: 0, y: offset))
                }
            }
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }
    }
    
    
    class Coordinator: NSObject {
        var parent: ScrollViewWithOffsetBinding<Content>
        weak var scrollView: NSScrollView?
        private var scrollEndTimer: Timer?
        
        init(_ parent: ScrollViewWithOffsetBinding<Content>) {
            self.parent = parent
        }
        
        @objc func boundsDidChange(_ notification: Notification) {
            guard let scrollView = scrollView else { return }
            
            let newOffset = if parent.scrollWay == .horizontal {
                scrollView.contentView.bounds.origin.x
            } else {
                scrollView.contentView.bounds.origin.y
            }
            
            // 更新綁定值
            if abs(parent.offset - newOffset) > 1 {
                DispatchQueue.main.async {
                    self.parent.offset = newOffset
                }
            }
        }
    }
}


class TrackingScrollView: NSScrollView {
    private var scrollEndTimer: Timer?
    private var lastScrollEventTime: Date = .now
    private(set) var isUserScrolling = false
    var onScrollGestureEnded: (() -> Void)? = nil

    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)

        // 手指實際在觸控板上滑動
        if event.phase == .began || event.phase == .changed {
            isUserScrolling = true
            lastScrollEventTime = Date()
            scrollEndTimer?.invalidate()
        }else

        // ✅ 這裡才表示使用者手已抬起
        if event.phase == .ended || event.momentumPhase == .ended {
            isUserScrolling = false
            didFinishScrollGesture()
        }else{
            
            // 萬一慣性滾動沒 phase 結束也保底加 timer
            scrollEndTimer?.invalidate()
        }
        scrollEndTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.isUserScrolling {
                self.isUserScrolling = false
                self.didFinishScrollGesture()
            }
        }
    }
    func didFinishScrollGesture() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.onScrollGestureEnded?()
        }
    }
}
