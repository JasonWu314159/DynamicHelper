//
//  StateMonitor.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/6/2.
//

import AppKit

func getAppCategory(_ app: NSRunningApplication) -> String? {
    guard let bundleURL = app.bundleURL else { return nil }

    let candidatePaths = [
        bundleURL.appendingPathComponent("Contents/Info.plist"),
        bundleURL.appendingPathComponent("Info.plist")
    ]

    for path in candidatePaths {
        if let info = NSDictionary(contentsOf: path),
           let category = info["LSApplicationCategoryType"] as? String {
            return category
        }
    }
    return nil
}

func isLikelyGameApp() -> Bool {
    guard let app = NSWorkspace.shared.frontmostApplication else {print("can't get frontmost app"); return false }

    if let category = getAppCategory(app) {
//        print("App 類別：\(category)")
        return category == "public.app-category.games"
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
