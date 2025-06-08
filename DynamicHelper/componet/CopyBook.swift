//
//  CopyBook.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/4/30.
//

import SwiftUI
import AppKit

class StringStorage: ObservableObject {
    @Published var Item: [(String,Bool)] = []
    var lastScrollPosID:Int? = 0
    var lastScrollPos:CGFloat = 0
    var containID = UUID()
    let objectWidth:CGFloat = 80
}
var stringStorage = StringStorage()

struct CopyBookScroller: View {
    @State private var offsetX:CGFloat = 0
    @State private var maxWidth:CGFloat = 0
    @State private var lastItemCount: Int = 0
    var body: some View {
        ScrollViewWithOffsetBinding(offsetX:$offsetX) {
            CopyBook()
        }
        .frame(height: 50,alignment: .leading)
        .frame(maxWidth: .infinity)
        .scrollIndicators(.hidden)
        .clipped()
        //        .scrollPosition(id: $visibleID)
        .onAppear{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01)
            {
                offsetX = stringStorage.lastScrollPos
            }
        }
        .onDisappear {
            stringStorage.lastScrollPos = offsetX
        }
        .onReceive(stringStorage.$Item) {newValue in
            if lastItemCount < newValue.count && stringStorage.objectWidth*CGFloat(newValue.count) > maxWidth{
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.001)
                {
                    offsetAnimation(offsetX+stringStorage.objectWidth+20)
                }
            }
            lastItemCount = newValue.count
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        maxWidth = geo.size.width
                    }
            }
        )
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
            }.id(Strings.containID)
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
                    stringStorage.Item.append(("",false))
                    Strings.containID = UUID()
                }
            
        }
    }
}



struct CopyBook_Previews:View {
    @State private var previews:String
    private var id:Int
    private let objectWidth:CGFloat = stringStorage.objectWidth
    @State private var isHovered:Bool = false
    @State private var offsetX:CGFloat = 0
    @State private var width:CGFloat = stringStorage.objectWidth
    @State private var isAppear:Bool = false

    
    init(previews: (String,Bool), id: Int) {
        _previews = State(initialValue: previews.0)
        isAppear = previews.1
        self.id = id
    }
    var body: some View {
        ZStack{
            VStack{
                MarqueeText(text: previews, speed: 0.05, delay: 0.5,font: .system(size: 15))
                    .padding(.vertical,0)
                    .allowsHitTesting(false)
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
                                    if id >= 0 && id < stringStorage.Item.count {
                                        withAnimation(.easeInOut(duration: 0.2)){
                                            offsetX = -objectWidth
                                        }
                                        widthAnimate(0,duration:0.2)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.21) {
                                            stringStorage.Item.remove(at: id)
                                            stringStorage.containID = UUID()
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
        .background(isHovered ? Color.gray.opacity(0.3) : .black)
        .clipped()
        .onHover{ h in
            isHovered = h
        }
        .onTapGesture {
            if(previews == ""){CopyAndPaste(0)}
            else{CopyAndPaste(1)}
        }
        .onAppear {
            if(isAppear){return}
            stringStorage.Item[id].1 = true
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
                stringStorage.Item[id].0 = previews
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


