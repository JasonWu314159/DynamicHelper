//
//  StateMonitor.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/6/2.
//

import AppKit

func getAppBundleURL(for app: NSRunningApplication) -> URL? {
    guard let exeURL = app.executableURL else {
        print("❌ 無法取得 executableURL")
        return nil
    }

    // 回推至 .app 路徑：.../Contents/MacOS/life_game -> /Applications/life_game.app
    let appURL = exeURL
        .deletingLastPathComponent() // MacOS
        .deletingLastPathComponent() // Contents
        .deletingLastPathComponent() // .app

    if FileManager.default.fileExists(atPath: appURL.path) {
        return appURL
    } else {
        print("❌ 推回的 .app 路徑不存在：\(appURL.path)")
        return nil
    }
}

func getAppCategory(_ app: NSRunningApplication) -> String? {
    let bundleURL: URL
    if let URL = app.bundleURL{
        if URL.pathComponents[1] == "private"{
            bundleURL = URL.deletingLastPathComponent()
        }else{
            bundleURL = URL
        }
    }else{
        guard let URL = getAppBundleURL(for: app) else {
            print("❌ 無法取得 bundleURL")
            return nil
        }
        bundleURL = URL
    }
    

    let candidatePaths = [
        bundleURL.appendingPathComponent("Contents/Info.plist"),
        bundleURL.appendingPathComponent("Info.plist"),
        bundleURL.appendingPathComponent("iTunesMetadata.plist"),
//        bundleURL.appendingPathComponent("Info.plist")
    ]

    for path in candidatePaths {
        if let info = NSDictionary(contentsOf: path),
           let category = info["LSApplicationCategoryType"] as? String {
            return category
        }
        if let info = NSDictionary(contentsOf: path),
           let categories = info["categories"] as? [String] {
            if let gameCategory = categories.first(where: { $0.contains("games") }) {
                return gameCategory
            }else{
                return categories.first
            }
        }
    }
    print("No category found")
    return nil
}

func isLikelyGameApp() -> Bool {
    guard let app = NSWorkspace.shared.frontmostApplication else {print("can't get frontmost app"); return false }

    let gamesCategory: Set<String> = [
        "public.app-category.games",
        "public.app-category.board-games"
    ]
    

    if let category = getAppCategory(app) {
        print("App 類別：\(category)")
        return category.lowercased().contains("games")
    }

    // 2. 常見遊戲 bundle identifier 白名單
    let knownGames: Set<String> = [
//        "com.valvesoftware.steam",
//        "com.blizzard.starcraft2",
//        "com.riotgames.leagueoflegends",
//        "com.pubg.mobile",
//        "com.epicgames.launcher"
        // 可再擴充
    ]
    if let bundleID = app.bundleIdentifier, knownGames.contains(bundleID) {
        return true
    }

    // 3. 名稱模糊比對
    if let name = app.localizedName?.lowercased() {
        let keywords: [String] = []//"game", "steam", "league", "dota", "genshin", "pubg", "valorant"]
        for keyword in keywords {
            if name.contains(keyword) {
                return true
            }
        }
    }

    return false
}
