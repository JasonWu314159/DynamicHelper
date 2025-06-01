# DynamicHelper

**DynamicHelper** 是一款專為 **macOS** 設計的動態懸浮視窗工具，靈感來自 iPhone 的 Dynamic Island。整合了 **電池監控、音樂播放狀態偵測、剪貼簿筆記儲存與多螢幕動態顯示** 等功能，打造高效率且不干擾作業流程的桌面體驗。

> 🖥️ 支援 Apple Silicon，專為 macOS 桌面空間（Spaces）優化！

## ✨ 功能特色

### 🧊 IslandView：永遠懸浮的動態視窗  
- 永遠顯示於最上層，支援 macOS Spaces  
- 不受其他 App 或系統操作干擾  
- 自動調整大小與位置以配合內容更新  

### 🔋 BatteryView：充電狀態感知  
- 連接電源時顯示充電狀態資訊  
- 拔除電源後自動切換顯示其他元件  

### 📒 CopyBook：可滑動的文字儲存器  
- 支援滑動儲存、點擊貼上與右鍵互動  
- 自動記憶最後一次滑動位置  
- 適合用作快速複製、語錄儲存或即時筆記  

### 🎵 MediaStatusMonitor：播放狀態偵測  
- 支援偵測 Apple Music 是否正在播放，未來可能拓展至youtube或spotify  
- 可與 IslandView 整合進行狀態顯示  


### 🖥️ 多螢幕支援與自動對齊  
- IslandView 根據內容自動縮放並定位  
- 在多螢幕配置下，自動對齊主螢幕或內建螢幕 

### 🧩 選單列圖標與控制項  
- 支援 macOS 系統選單列常駐  
- 可從選單列開關視窗或執行常用操作  

---

## 🛠️ 安裝方式

1. 使用 Xcode 15 或以上版本開啟專案  
### 使用 Xcode 自行編譯：

    1. 安裝 [Xcode 15+](https://developer.apple.com/xcode/)
    2. Clone 專案：
       ```bash
       git clone https://github.com/JasonWu314159/DynamicHelper.git
       cd DynamicHelper
       open DynamicHelper.xcodeproj```
2. 確保系統設定允許使用私有 API（僅限個人開發用途）  
3. 編譯並執行 App，即可看到 IslandView 懸浮視窗出現  
4. 也可以直接從release裡下載已編譯的的app，但有機會不能執行

> 注意：本 App 部分功能使用 macOS 私有 API，僅建議作為個人實驗性工具，請勿用於上架或公開發佈  


---

## 📄 授權 License

此專案為個人用途開發，未授權任何商業或公開發佈使用。請勿未經許可使用或修改。

---

## 🧑‍💻 開發者資訊

- macOS / SwiftUI / 系統整合愛好者  
