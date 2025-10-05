//
//  global.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/4/13.
//


import SwiftUI
import AppKit




var MusicInfo:(TrackName:String,ArtistAndAlbumName:String,artwork: NSImage?,currentTime:Double,totalTime:Double,progress:Double, isPlay:Bool) = ("","",nil,0,0,0,false)

class HoverState: ObservableObject {
    static let IslandHoverState:HoverState = HoverState()
    
    @Published var isHovering: Bool = false
    @Published var isDragger: Bool = false
}


class ViewSpace: ObservableObject {
    static let AirDrop:ViewSpace = ViewSpace()
    static let FileDrop:ViewSpace = ViewSpace()
    
    @Published var frame:CGRect = CGRect.zero
    @Published var isHovering:Bool = false
    
    func checkHovering(_ point:CGPoint){
        withAnimation(.easeInOut(duration: 0.2)){
            isHovering = frame.contains(point)
        }
//        print(isHovering)
    }
    
}



func getMousePoint() -> CGPoint {
    var mousePosition = NSEvent.mouseLocation
    let screen = ScreenMonitor.getNowScreen()
    mousePosition.y = screen.frame.height - mousePosition.y + screen.frame.origin.y
    mousePosition.x = mousePosition.x - screen.frame.width/2 + IslandTypeManager.shared.getNowWindowSize().width/2 - screen.frame.origin.x
//    print(mousePosition)
    return mousePosition
}



let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
