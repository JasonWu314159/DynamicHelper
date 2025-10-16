//
//  CopyBook.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/4/30.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers
import Inspect


class StringStorage: ObservableObject {
    
    static let shared = StringStorage()
    @Published var Item: [(String,Bool)] = []
    var lastScrollPosID:Int = 0
    var lastScrollPos:CGFloat = 0
    var containID = UUID()
    let objectWidth:CGFloat = 80
    
    struct TextEntry: Identifiable, Equatable {
        let id = UUID()
        let fileURL: URL // 儲存原始格式
        let typeIdentifier: String // e.g., public.rtf, public.html
        let plainText: String // 顯示用文字

        // 自動產生純文字
        init?(data: Data, typeIdentifier: String) {
            self.typeIdentifier = typeIdentifier

            let ext = UTType(typeIdentifier)?.preferredFilenameExtension ?? "txt"
            let tmpURL = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("TextStorage")
                .appendingPathComponent(UUID().uuidString + "." + ext)

            do {
                try FileManager.default.createDirectory(at: tmpURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try data.write(to: tmpURL)
                self.fileURL = tmpURL

                // 解析純文字
                if let attributed = try? NSAttributedString(data: data, options: [
                    .documentType: Self.documentType(for: typeIdentifier)
                ], documentAttributes: nil) {
                    self.plainText = attributed.string
                } else if let str = String(data: data, encoding: .utf8) {
                    self.plainText = str
                } else {
                    self.plainText = "[無法解讀內容]"
                }
            } catch {
                print("❌ 儲存 TextEntry 失敗：\(error)")
                return nil
            }
        }

        static func documentType(for type: String) -> NSAttributedString.DocumentType {
            switch type {
            case "public.rtf":
                return .rtf
            case "public.html":
                return .html
            default:
                return .plain
            }
        }
    }
}


struct CopyBookScroller: View {
    @State private var offsetX:CGFloat = 0
    @State private var maxWidth:CGFloat = 0
    @State private var lastItemCount: Int = 0
    var body: some View {
        ZStack() {
            
            CopyBook()
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            maxWidth = geo.size.width
                        }
                }
            )
            RoundedRectangle(cornerRadius: 5)
                .stroke(
                    Color(red: 0.5, green: 0.5, blue: 0.5),
                    lineWidth: 0
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(x:1.05, y:1.1)
        }
        .frame(height: 50,alignment: .leading)
        .frame(maxWidth: .infinity)
    }
    
    func offsetAnimation(_ to:CGFloat,duration:Double = 0.2){
        
        let stepTime = 0.01
        let d = (duration * 100).rounded() / 100
        let totalSteps = Int(d/stepTime)
        let deltha:CGFloat = to - offsetX
        let delthaEveryStep:CGFloat = deltha / CGFloat(totalSteps)
        for i in 0..<totalSteps{
            DispatchQueue.main.asyncAfter(deadline: .now() + stepTime*CGFloat(i)){
                offsetX += delthaEveryStep
                if offsetX < 0{offsetX=0;return}
            }
        }
    }
}

struct CopyBook: View {
    @ObservedObject var Strings:StringStorage = StringStorage.shared
    @State private var AddButtonIsHover:Bool = false
    var body: some View {
        HStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        Rectangle()
                            .frame(width: 1)
                            .frame(maxHeight: .infinity)
                            .foregroundStyle(.gray.opacity(0.5))
                        ForEach(Array(Strings.Item.enumerated()), id: \.offset) { index, item in
                            CopyBook_Previews(previews: item,id: index).id(index)
                            Rectangle()
                                .frame(width: 1)
                                .frame(maxHeight: .infinity)
                                .foregroundStyle(.gray.opacity(0.5))
                        }.id(Strings.containID)
                        
                        Image(systemName: "plus")
                            .id(Strings.Item.count*3)
                            .font(.system(size: 17))
                            .foregroundStyle(.white)
                            .frame(width: 35, height: 35)
                            .hoverPressEffect(CR: 35) {
                                StringStorage.shared.Item.append(("",false))
                                Strings.containID = UUID()
                            }
                            .onAppear(){
                                withAnimation {
                                    proxy.scrollTo(
                                        StringStorage.shared.lastScrollPosID, anchor: .center
                                    )
                                }
                            }
                    }
                }
                .inspect { (nsScrollView: NSScrollView) in
                    nsScrollView.hasHorizontalScroller = false
                    nsScrollView.hasVerticalScroller = false
                }
            }
        }
    }
}



