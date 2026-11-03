# KDE Virtual Desktop Notes

![Virtual Desktop Notes icon](package/contents/images/icon.svg)

適用於 **KDE Plasma 5.27**（例如 Kubuntu 24.04）的工具列筆記元件，可自動顯示目前 Virtual Desktop 的名字，並在每個虛擬桌面保留獨立的一行／兩行文字。

## 功能

- **自動顯示桌面名稱**：從 KDE 取得目前桌面名稱，切換或重新命名桌面會自動更新。預設顯示，可在設定中隱藏。
- **獨立筆記**：使用 KDE 虛擬桌面 ID 區分，桌面改名也不會讓筆記混淆。
- **單一輸入框**：點擊筆記即可編輯，只輸入一行或按 Enter 寫第二行，最多兩行。桌面名稱在上方，不佔筆記行數。
- **自適應字型**：文字大小依目前工具列高度、設定寬度與字數自動縮放；編輯時採用顯示字型的實際大小。
- **可調寬度**：80–900 px，預設 240 px。
- **重新開機清空筆記**：筆記只保留在元件記憶體，不寫入檔案；重啟 plasmashell、登出、重開機或移除元件都會清空。元件寬度和標題顯示偏好不會清空。

## 安裝（Kubuntu 24.04 / KDE Plasma 5）

~~~bash
sudo apt install git
git clone https://github.com/pulipulichen/kde-virtual-desktop-notes.git
cd kde-virtual-desktop-notes
bash scripts/install.sh
~~~

安裝腳本也會將專用 SVG 圖示加入使用者的 `hicolor` 圖示主題，讓「新增元件」清單顯示專屬縮圖；**不需要 `sudo`**。

安裝後，在 **KDE 工具列按右鍵 → 新增元件（Add Widgets）→ 搜尋 Virtual Desktop Notes → 加到工具列**。

若要更新已安裝的版本：

~~~bash
cd kde-virtual-desktop-notes
git pull
bash scripts/install.sh --reload
~~~

`--reload` 會重新啟動 Plasma Shell，讓原本工具列上正在執行的舊版 QML 與圖示重新載入。**這會清空所有尚未持久化的筆記**（本工具設計上只保留在記憶體）。如不想立刻重啟，可先執行 `bash scripts/install.sh`，然後登出再登入；若仍見舊畫面，先從工具列移除元件再新增。

## 解除安裝

請先從工具列進入編輯模式，對 **Virtual Desktop Notes** 選擇 **移除元件**，再執行：

~~~bash
cd kde-virtual-desktop-notes
git pull
bash scripts/uninstall.sh
~~~

這會移除目前使用者安裝的 Plasmoid 套件和本專案安裝的 SVG 圖示，**不會刪除其他工具列設定**，也不需要 `sudo`。重複執行不會因套件已不存在而失敗。若 KDE 還顯示快取的舊圖示，可登出再登入，或使用 `bash scripts/uninstall.sh --reload`（會清空工作階段筆記）。

## 使用方式

1. 進入任一 KDE Virtual Desktop，上方會自動顯示桌面名稱（例如「工作」或「研究」）。
2. 點下方筆記區輸入文字。Enter 用於第二行；可只寫一行。
3. 點輸入框外或按 Esc 結束編輯。
4. 切換虛擬桌面時，標題和筆記跟著更新，筆記互不影響。
5. 右鍵開啟元件的 **設定 → Appearance**，調整寬度或取消勾選 **Show the current virtual desktop name**。

桌面名稱需要從 KDE 系統設定（**系統設定 → 工作空間行為 → 虛擬桌面**）修改，而不是在本元件內編輯。若沒有自訂名稱，會顯示 Desktop 1 等預設名稱。

## 產生 .plasmoid 安裝包

~~~bash
sudo apt install zip
bash scripts/build.sh
kpackagetool5 --type Plasma/Applet --install dist/kde-virtual-desktop-notes.plasmoid
~~~

套件儲存於 `dist/kde-virtual-desktop-notes.plasmoid`。如果元件已安裝，請將指令中的 `--install` 改為 `--upgrade`。建議透過 `scripts/install.sh` 安裝，以確保自訂圖示也安裝到使用者的圖示主題。

## 程式碼

~~~text
package/
  metadata.json
  contents/ui/main.qml            # 桌面 ID、桌面名稱、筆記與字體縮放
  contents/images/icon.svg        # 專用 Plasmoid 縮圖
  contents/ui/configGeneral.qml   # 寬度與標題開關
  contents/config/config.qml      # 設定分類
  contents/config/main.xml        # 只存外觀設定
scripts/install.sh
scripts/uninstall.sh
scripts/build.sh
~~~

## 已知限制

- 這個版本針對 KDE Plasma 5 / Qt 5 設計，**尚未驗證 Plasma 6 相容性**。
- 以水平工具列為主要使用環境；垂直工具列可能需要進一步調整。
- 字體有最小大小限制，極長的字串可能會被省略。
- 目前尚未在實體 Plasma 工作階段進行互動測試。

Repository: https://github.com/pulipulichen/kde-virtual-desktop-notes
