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
    @State var ArtistAndAlbumName:String = MusicInfo.ArtistAndAlbumName
    @State var artwork: NSImage? = MusicInfo.artwork
    
    @State var currentTime:Double = MusicInfo.currentTime
    @State var totalTime:Double = MusicInfo.totalTime
    @State var progress:Double = MusicInfo.progress
    @State private var isPlay:Bool = MusicInfo.isPlay
    @State private var isVisible = false
    @State private var firstTime:Bool = true
    @State private var handleMusicPlaybackStateChange:Bool = false
    @State private var isDraggingButPause:Bool = false
    @State private var AfterDraggingButPause:Double = 0.0
    
    
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
            if !IslandTypeManager.shared.checkNowIslandTypeIs(.Music){
                MusicIconButton(artwork: artwork)
            }
            
            let font1:CGFloat = IslandTypeManager.shared.checkNowIslandTypeIs(.Music) ? 20 : 13
            let font2:CGFloat = IslandTypeManager.shared.checkNowIslandTypeIs(.Music) ? 15 : 10
            
            MarqueeText(text: TrackName, speed: 20, delay: 0.5,font: .system(size: font1))
                .padding(.horizontal)
                .padding(.top,5)
            MarqueeText(text: ArtistAndAlbumName, speed: 20, delay: 0.5, TextColor: Color.gray,font: .system(size: font2))
                .padding(.horizontal)
                .padding(.bottom,5)
            SliderBar(progress:$progress,isDragging: $handleMusicPlaybackStateChange)
                .onChange(of: handleMusicPlaybackStateChange) {
                    if(!handleMusicPlaybackStateChange){
                        setMusicPlaybackPosition(totalTime*progress)
                        AfterDraggingButPause = totalTime*progress
                        isDraggingButPause = !(isMusicPlaying() ?? false)
                        updateMusicInfo()
                    }
                }
                .onChange(of: progress) {
                    if(handleMusicPlaybackStateChange){
                        currentTime = totalTime*progress
                    }
                }
                .padding(.vertical,3)
            ZStack{
                let size:CGFloat = IslandTypeManager.shared.checkNowIslandTypeIs(.Music) ? 30.0 : 20.0
                let font:CGFloat = IslandTypeManager.shared.checkNowIslandTypeIs(.Music) ? 14.0 : 9.0
                
                VStack(){
                    HStack{
                        Text(SecondToMMSS(currentTime))
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
        .frame(
            maxWidth: IslandTypeManager.shared.checkNowIslandTypeIs(.Music) ? .infinity : 180,
            maxHeight: .infinity
        )
        .onAppear {
            isVisible = true
            isPlay = (isMusicPlaying()) ?? false
            updateMusicInfo()
        }
        .onDisappear {
            isVisible = false
        }
    }
    
    
    
    func ControlMusic(_ function:Int){
        switch function {
            case 0:
                previousTrack(currentTime)
                isPlay = true
                return
            case 1:
                togglePlayPauseMusic()
                if(isDraggingButPause){
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                        setMusicPlaybackPosition(AfterDraggingButPause)
                    }
                }
                isPlay = (isMusicPlaying()) ?? false
                if(isPlay){updateMusicInfo()}
                return
            case 2:
                nextTrack()
                isPlay = true
                return
            default:
                return
        }
    }
    
    
    func updateMusicInfo() {
        if !isVisible {return}
        var delay = 0.5
        if firstTime {
            delay = 0
            firstTime = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            MusicInfo = (TrackName,ArtistAndAlbumName,artwork ?? nil,currentTime,totalTime,progress,isPlay)
            if(handleMusicPlaybackStateChange){return}
            let (a,b,c) = getMusicInfoViaShell()
            if a == "-" && !isPlay{updateMusicInfo();return}
            isPlay = isMusicPlaying() ?? false
            totalTime = getCurrentTrackDuration()
            currentTime = getMusicPlaybackPosition()
            progress = totalTime==0 ? 0 : currentTime / totalTime
            if a == TrackName {updateMusicInfo();return}
            TrackName = a
            var center = " - "
            if(b == "" || c == ""){
                center = ""
            }
            if "\(b)\(center)\(c)" != ArtistAndAlbumName {
                ArtistAndAlbumName = "\(b)\(center)\(c)"
            }
            if let img = loadMusicArtworkImage() {
                artwork = img
            }
            updateMusicInfo()
        }
    }
}


//#Preview {
//    MusicView()
//}
