//
//  MusicIconButton.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/10/1.
//

import SwiftUI

struct MusicIconButton: View {
    let artwork: NSImage?
    @State private var MusicImageIsHover:Bool = false
    
    @State private var WidthScale:CGFloat = 1
    
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let imagesize = artwork?.size ?? CGSize(width: 1,height: 1)
            let widthScale:CGFloat = imagesize.width / imagesize.height
            let RoundedRectangleDelta: CGFloat = size*0.15/2
            let width = size * widthScale
            let height = size
            let RoundedRectangleScaleX = (width + 2 * RoundedRectangleDelta) / width + 0.015
            let RoundedRectangleScaleY = (height + 2 * RoundedRectangleDelta) / height + 0.015
            
            
            ZStack{
                Color.clear
                    .onAppear{
                        WidthScale = widthScale
                    }
                    .onChange(of: artwork){
                        WidthScale = widthScale
                    }
                ZStack{
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(MusicImageIsHover ? 0.5 : 0))
                        .frame(width:  width,height: height)
                        .scaleEffect(
                            x: MusicImageIsHover ? RoundedRectangleScaleX : 1.0,
                            y: MusicImageIsHover ? RoundedRectangleScaleY : 1.0
                        )
                        .overlay(
                            ZStack {
                                Group{
                                    if let image = artwork {
                                        Image(nsImage: image).resizable()
                                    } else {
                                        AppIcon(for: "com.apple.Music").resizable().scaleEffect(1.2)
                                    }
                                }
                                .scaledToFit()
                                .cornerRadius(10)
                                .onTapGesture {
                                    if(NSEvent.modifierFlags.contains(.command)) || IslandTypeManager.shared.checkNowIslandTypeIs(.Music){
                                        openMusic()
                                        return
                                    }else{
                                        IslandTypeManager.shared
                                            .OutsideChangeIslandType(
                                                to: .Music,
                                                Animate: true
                                            )
                                    }
                                }
                                .scaleEffect(MusicImageIsHover ? 1.03 : 1.0)
                                .onHover{ishovering in  
                                    withAnimation(.easeInOut(duration: 0.2)){
                                        MusicImageIsHover = ishovering 
                                    }
                                }
                                if let _ = artwork {
                                    let s:CGFloat = IslandTypeManager.shared.checkNowIslandTypeIs(.Music) ? 40 : 25
                                    AppIcon(for: "com.apple.Music")
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(10)
                                        .frame(width: s,height: s)
                                        .offset(x:(width-s/2)/2,y:(height-s/2)/2)
                                        .scaleEffect(MusicImageIsHover ? 1.03 : 1.0)
                                }
                            }
                        )
                }.frame(width:  width,height: height)
            }.frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .center
            )
        }
        .aspectRatio(WidthScale == 0 ? 1 : WidthScale, contentMode: .fit)
    }
    
}
