//
//  RightClickEvent.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/5/1.
//

import SwiftUI
import AppKit

private struct RightClickModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        RightClickableWrapper(action: action) {
            content
        }
    }
}

extension View {
    func onRightClick(_ action: @escaping () -> Void) -> some View {
        self.modifier(RightClickModifier(action: action))
    }
}


struct RightClickableWrapper<Content: View>: NSViewRepresentable {
    let action: () -> Void
    let content: () -> Content

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    func makeNSView(context: Context) -> NSHostingView<Content> {
        let view = NSHostingView(rootView: content())

        let recognizer = NSClickGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.rightClick(_:))
        )
        recognizer.buttonMask = 0x2 // 右鍵
        view.addGestureRecognizer(recognizer)

        return view
    }

    func updateNSView(_ nsView: NSHostingView<Content>, context: Context) {
        nsView.rootView = content()
    }

    class Coordinator: NSObject {
        let action: () -> Void
        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func rightClick(_ sender: NSClickGestureRecognizer) {
            action()
        }
    }
}
