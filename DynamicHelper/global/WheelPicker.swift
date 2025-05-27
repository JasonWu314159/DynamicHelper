//
//  WheelPicker.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/5/2.
//

import SwiftUI

import SwiftUI

struct WheelPicker: View {
    let range: Range<Int>
    @Binding var selection: Int
    @State var selectionOffset: Int = 0
    @State var offset: CGFloat
    let scrollWay: Axis
    let itemSize: CGFloat = 20
    @State var lastItemOffset: CGFloat = 0
    @State var ScrollAnimateTime: CGFloat? = 0
    @State var Size: CGSize = .zero
    
    init(range r: Range<Int>, selection: Binding<Int>, scrollWay s: Axis = .vertical) {
        self.range = r
        self._selection = selection
        self.scrollWay = s
        self.offset = 0 //CGFloat(self.range.upperBound) * itemSize
    }
    

    var body: some View {
        GeometryReader { geometry in
            ZStack{
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(.gray.opacity(0.2))
                    .frame(height: itemSize)
                Group{
                    if(scrollWay == .horizontal){
                        ScrollViewWithOffsetBinding(offsetX: $offset){
                        }
                    }else{
                        ScrollViewWithOffsetBinding(offsetY: $offset,AnimateTime: $ScrollAnimateTime, onScrollEnded: {ToCorrectOffset()}){
                            PickerScrollView(
                                range: range,
                                offset: $offset,
                                itemSize: itemSize,
                                selectedIndex: $selectionOffset,
                                scrollWay: scrollWay
                            )
                        }
                    }
                }
                .mask(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0.0),   // 頂部完全透明
                            .init(color: .black, location: 0.5),   // 漸層進入可見
                            .init(color: .black, location: 0.5),   // 保持可見
                            .init(color: .clear, location: 1.0) 
                        ]),
                        startPoint: scrollWay == .vertical ? .top : .leading,
                        endPoint: scrollWay == .vertical ? .bottom : .trailing
                    )
                )
                .onAppear{
                    Size = geometry.size
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
                    {
                        offset = firstItemOffset+CGFloat(selection)*itemSize
                        ToCorrectOffset()
                    }
                }
                .onChange(of: offset) { oldValue, newValue in
                    if(offset > firstItemOffset + ItemHeightOffset){
                        ScrollAnimateTime = 0
                        offset = firstItemOffset
                    }else if(offset < firstItemOffset){
                        ScrollAnimateTime = 0
                        offset = firstItemOffset + ItemHeightOffset
                    }
                    lastItemOffset = offset
                }
            }
        }
        .frame(maxWidth: .infinity)
        .clipped()
    }
    
    var firstItemOffset: CGFloat {
        let r = self.range.upperBound-self.range.lowerBound
        let o = scrollWay == .vertical ? Size.height/2 : Size.width/2
        return (CGFloat(r) * itemSize) - o + itemSize/2
    }
    
    var ItemHeightOffset: CGFloat {
        let r = self.range.upperBound-self.range.lowerBound
        return (CGFloat(r) * itemSize)
    }
    
    
    func ToCorrectOffset(){
        if(lastItemOffset != offset){return}
        let IntOffset = Int(offset)
        let IntFirstItemOffset = Int(firstItemOffset)
        let IntItemSize = Int(itemSize)
        
        var CorrectOffset:CGFloat = 0
        if((IntOffset - IntFirstItemOffset) % IntItemSize >= IntItemSize/2){
            CorrectOffset = offset+CGFloat(IntItemSize - (IntOffset - IntFirstItemOffset) % IntItemSize)
        }else{
            CorrectOffset = offset-CGFloat((IntOffset - IntFirstItemOffset) % IntItemSize)
        }
        //CorrectOffset// += CGFloat(IntItemSize/4)
        ScrollAnimateTime = 0.25
        offset = CorrectOffset
        lastItemOffset = offset
        
        selection = ((IntOffset - IntFirstItemOffset) / IntItemSize + self.range.lowerBound)
        selectionOffset = selection + self.range.upperBound - self.range.lowerBound
    }
}

struct PickerScrollView: View {
    let range: Range<Int>
    @Binding var offset: CGFloat
    let item: [(offset:Int, Int)] 
    let itemSize: CGFloat
    @Binding var selectedIndex: Int
    let scrollWay: Axis
    
    init(range r: Range<Int>,offset: Binding<CGFloat>,itemSize: CGFloat, selectedIndex: Binding<Int>, scrollWay: Axis) {
        self.range = r
        self.item = Array((Array(r)+Array(r)+Array(r)).enumerated())
        self._offset = offset
        self.itemSize = itemSize
        self._selectedIndex = selectedIndex
        self.scrollWay = scrollWay
    }
    
    var body: some View {
        VStack(spacing: 0){
            ForEach(item, id:\.offset){ index, value in
                Text("\(value)")
                    .foregroundStyle(.white)
                    .frame(height: itemSize)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

