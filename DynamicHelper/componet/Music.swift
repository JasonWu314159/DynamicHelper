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
    @State private var MusicImageIsHover:Bool = false
    @State private var isDraggingButPause:Bool = false
    @State private var AfterDraggingButPause:Double = 0.0
    
    
    var body: some View {
        VStack(spacing:0){
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
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(MusicImageIsHover ? 0.5 : 0))
                        .frame(width:  width,height: height)
                        .scaleEffect(
                            x: MusicImageIsHover ? RoundedRectangleScaleX : 1.0,
                            y: MusicImageIsHover ? RoundedRectangleScaleY : 1.0
                        )
                        .overlay(
                            Group {
                                if let image = artwork {
                                    Image(nsImage: image).resizable()
                                } else {
                                    Image("MusicDefault").resizable()
                                }
                            }
                                .scaledToFit()
                                .cornerRadius(10)
                                .onTapGesture {openMusic()}
                                .scaleEffect(MusicImageIsHover ? 1.03 : 1.0)
                                .onHover{ishovering in  
                                    withAnimation(.easeInOut(duration: 0.2)){
                                        MusicImageIsHover = ishovering 
                                    }
                                }
                        )
                }
                .offset(x:(geometry.size.width-width)/2)
                .frame(width:  width,height: height)
            }
            MarqueeText(text: TrackName, speed: 0.05, delay: 0.5,font: .system(size: 13))
                .padding(.horizontal)
                .padding(.top,5)
            MarqueeText(text: ArtistAndAlbumName, speed: 0.05, delay: 0.5, TextColor: Color.gray,font: .system(size: 10))
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
                VStack(){
                    HStack{
                        Text(SecondToMMSS(currentTime))
                            .foregroundColor(.white)
                            .font(.system(size: 9))
                        Spacer()
                        Text(SecondToMMSS(totalTime))
                            .foregroundColor(.white)
                            .font(.system(size: 9))
                    }
                }.frame(alignment: .top)
                .padding(.horizontal)
                HStack(spacing:3){
                    MenuItemButton(systemName: "backward.fill",onTap: {ControlMusic(0)},size:20,ResizeMagin:1.2).padding(.vertical,3)
                    
                    MenuItemButton(systemName: isPlay ? "pause.fill" : "play.fill",onTap: {ControlMusic(1)},size:20,ResizeMagin:1.2).padding(.vertical,3)
                    
                    MenuItemButton(systemName: "forward.fill",onTap: {ControlMusic(2)},size:20,ResizeMagin:1.2).padding(.vertical,3)
                }.frame(maxHeight: 20)
                
            }
        }
        .frame(maxWidth: 180,maxHeight: .infinity)
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
            totalTime = getCurrentTrackDuration()
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
