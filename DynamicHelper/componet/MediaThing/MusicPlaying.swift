//
//  MusicPlaying.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/9/25.
//

import SwiftUI

struct MusicPlaying:View{
    @State var artwork: NSImage? = MusicInfo.artwork
    @State private var isPlay:Bool = MusicInfo.isPlay
    @State private var isVisible = false
    @State private var firstTime:Bool = true
    @State private var NoPlayingTime:Int = 0
    @State private var TrackName: String = MusicInfo.TrackName
    @State private var progress:CGFloat = MusicInfo.progress
    private let TextSize:CGFloat = 13
    
    var body: some View {
        VStack(spacing: 0){
            HStack{
                Group {
                    if let image = artwork {
                        Image(nsImage: image).resizable()
                    } else {
                        Image("MusicDefault").resizable()
                    }
                }
                .frame(width: 25, height: 25)
                .scaledToFit()
                .cornerRadius(5)
                .onAppear{
                    isVisible = true
                    updateMusicInfo()
                }
                .onDisappear{
                    isVisible = false
                }
                .padding(5)
                Spacer()
                AudioSpectrumView(isPlaying: $isPlay)
                    .frame(width: 25, height: 25)
                    .padding(.bottom,10)
            }
            .frame(height: getNowScreen().safeAreaInsets.top+1)
            if islandTypeManager.getNowIslandType() == .onMusicChanging{
                MarqueeText(text: TrackName,speed: 20,font: .system(size:TextSize))
                    .padding(.horizontal,5)
                    .padding(.vertical,1)
            }
            else{
                GeometryReader{geo in
                    Capsule()
                        .fill(.white)
                        .frame(width: geo.size.width * progress, height: 1)
                }
                .padding(.horizontal,5)
            }
        }.frame(maxWidth: .infinity,maxHeight: .infinity)
    }
    
    func updateMusicInfo() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !isVisible {return}
            let (a,b,c) = getMusicInfoViaShell()
            
            let totalTime = getCurrentTrackDuration()
            let currentTime = getMusicPlaybackPosition()
            if isMusicPlaying() ?? false { progress = totalTime == 0 ? 0 : currentTime / totalTime }
            
            if a != TrackName && a != "-"{
                TrackName = a
                MusicInfo.TrackName = a
                var center = " - "
                if(b == "" || c == ""){
                    center = ""
                }
                MusicInfo.ArtistAndAlbumName = "\(b)\(center)\(c)"
                islandTypeManager.OutsideChangeIslandType(to: .onMusicChanging)
                DispatchQueue.main.asyncAfter(deadline: .now() + 7.0){
                    if islandTypeManager.getNowIslandType() == .onMusicChanging{
                        islandTypeManager.OutsideChangeIslandType(to: .onMusicPlaying)
                    }
                }
            }
            
            DispatchQueue.global().async {
                let playing = isMusicPlaying()  // AppleScript
                DispatchQueue.main.async {
                    self.isPlay = playing ?? false
                }
            }
            if !isPlay{
                NoPlayingTime += 1;
                if NoPlayingTime > 4 { islandTypeManager.OutsideChangeIslandType(to: .hide) ;return }
            }else{
                NoPlayingTime = 0
            }
            if let img = loadMusicArtworkImage() {
                artwork = img
                MusicInfo.artwork = img
            }
            updateMusicInfo()
        }
    }
}


