//
//  global.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/4/13.
//


import SwiftUI
import AppKit

enum WindowType:String, Codable{
    case hide
    case exten
    case onCharge
    case Drop
    case Clock
    case Hardware
    case ForceFocus
}

let WindowSize:[WindowType:(width:CGFloat,height:CGFloat,downRadius:CGFloat,upRadius:CGFloat)] = [
    .hide:(width:190,height:32,downRadius:11,upRadius:6),
    .onCharge:(width:400,height:33,downRadius:11,upRadius:6),
    .exten:(width:600,height:200,downRadius:25,upRadius:20),
    .Drop:(width:600,height:200,downRadius:25,upRadius:20),
    .Clock:(width:600,height:200,downRadius:25,upRadius:20),
    .Hardware:(width:600,height:200,downRadius:25,upRadius:20),
    .ForceFocus:(width:1470,height:960,downRadius:0,upRadius:0),
]

var Resize:CGFloat = 0

let EdgeToTop:CGFloat = 2.0

func refreshResize(){
    if let screen = NSScreen.main {
        let safeAreaInsets = screen.safeAreaInsets
        Resize = safeAreaInsets.top/32
    }
}


func getWindowSize(_ windowType:WindowType) -> CGSize {
    var w:CGFloat = WindowSize[windowType]?.width ?? 0
    var h:CGFloat = WindowSize[windowType]?.height ?? 0
    w *= Resize
    h *= Resize
    return CGSize(width: w, height: h)
}


func getWindowRadius(_ windowType:WindowType) -> (down:CGFloat, up:CGFloat) {
    var down:CGFloat = WindowSize[windowType]?.downRadius ?? 0
    var up:CGFloat = WindowSize[windowType]?.upRadius ?? 0
    down *= Resize
    up *= Resize
    return (down, up)
}

var MusicInfo:(TrackName:String,ArtistAndAlbumName:String,artwork: NSImage?,currentTime:Double,totalTime:Double,progress:Double, isPlay:Bool) = ("","",nil,0,0,0,false)

class HoverState: ObservableObject {
    @Published var isHovering: Bool = false
    @Published var isDragger: Bool = false
}

class WindowState: ObservableObject {
    @Published var type:WindowType = .hide
    @Published var outsideChange:WindowType? = nil
    @Published var isLock:Bool = false
}
var windowState:WindowState = WindowState()

var fileStorage:FileStorage = FileStorage()

class ViewSpace: ObservableObject {
    @Published var frame:CGRect = CGRect.zero
    @Published var isHovering:Bool = false
    
    func checkHovering(_ point:CGPoint){
        withAnimation(.easeInOut(duration: 0.2)){
            isHovering = frame.contains(point)
        }
        print(isHovering)
    }
}

var AirDropViewSpace:ViewSpace = ViewSpace()
var FileDropViewSpace:ViewSpace = ViewSpace()


func getMousePoint() -> CGPoint {
    var mousePosition = NSEvent.mouseLocation
    mousePosition.y = NSScreen.main!.frame.height - mousePosition.y
    mousePosition.x -= NSScreen.main!.frame.width/2 - getWindowSize(windowState.type).width/2
    return mousePosition
}

var isCharging:Bool = false
