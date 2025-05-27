//
//  MusicFunc.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/22/25.
//

import Foundation
import SwiftUI

func getMusicInfoViaShell() -> (trackName:String, artistName:String, albumName:String) {
    let script = """
    tell application "Music"
        if it is running and player state is playing then
            set trackName to name of current track
            set artistName to artist of current track
            set albumName to album of current track
            return trackName & "==" & artistName & "==" & albumName
        else
            return "No music playing"
        end if
    end tell
    """

    var error: NSDictionary?
    if let appleScript = NSAppleScript(source: script) {
        let result = appleScript.executeAndReturnError(&error)
        if let error = error {
            print("getMusicInfoViaShell() ❌ AppleScript Error: \(error)")
            return ("Error","Error","Error")
        }
        guard let string = result.stringValue else {
            return ("-","-","-")
        }
        let parts = string.split(separator: "==", omittingEmptySubsequences: false).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        
        if parts.count == 3 {
            return (parts[0], parts[1], parts[2])
        }
    }
    return ("-","-","-")
}

func getMusicPlaybackPosition() -> Double {
    let script = """
    tell application "Music"
        if it is running and player state is playing then
            return player position
        else
            return -1
        end if
    end tell
    """

    var error: NSDictionary?
    if let appleScript = NSAppleScript(source: script) {
        let result = appleScript.executeAndReturnError(&error)
        if let error = error {
            print("getMusicPlaybackPosition() AppleScript Error: \(error)")
            return -1
        }

        
        if let seconds = result.coerce(toDescriptorType: typeIEEE64BitFloatingPoint)?.doubleValue, seconds >= 0 {
            return seconds
        }
    }
    return -1
}

func saveMusicArtworkToTemp() {
    let script = """
    tell application "Music"
        if it is running and player state is playing then
            set albumArt to data of artwork 1 of current track
            set filePath to (POSIX file "/tmp/music_artwork.jpg")
            set outFile to open for access filePath with write permission
            set eof outFile to 0
            write albumArt to outFile
            close access outFile
        end if
    end tell
    """

    var error: NSDictionary?
    if let appleScript = NSAppleScript(source: script) {
        _ = appleScript.executeAndReturnError(&error)
        if let error = error {
            print("saveMusicArtworkToTemp() AppleScript Error: \(error)")
        }
    }
}

func loadMusicArtworkImage() -> NSImage? {
    let imagePath = "/tmp/music_artwork.jpg"
    let fileManager = FileManager.default

    do {
        if fileManager.fileExists(atPath: imagePath) {
            try fileManager.removeItem(atPath: imagePath)
        }
    } catch {}
    saveMusicArtworkToTemp()
    return NSImage(contentsOfFile: imagePath)
}


func getCurrentTrackDuration() -> Double {
    let script = """
    tell application "Music"
        if it is running and player state is playing then
            return duration of current track
        else
            return -1
        end if
    end tell
    """

    var error: NSDictionary?
    if let appleScript = NSAppleScript(source: script) {
        let result = appleScript.executeAndReturnError(&error)
        if let error = error {
            print("getCurrentTrackDuration() ❌ AppleScript Error: \(error)")
            return -1
        }
        return result.doubleValue
    }
    return -1
}


func SecondToMMSS(_ seconds: Double) -> String {
    if seconds >= 0 {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    else{
        return "--:--"
    }
}

func setMusicPlaybackPosition(_ seconds: Double) {
    let script = """
    tell application "Music"
        if it is running and player state is playing then
            set player position to \(seconds)
        end if
    end tell
    """

    var error: NSDictionary?
    if let appleScript = NSAppleScript(source: script) {
        appleScript.executeAndReturnError(&error)
        if let error = error {
            print("setMusicPlaybackPosition AppleScript Error: \(error)")
        } else {
//            print("✅ 播放位置已設定為 \(seconds) 秒")
        }
    }
}

func togglePlayPauseMusic(_ isPlay:Bool? = nil) {
    let script = """
    tell application "Music"
        if it is not running then
            launch
            activate
        end if
        \(isPlay == nil ? "playpause" : (isPlay! ? "play": "pause"))
    end tell
    """

    var error: NSDictionary?
    if let appleScript = NSAppleScript(source: script) {
        appleScript.executeAndReturnError(&error)
        if let error = error {
            print("togglePlayPauseMusic ❌ AppleScript Error: \(error)")
        }
    }
}

func nextTrack() {
    let isPlaying = isMusicPlaying()
    if(isPlaying==false || isPlaying==nil){togglePlayPauseMusic(true)}
    let script = "tell application \"Music\" to next track"
    _ = NSAppleScript(source: script)?.executeAndReturnError(nil)
}

func previousTrack(_ NowPlayingTime: Double = 0) {
    struct time {
        static var lastPressTime = Date().timeIntervalSince1970-3
    }
    let isPlaying = isMusicPlaying()
    if(isPlaying==false || isPlaying==nil){togglePlayPauseMusic(true)}
    let currentTimestamp = Date().timeIntervalSince1970
    var script: String = "tell application \"Music\" to previous track"
    if currentTimestamp - time.lastPressTime > 2 && NowPlayingTime > 5{
        script = "tell application \"Music\" to set player position to 0"
    }
    print(script)
    _ = NSAppleScript(source: script)?.executeAndReturnError(nil)
    time.lastPressTime = currentTimestamp
}

func isMusicPlaying() -> Bool? {
    let script = """
    tell application "Music"
        if it is running then
            return player state is playing
        else
            return false
        end if
    end tell
    """

    var error: NSDictionary?
    if let appleScript = NSAppleScript(source: script) {
        let result = appleScript.executeAndReturnError(&error)
        if let error = error {
            print("isMusicPlaying ❌ AppleScript Error: \(error)")
            return nil
        } else {
            return result.booleanValue // ✅ 回傳 true 或 false
        }
    }
    return nil
}

func openMusic(){
    let script: String = """
    tell application "Music"
        if it is not running then
            launch
        end if
        activate
    end tell
    """
    _ = NSAppleScript(source: script)?.executeAndReturnError(nil)
}
