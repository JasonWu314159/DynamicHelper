//
//  CopyBook.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/4/30.
//

import SwiftUI
import AppKit

class StringStorage: ObservableObject {
    @Published var Item: [String] = []
    var lastScrollPosID:Int? = 0
    var lastScrollPos:CGFloat = 0
    var containID = UUID()
}
var stringStorage = StringStorage()

struct CopyBookScroller: View {
    @State private var offsetX:CGFloat = 0
    var body: some View {
        ScrollViewWithOffsetBinding(offsetX:$offsetX) {
            CopyBook()
        }
        .frame(height: 50,alignment: .leading)
        .scrollIndicators(.hidden)
        .clipped()
//        .scrollPosition(id: $visibleID)
        .onAppear{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
            {
                
//                visibleID = (stringStorage.lastScrollPosID ?? 0) + 1
                offsetX = stringStorage.lastScrollPos
            }
        }
        .onDisappear {
            stringStorage.lastScrollPos = offsetX
        }
    }
}

struct CopyBook: View {
    @ObservedObject var Strings:StringStorage = stringStorage
    @State private var AddButtonIsHover:Bool = false
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .frame(width: 1)
                .frame(maxHeight: .infinity)
                .foregroundStyle(.gray.opacity(0.5))
            ForEach(Array(Strings.Item.enumerated()), id: \.offset) { index, item in
                CopyBook_Previews(previews: item,id: index)
                Rectangle()
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                    .foregroundStyle(.gray.opacity(0.5))
            }.id(UUID())
            Circle()
                .id(Strings.Item.count*3)
                .frame(width: 35, height: 35)
                .foregroundStyle(AddButtonIsHover ? .gray.opacity(0.3) :.black)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 17))
                        .foregroundStyle(.white)
                )
                .onHover{ isHovering in
                    withAnimation(.easeInOut(duration: 0.2)){
                        AddButtonIsHover = isHovering
                    }
                }
                .onTapGesture {
                    stringStorage.Item.append("")
                    Strings.containID = UUID()
                }
            
        }
    }
}



struct CopyBook_Previews:View {
    @State private var previews:String
    private var id:Int
    @State private var isHovered:Bool = false

    
    init(previews: String, id: Int) {
        _previews = State(initialValue: previews)
        self.id = id
    }
    var body: some View {
        ZStack{
            VStack{
                MarqueeText(text: previews, speed: 0.05, delay: 0.5,font: .system(size: 15))
                    .padding(.vertical,0)
                    .allowsHitTesting(false)
                HStack(spacing:0){
                    MenuItemButton(systemName: "clipboard.fill",onTap: {CopyAndPaste(0)},width: 40, height: 20)
                        
                    
                    MenuItemButton(systemName: "doc.on.doc",onTap: {CopyAndPaste(1)},width: 40, height: 20)
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
                                    if id >= 0 && id < stringStorage.Item.count {
                                        stringStorage.Item.remove(at: id)
                                        stringStorage.containID = UUID()
                                    }
                                }
                        }.frame(width: 16, height: 16)
                            .offset(x:8)
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal,10)
        .background(isHovered ? Color.gray.opacity(0.3) : .black)
        .clipped()
        .onHover{ h in
            isHovered = h
        }
        .onTapGesture {
            if(previews == ""){CopyAndPaste(0)}
            else{CopyAndPaste(1)}
        }
    }
    func CopyAndPaste(_ i:Int){
        if(i == 0){//貼上
            let pasteboard = NSPasteboard.general
            if let copied = pasteboard.string(forType: .string) {
                previews = copied
                stringStorage.Item[id] = previews
            }
        }else if(i == 1){
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(previews, forType: .string)
        }
    }
}


