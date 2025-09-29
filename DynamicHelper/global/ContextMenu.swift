import SwiftUI
import AppKit

/// 選單項目結構
struct AppKitMenuOption<Value: Hashable>: Hashable {
    let title: String
    let systemImage: String
    let value: Value
}

/// SwiftUI 修飾器：右鍵彈出 AppKit NSMenu
struct AppKitMenuArea<Value: Hashable>: NSViewRepresentable {
    @Binding var selection: Value
    let options: [AppKitMenuOption<Value>]

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        v.addGestureRecognizer(NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.showMenu(_:))))
        context.coordinator.options = options
        return v
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.selection = $selection
        context.coordinator.options = options
    }

    class Coordinator: NSObject {
        var selection: Binding<Value>
        var options: [AppKitMenuOption<Value>] = []

        init(selection: Binding<Value>) {
            self.selection = selection
        }

        @objc func showMenu(_ sender: NSClickGestureRecognizer) {
            guard sender.buttonMask == 0x2 else { return } // 只響應右鍵
            let menu = NSMenu()

            for opt in options {
                let item = NSMenuItem(
                    title: opt.title,
                    action: #selector(selectItem(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = opt.value
                item.image = NSImage(systemSymbolName: opt.systemImage, accessibilityDescription: nil)
                item.state = (opt.value == selection.wrappedValue) ? .on : .off // ✅ 左邊勾勾
                menu.addItem(item)
            }

            let location = sender.location(in: sender.view)
            menu.popUp(positioning: nil, at: location, in: sender.view)
        }

        @objc func selectItem(_ sender: NSMenuItem) {
            if let v = sender.representedObject as? Value {
                selection.wrappedValue = v
            }
        }
    }
}

extension View {
    func appKitContextMenu<Value: Hashable>(
        selection: Binding<Value>,
        options: [AppKitMenuOption<Value>]
    ) -> some View {
        self.background(AppKitMenuArea(selection: selection, options: options))
    }
}
