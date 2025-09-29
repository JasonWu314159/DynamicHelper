//
//  FileDropper.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/23/25.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers
import Inspect

struct DroppableIslandView: View {
    @ObservedObject var storedFiles:FileStorage = fileStorage
    @ObservedObject var fileDropViewSpace = FileDropViewSpace
    var width:CGFloat = 360
    var height:CGFloat = 100
    
    @State private var offsetX:CGFloat = 0
    
    
    var body: some View {
        GeometryReader { geo in
            ZStack() {
                if !storedFiles.Files.isEmpty {
                    FileContainerView(storedFiles:storedFiles)
                    .frame(maxHeight: .infinity)
                    .onTapGesture {
                        for i in 0..<storedFiles.Files.count {
                            storedFiles.Files[i].isClicked = false
                        }
                    }
                }
                RoundedRectangle(cornerRadius: 30)
                    .stroke(
                        Color(red: 0.5, green: 0.5, blue: 0.5),
                        lineWidth: FileDropViewSpace.isHovering ? 10 : 5
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if(storedFiles.Files.isEmpty ){
                    Text("將檔案拖曳到這裡").foregroundColor(.gray)
                }
            }
            .padding()
            .cornerRadius(30)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                FileDropViewSpace.isHovering = false
            }
            .onChange(of: geo.frame(in: .global)) { 
                FileDropViewSpace.frame = geo.frame(in: .global)
            }
            
        }
    }

    
}


struct FileContainerView: View {
    @ObservedObject var storedFiles:FileStorage
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach($storedFiles.Files) {$file in
                        FileInfoView(file: $file, storedFiles: storedFiles).id($file.id)
                        
                    }
                    Color.clear
                        .onAppear{
                            withAnimation {
                                proxy.scrollTo(
                                    storedFiles.lastScrollFileID, anchor: .center
                                )
                            }
                        }
                }
                .padding()
                
            }
            .inspect { (nsScrollView: NSScrollView) in
                nsScrollView.hasHorizontalScroller = false
                nsScrollView.hasVerticalScroller = false
            }
        }
    }
}


struct FileInfoView: View  {
    @Binding var file: FileStorage.FileEntry
    @ObservedObject var storedFiles:FileStorage
    @State private var isHovered: Bool = false
    @State private var isExist = true
    var body: some View {
        ZStack{
            if(file.isClicked){
                RoundedRectangle(cornerRadius: 5)
                    .stroke(
                        Color.gray,
                        lineWidth: 2
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.gray.opacity(0.4))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    )
            }
            else if(isHovered){
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.gray.opacity(0.4))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            VStack {
                Image(nsImage: file.icon)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .cornerRadius(6)
                ZStack{
                    MarqueeText(text: file.RealUrl.lastPathComponent, speed: 20, delay: 0.5,font: .system(size: 13))
                        .padding(.vertical,0)
                        .allowsHitTesting(false)
                    Color.clear
                        .contentShape(Rectangle()) 
                        .frame(maxHeight: 14)
                }
            }
            .clipped()
            .padding(.horizontal,6)
            .onDrag {
                let f = file
//                let provider = NSItemProvider(contentsOf: f.RealUrl)
                let provider = FileStorage.createUnifiedItemProvider(for:f.RealUrl)
                if(NSEvent.modifierFlags.contains(.command)){
                    storedFiles.Files.removeAll { $0 == file }
                }
//                return provider!
                return provider
            }
            .onTapGesture {
                let c = file.isClicked
                if NSEvent.modifierFlags.contains(.command) {
                    NSWorkspace.shared.open(file.RealUrl)
                }
                else if NSEvent.modifierFlags.contains(.option) {
                    NSWorkspace.shared.activateFileViewerSelecting([file.RealUrl])
                }else if NSEvent.modifierFlags.contains(.shift) {
                    
                }else{
                    for i in 0..<storedFiles.Files.count {
                        storedFiles.Files[i].isClicked = false
                    }
                }
                file.isClicked = !c
            }
            
            if(isHovered){
                HStack{
                    Spacer()
                    VStack{
                        ZStack{
                            Circle()
                                .fill(Color.black) // 填滿藍色
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                
                            Image(systemName: "x.circle.fill")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .foregroundStyle(.gray)
                                .onTapGesture {
                                    isExist = false
                                    do {
                                        try FileManager.default.removeItem(at: file.storageURL)
                                        print("✅ 檔案已刪除")
                                    } catch {
                                        print("❌ 刪除失敗：\(error)")
                                    }
                                    withAnimation(.linear){
                                        storedFiles.Files.removeAll { $0 == file }
                                    }
                                }
                        }.frame(width: 16, height: 16)
                            .offset(x:8, y:-8)
                        Spacer()
                    }
                }
            }
        }
        .contextMenu {
            Button("打開") {
                NSWorkspace.shared.open(file.RealUrl)
            }
            Divider()
            Button("顯示於Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([file.RealUrl])
            }
            Divider()
            Button("移除") {
                isExist = false
                storedFiles.Files.removeAll { $0 == file }
                do {
                    try FileManager.default.removeItem(at: file.storageURL)
                    print("✅ 檔案已刪除")
                } catch {
                    print("❌ 刪除失敗：\(error)")
                }
            }
        }
        .onHover{ hovering in
            isHovered = hovering
            if isExist {
                storedFiles.lastScrollFileID = file.id
            }
        }
    }
}


extension AppDelegate{
    func DeleteAllCopyFile(){
        for file in fileStorage.Files{
            do {
                try FileManager.default.removeItem(at: file.storageURL)
                print("✅ 檔案已刪除")
            } catch {
                print("❌ 刪除失敗：\(error)")
            }
        }
    }
}
