//
//  IslandTypeManager.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/6/2.
//

import SwiftUI
import AppKit



class IslandTypeManager: ObservableObject {
    static let shared = IslandTypeManager()
    
    static let StandardSizeLevel:Int = 10
    enum IslandType:String, Codable{
        case hide
        case onLogin
        case onMusicPlaying
        case onMusicChanging
        case onCharge
        case gameMode
        case exten
        case Music
        case Drop
        case Clock
        case Hardware
        case ForceFocus
        case RemoteControl
        
        var level: Int {
            switch self {
            case .onMusicPlaying,.onLogin,.onMusicChanging:return IslandTypeManager.StandardSizeLevel-3
            case .onCharge, .RemoteControl: return IslandTypeManager.StandardSizeLevel-2
            case .gameMode: return IslandTypeManager.StandardSizeLevel-1
            case .exten, .Drop, .Clock, .Hardware, .Music: return IslandTypeManager.StandardSizeLevel
            case .ForceFocus: return IslandTypeManager.StandardSizeLevel+1
            default: return IslandTypeManager.StandardSizeLevel-4
            }
        }
    }
    
    static private let WindowSize:[IslandType:(width:CGFloat,height:CGFloat,downRadius:CGFloat,upRadius:CGFloat)] = [
        .hide:(width:0,height:0,downRadius:11,upRadius:6),
        .onMusicPlaying:(width:70,height:2,downRadius:13,upRadius:8),
        .onMusicChanging:(width:70,height:20,downRadius:13,upRadius:8),
        .onLogin:(width:70,height:1,downRadius:13,upRadius:8),
        .onCharge:(width:210,height:1,downRadius:13,upRadius:8),
        .RemoteControl:(width:210,height:1,downRadius:13,upRadius:8),
        .gameMode:(width:300,height:1,downRadius:13,upRadius:8),
        .exten:(width:410,height:168,downRadius:25,upRadius:20),
        .Music:(width:410,height:168,downRadius:25,upRadius:20),
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
    
    @Published private(set) var NowType:IslandType = .hide
    @Published private(set) var outsideChange:IslandType? = nil
    @Published var isLock:Bool = false
    @Published private(set) var ousideEnforceChange:Bool = false
    @Published private(set) var ousideChangeWithAnimate:Bool = false
    @Published var defaultWindowType:IslandType = .exten
    @Published var lastWindowType:IslandType = .exten
    @Published private var isPendingOutsideChange:Bool = false
    @Published private(set) var isTypeChanging:Bool = false
    
    private var islandViewChangeQueue:[outsideChangeInfo] = []
    
    static var NotchHeight:CGFloat {
        let screen = ScreenMonitor.getNowScreen()
        let safeAreaInsets = screen.safeAreaInsets
        return safeAreaInsets.top
    }
    
    static var Resize:CGFloat {
        return hasNotch ? NotchHeight/32 : 1
    }

    static var hasNotch:Bool{
        let screen = ScreenMonitor.getNowScreen()
        let safeAreaInsets = screen.safeAreaInsets
        return safeAreaInsets.top > 0
    }

    static let EdgeToTop:CGFloat = 0
    
    static func isIslandTypeToSmall(from:IslandType,to:IslandType) -> Bool{
        return from.level > to.level
    }
    
    static func isIslandTypeToBig(from:IslandType,to:IslandType) -> Bool{
        return from.level < to.level
    }
    
    static func getWindowSize(_ windowType:IslandType) -> CGSize {
        var w:CGFloat = self.WindowSize[windowType]?.width ?? 0
        var h:CGFloat = WindowSize[windowType]?.height ?? 0
        if(!hasNotch && windowType == .hide){h=1;w=ScreenMonitor.getNowScreen().frame.width}
        else if(!hasNotch && windowType != .hide){h += 32;w += 190}
        else {
            let screen = ScreenMonitor.getNowScreen()
            let safeAreaInsets = screen.safeAreaInsets
            w += Resize < 1 && windowType != .hide ? 190 : Resize*190
            h += safeAreaInsets.top
        }
        return CGSize(width: w, height: h)
    }

    
    func getNowWindowSize() -> CGSize {
        return IslandTypeManager.getWindowSize(NowType)
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
    
    func getNowWindowRadius() -> (down:CGFloat, up:CGFloat) {
        return IslandTypeManager.getWindowRadius(NowType)
    }
    
    func OutsideChangeIslandType(to:IslandType,Animate:Bool = true ,EnforceChange:Bool = false){
        OutsideChangeIslandType(outsideChange: outsideChangeInfo(type: to, animate: Animate, Enforce: EnforceChange))
    }
    
    func OutsideChangeIslandType(outsideChange OusideChangeInfo:outsideChangeInfo, tofirst:Bool = false){
        islandViewChangeQueue.append(OusideChangeInfo)
        if !isPendingOutsideChange{
            isPendingOutsideChange = true
            // 安排在下一幀執行
            DispatchQueue.main.async {
                let ChangeInfo = self.islandViewChangeQueue.sorted(by: {$0.type.level > $1.type.level})[0]
                self.ousideEnforceChange = ChangeInfo.Enforce
                self.outsideChange = ChangeInfo.type
                self.ousideChangeWithAnimate = ChangeInfo.animate
                self.islandViewChangeQueue = []
                self.isPendingOutsideChange = false
            }
        }
    }
    
    func setIslandViewChangeState(isChanging:Bool){
        isTypeChanging = isChanging
    }

    func getNowIslandType() -> IslandType {
        return NowType
    }
    
    func changeIslandType(_ type:IslandType){
        self.NowType = type
    }
    
    func checkNowIslandTypeIs(_ type:IslandType) -> Bool {
        return self.NowType == type
    }
    
    func refreshIsland(Animate:Bool = true){
        OutsideChangeIslandType(to: NowType,Animate: Animate, EnforceChange: true)
    }
    
    func checkWeatherOusideChange() -> Bool {
        return outsideChange != nil
    }
    
    func resetOutsideChange(){
        outsideChange = nil
        ousideEnforceChange = false
        ousideChangeWithAnimate = false 
    }
    
    func ShouldRefreshIsland() -> Bool {
        return ousideEnforceChange || (outsideChange != NowType && outsideChange != nil)
    }
    
    func changelastIslandType(_ typeOptional:IslandType?){
        guard let typeReal = typeOptional else{
            lastWindowType = lastWindowType.level >= IslandTypeManager.StandardSizeLevel ? lastWindowType : .exten
            return
        }
        
        if(defaultWindowType == .hide && typeReal.level >= IslandTypeManager.StandardSizeLevel){
            lastWindowType = typeReal
        }
    }
}