struct CopyBook_Previews:View {
    @State private var previews:String
    private var id:Int
    private let objectWidth:CGFloat = StringStorage.shared.objectWidth
    @State private var isHovered:Bool = false
    @State private var offsetX:CGFloat = 0
    @State private var width:CGFloat = StringStorage.shared.objectWidth
    @State private var isAppear:Bool = false
    
    @State private var BackgroundColor:Color = .black

    
    init(previews: (String,Bool), id: Int) {
        _previews = State(initialValue: previews.0)
        isAppear = previews.1
        self.id = id
    }
    var body: some View {
        ZStack{
            VStack{
                MarqueeText(text: previews, speed: 20, delay: 0.5,font: .system(size: 15))
                    .padding(.vertical,0)
                HStack(spacing:0){
                    MenuItemButton(systemName: "clipboard.fill",onTap: {CopyAndPaste(0)},width: objectWidth/2, height: 20)
                    MenuItemButton(systemName: "doc.on.doc",onTap: {CopyAndPaste(1)},width: objectWidth/2, height: 20)
                }
            }
            if(isHovered){
                HStack{
                    Spacer()
                    VStack{
                        ZStack{
                            Circle()
                                .fill(Color.black) // 填滿藍色
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                
                            Image(systemName: "x.circle.fill")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .foregroundStyle(.gray)
                                .onTapGesture {
                                    if id >= 0 && id < StringStorage.shared.Item.count {
                                        withAnimation(.easeInOut(duration: 0.2)){
                                            offsetX = -objectWidth
                                        }
                                        widthAnimate(0,duration:0.2)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.21) {
                                            StringStorage.shared.Item.remove(at: id)
                                            StringStorage.shared.containID = UUID()
                                        }
                                    }
                                }
                        }.frame(width: 16, height: 16)
                            .offset(x:8)
                        Spacer()
                    }
                }
            }
        }
        .offset(x: offsetX)
        .frame(width:width)
        .padding(.horizontal,width/8)
        .background(BackgroundColor)
        .clipped()
        .onHover{ h in
            isHovered = h
            BackgroundColor = isHovered ? Color.gray.opacity(0.3) : .black
            StringStorage.shared.lastScrollPosID = id
        }
        .onTapGesture {
            if(previews == ""){CopyAndPaste(0)}
            else{CopyAndPaste(1)}
        }
        .onAppear {
            if(isAppear){return}
            StringStorage.shared.Item[id].1 = true
            offsetX = -objectWidth
            withAnimation(.easeInOut(duration: 0.2)){
                offsetX = 0
            }
            width = 0
            widthAnimate(objectWidth)
        }
    }
    func CopyAndPaste(_ i:Int){
        if(i == 0){//貼上
            let pasteboard = NSPasteboard.general
            if let copied = pasteboard.string(forType: .string) {
                previews = copied
                StringStorage.shared.Item[id].0 = previews
            }
        }else if(i == 1){
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(previews, forType: .string)
        }
    }
    
    func widthAnimate(_ to:CGFloat,duration:Double = 0.2){
        let stepTime = 0.01
        let d = (duration * 100).rounded() / 100
        let totalSteps = Int(d/stepTime)
        let deltha:CGFloat = to - width
        let delthaEveryStep:CGFloat = deltha / CGFloat(totalSteps)
        for i in 0..<totalSteps{
            DispatchQueue.main.asyncAfter(deadline: .now() + stepTime*CGFloat(i)){
                width += delthaEveryStep
                if width < 0{width=0;return}
            }
        }
    }
}


