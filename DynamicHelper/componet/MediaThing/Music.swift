//
//  Music.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/4/18.
//

import OSAKit
import Foundation // For DispatchQueue
import SwiftUI

struct MusicView: View {
    @ObservedObject private var iTM : IslandTypeManager = IslandTypeManager.shared
    @State var TrackName:String = MusicInfo.TrackName
    @State var Artist:String = MusicInfo.Artist
    @State var Album:String = MusicInfo.Album
    @State var artwork: NSImage? = MusicInfo.artwork
    @State var ArtistAndAlbumName: String = "\(MusicInfo.Artist) - \(MusicInfo.Album)"
    @State var currentTime:Double = MusicInfo.currentTime
    @State var totalTime:Double = MusicInfo.totalTime
    @State var progress:Double = MusicInfo.progress
    @State private var isPlay:Bool = MusicInfo.isPlaying
    @State private var isVisible = false
    @State private var firstTime:Bool = true
    @State private var isDraggingButPause:Bool = false
    @State private var AfterDraggingButPause:Double = 0.0
    
    @State private var timer:Timer? = nil
    
    
    @State private var startPlayingTime: Date?
    
    
    var body: some View {
        HStack(spacing: 0){
            if IslandTypeManager.shared.checkNowIslandTypeIs(.Music){
                MusicIconButton(artwork: artwork)
                    .padding(.vertical,20)
                    .padding(.horizontal,30)
            }
            MusicView
        }
    }
    
    
    
    private var MusicView: some View {
        VStack(spacing:0){
            let NowIslandTypeIsMusic:Bool = IslandTypeManager.shared.checkNowIslandTypeIs(.Music)
            if !NowIslandTypeIsMusic{
                MusicIconButton(artwork: artwork)
            }
            
            let font1:CGFloat = NowIslandTypeIsMusic ? 20 : 13
            let font2:CGFloat = NowIslandTypeIsMusic ? 15 : 10
            
            MarqueeText(text: TrackName, speed: 20, delay: 0.5,font: .system(size: font1),shouldMask: true)
                .padding(.horizontal)
                .padding(.top,5)
            MarqueeText(text: ArtistAndAlbumName, speed: 20, delay: 0.5, TextColor: Color.gray,font: .system(size: font2),shouldMask: true)
                .padding(.horizontal)
                .padding(.bottom,5)
            
            
            TimelineView(.periodic(from: Date(), by: 0.1)) { timeline in
                let now = timeline.date
                let start = startPlayingTime ?? now
                let elapsed = isPlay ? now.timeIntervalSince(start) : currentTime
                let pgs:Double =  totalTime == 0 ? 0 : elapsed/totalTime
                SliderBar(progress:pgs){ endDrag, _ in
                    let target = totalTime * endDrag
                    setMusicPlaybackPosition(target)
                    AfterDraggingButPause = target
                    currentTime = target
                    startPlayingTime = Date().addingTimeInterval(-currentTime)
                    isDraggingButPause = !(isMusicPlaying() ?? false)
                }
                .padding(.vertical,3)
                ZStack{
                    let size:CGFloat = NowIslandTypeIsMusic ? 30.0 : 20.0
                    let font:CGFloat = NowIslandTypeIsMusic ? 14.0 : 9.0
                    
                    VStack(){
                        HStack{
                            Text(SecondToMMSS(elapsed))
                                .foregroundColor(.white)
                                .font(.system(size: font))
                            Spacer()
                            Text(SecondToMMSS(totalTime))
                                .foregroundColor(.white)
                                .font(.system(size: font))
                        }
                    }.frame(alignment: .top)
                        .padding(.horizontal)
                    HStack(spacing:3){
                        MenuItemButton(systemName: "backward.fill",onTap: {ControlMusic(0)},size:size,ResizeMagin:1.2).padding(.vertical,3)
                        
                        MenuItemButton(systemName: isPlay ? "pause.fill" : "play.fill",onTap: {ControlMusic(1)},size:size,ResizeMagin:1.2).padding(.vertical,3)
                        
                        MenuItemButton(systemName: "forward.fill",onTap: {ControlMusic(2)},size:size,ResizeMagin:1.2).padding(.vertical,3)
                    }.frame(maxHeight: size)
                    
                }
            }
        }
        .frame(
            maxWidth: IslandTypeManager.shared.checkNowIslandTypeIs(.Music) ? .infinity : 180,
            maxHeight: .infinity
        )
        .onAppear {
            isVisible = true
            isPlay = (isMusicPlaying()) ?? false
            startUpdate()
        }
        .onDisappear {
            isVisible = false
            stopUpdate()
        }
    }
    
    
    
    func ControlMusic(_ function:Int){
        switch function {
        case 0:
            previousTrack(currentTime)
            isPlay = true
            return
        case 1:
            updateMusicInfo(isFirst: true)
            togglePlayPauseMusic()
            if(isDraggingButPause){
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                    setMusicPlaybackPosition(AfterDraggingButPause)
                }
            }
            isPlay = (isMusicPlaying()) ?? false
            return
        case 2:
            nextTrack()
            isPlay = true
            return
        default:
            return
        }
    }
    
    func refreshCurrentTime(){
        currentTime = getMusicPlaybackPosition() ?? currentTime
        startPlayingTime = Date().addingTimeInterval(-currentTime)
    }
    
    func startUpdate() {
        stopUpdate()
        self.updateMusicInfo(isFirst: true)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.updateMusicInfo()
        }
    }
    
    func stopUpdate() {
        timer?.invalidate()
        timer = nil
    }
    
    
    func updateMusicInfo(isFirst:Bool = false) {
        isPlay = isMusicPlaying() ?? false
        guard let (a,b,c) = getMusicInfoViaShell() ,
              let TotalTime = getCurrentTrackDuration()
        else {
            return
        }
        if a == TrackName && !isFirst {return}
        progress = totalTime==0 ? 0 : currentTime / totalTime
        refreshCurrentTime()
        totalTime = TotalTime      
        TrackName = a
        var center = " - "
        if(b == "" || c == ""){
            center = ""
        }
        if "\(b)\(center)\(c)" != ArtistAndAlbumName {
            ArtistAndAlbumName = "\(b)\(center)\(c)"
            Artist = b
            Album = c
        }
        if let img = loadMusicArtworkImage() {
            artwork = img
        }
        MusicInfo = MediaInfo(TrackName,Artist,Album,currentTime,totalTime,progress,"",artwork,isPlay)
    }
}


//#Preview {
//    MusicView()
//}
