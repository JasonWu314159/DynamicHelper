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
    .hide:(width:0,height:0,downRadius:11,upRadius:6),
    .onCharge:(width:210,height:1,downRadius:11,upRadius:6),
    .exten:(width:410,height:168,downRadius:25,upRadius:20),
    .Drop:(width:410,height:168,downRadius:25,upRadius:20),
    .Clock:(width:410,height:168,downRadius:25,upRadius:20),
    .Hardware:(width:410,height:168,downRadius:25,upRadius:20),
    .ForceFocus:(width:1470,height:960,downRadius:0,upRadius:0),
]

var Resize:CGFloat = 0

var hasNotch:Bool = true

let EdgeToTop:CGFloat = 0

func refreshResize(){
    let screen = getNowScreen()
    let safeAreaInsets = screen.safeAreaInsets
    hasNotch = safeAreaInsets.top > 0
    Resize = safeAreaInsets.top == 0 ? 1 : safeAreaInsets.top/32
//    print(Resize)
}


func getNowScreen() -> NSScreen {
    let Screens = getAllScreenInfo()
    var screen:NSScreen
    if(defaultWindowPos == -1){
        for i in Screens{
            if i.isBuiltin{
                return i.screen
            }
        }
        screen = Screens[0].screen
    }else if(defaultWindowPos < Screens.count){
        screen = Screens[defaultWindowPos].screen
    }else{
        screen = Screens[Screens.count-1].screen
    }
    return screen
}


func getWindowSize(_ windowType:WindowType) -> CGSize {
    var w:CGFloat = WindowSize[windowType]?.width ?? 0
    var h:CGFloat = WindowSize[windowType]?.height ?? 0
    if(!hasNotch && windowType == .hide){h=1;w=getNowScreen().frame.width}
    else if(!hasNotch && windowType != .hide){h += 32;w += 190}
    else {
        let screen = getNowScreen()
        let safeAreaInsets = screen.safeAreaInsets
        w += Resize < 1 && windowType != .hide ? 190 : Resize*190
        h += safeAreaInsets.top
    }
    return CGSize(width: w, height: h)
}


func getWindowRadius(_ windowType:WindowType) -> (down:CGFloat, up:CGFloat) {
    var down:CGFloat = WindowSize[windowType]?.downRadius ?? 0
    var up:CGFloat = WindowSize[windowType]?.upRadius ?? 0
    if(!hasNotch && windowType == .hide){down=1;up=0}
    else if(windowType == .hide){
        down *= Resize
        up *= Resize
    }
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
    @Published var ousideEnforceChange:Bool = false
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
//        print(isHovering)
    }
}

var AirDropViewSpace:ViewSpace = ViewSpace()
var FileDropViewSpace:ViewSpace = ViewSpace()


func getMousePoint() -> CGPoint {
    var mousePosition = NSEvent.mouseLocation
    let screen = getNowScreen()
    mousePosition.y = screen.frame.height - mousePosition.y + screen.frame.origin.y
    mousePosition.x -= screen.frame.width/2 - getWindowSize(windowState.type).width/2 + screen.frame.origin.x
    return mousePosition
}

var isCharging:Bool = false


