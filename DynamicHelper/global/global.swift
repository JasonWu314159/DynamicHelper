//
//  global.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/4/13.
//


import SwiftUI
import AppKit


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


var MusicInfo:(TrackName:String,ArtistAndAlbumName:String,artwork: NSImage?,currentTime:Double,totalTime:Double,progress:Double, isPlay:Bool) = ("","",nil,0,0,0,false)

class HoverState: ObservableObject {
    @Published var isHovering: Bool = false
    @Published var isDragger: Bool = false
}


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
    mousePosition.x -= screen.frame.width/2 - islandTypeManager.getNowWindowSize().width/2 + screen.frame.origin.x
    return mousePosition
}

var isCharging:Bool = false


