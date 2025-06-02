//
//  IslandTypeManager.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/6/2.
//

import SwiftUI
import AppKit



class IslandTypeManager: ObservableObject {
    enum IslandType:String, Codable{
        case hide
        case onCharge
        case gameMode
        case exten
        case Drop
        case Clock
        case Hardware
        case ForceFocus
        
        var level: Int {
            switch self {
            case .hide: return 0
            case .onCharge, .gameMode: return 1
            case .exten, .Drop, .Clock, .Hardware: return 2
            case .ForceFocus: return 3
            }
        }
    }
    
    static private let WindowSize:[IslandType:(width:CGFloat,height:CGFloat,downRadius:CGFloat,upRadius:CGFloat)] = [
        .hide:(width:0,height:0,downRadius:11,upRadius:6),
        .onCharge:(width:210,height:1,downRadius:11,upRadius:6),
        .gameMode:(width:210,height:1,downRadius:11,upRadius:6),
        .exten:(width:410,height:168,downRadius:25,upRadius:20),
        .Drop:(width:410,height:168,downRadius:25,upRadius:20),
        .Clock:(width:410,height:168,downRadius:25,upRadius:20),
        .Hardware:(width:410,height:168,downRadius:25,upRadius:20),
        .ForceFocus:(width:1470,height:960,downRadius:0,upRadius:0),
    ]
    
    struct outsideChangeInfo{
        var type:IslandType
        var animate:Bool
        var Enforce:Bool
    }
    
    @Published private(set) var type:IslandType = .hide
    @Published private(set) var outsideChange:IslandType? = nil
    @Published var isLock:Bool = false
    @Published private(set) var ousideEnforceChange:Bool = false
    @Published private(set) var ousideChangeWithAnimate:Bool = false
    @Published var defaultWindowType:IslandType = .exten
    @Published var lastWindowType:IslandType = .exten
    
    private var islandViewChangeQueue:[outsideChangeInfo] = []
    
    static var Resize:CGFloat {
        let screen = getNowScreen()
        let safeAreaInsets = screen.safeAreaInsets
        return hasNotch ? safeAreaInsets.top/32 : 1
    }

    static var hasNotch:Bool{
        let screen = getNowScreen()
        let safeAreaInsets = screen.safeAreaInsets
        return safeAreaInsets.top > 0
    }

    static let EdgeToTop:CGFloat = 0
    
    static func isIslandTypeToBig(from:IslandType,to:IslandType) -> Bool{
        return from.level < to.level
    }
    
    static func getWindowSize(_ windowType:IslandType) -> CGSize {
        var w:CGFloat = self.WindowSize[windowType]?.width ?? 0
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

    
    func getNowWindowSize() -> CGSize {
        return IslandTypeManager.getWindowSize(type)
    }
    
    static func getWindowRadius(_ windowType:IslandType) -> (down:CGFloat, up:CGFloat) {
        var down:CGFloat = WindowSize[windowType]?.downRadius ?? 0
        var up:CGFloat = WindowSize[windowType]?.upRadius ?? 0
        if(!hasNotch && windowType == .hide){down=1;up=0}
        else if(windowType == .hide){
            down *= Resize
            up *= Resize
        }
        return (down, up)
    }
    
    func OutsideChangeIslandType(to:IslandType,Animate:Bool = true ,EnforceChange:Bool = false){
        if(outsideChange != nil){
            islandViewChangeQueue.append(outsideChangeInfo(type: to,animate: Animate,Enforce: EnforceChange))
            return
        }
        ousideEnforceChange = EnforceChange
        outsideChange = to
        ousideChangeWithAnimate = Animate
    }
    
    func OutsideChangeIslandType(outsideChange OusideChangeInfo:outsideChangeInfo){
        if(outsideChange != nil){
            islandViewChangeQueue.append(OusideChangeInfo)
            return
        }
        ousideEnforceChange = OusideChangeInfo.Enforce
        outsideChange = OusideChangeInfo.type
        ousideChangeWithAnimate = OusideChangeInfo.animate
    }

    func getNowIslandType() -> IslandType {
        return type
    }
    
    func changeIslandType(_ type:IslandType){
        self.type = type
    }
    
    func checkNowIslandTypeIs(_ type:IslandType) -> Bool {
        return self.type == type
    }
    
    func refreshIsland(Animate:Bool = true){
        OutsideChangeIslandType(to: type,Animate: Animate, EnforceChange: true)
    }
    
    func checkWeatherOusideChange() -> Bool {
        return outsideChange != nil
    }
    
    func resetOutsideChange(){
        outsideChange = nil
        ousideEnforceChange = false
        ousideChangeWithAnimate = false 
        guard let first = islandViewChangeQueue.first else{
            return
        }
        islandViewChangeQueue.removeFirst()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.OutsideChangeIslandType(outsideChange:first)
        }
    }
    
    func ShouldRefreshIsland() -> Bool {
        return ousideEnforceChange || (outsideChange != type && outsideChange != nil)
    }
    
    func changelastIslandType(_ type:IslandType?){
        if(defaultWindowType == .hide && type != .onCharge && type != .gameMode){
            lastWindowType = type == nil ? self.type : type!
        }
    }
}
var islandTypeManager:IslandTypeManager = IslandTypeManager()

