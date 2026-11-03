# KDE Virtual Desktop Notes（虛擬桌面臨時備忘錄）

A lightweight KDE Plasma panel widget that displays **two editable lines of notes for each virtual desktop**, with a configurable width in the QML source. Notes are kept in memory and automatically cleared when Plasma restarts or the computer reboots.

這是一個放在 **KDE Plasma 工具列（Panel）**上的臨時備忘錄元件。切換不同虛擬桌面時，工具列會顯示該桌面自己的兩行文字，適合用來標記工作區的用途或待辦事項。

## 功能特色

- **每個虛擬桌面獨立兩行文字**：切換桌面時，自動切換顯示的備忘錄內容。
- **直接點擊編輯**：點擊工具列上的文字，即可在彈出介面修改兩行內容。
- **只存於記憶體**：不寫入設定檔；重新啟動 Plasma 或電腦後，文字自動清空。
- **簡潔的工具列外觀**：文字水平、垂直置中，預設寬度 205 px、字體 16 px。
- **可從原始碼調整寬度、字體大小**：目前須修改 QML 並重新安裝，**尚未提供介面上的寬度調整控制項**。

## 支援環境

這份 **v0.1 試作版**是以 **Kubuntu 24.04 預設的 KDE Plasma 5.27** 為目標，使用 `kpackagetool5` 安裝，尚未經實機驗證。**KDE Plasma 6 尚未確認相容**，請勿直接假設本套件能在 Plasma 6 上使用。

先查看版本：

```bash
plasmashell --version
command -v kpackagetool5
```

## 安裝

1. 下載儲存庫根目錄的 [kde-virtual-desktop-notes.plasmoid](./kde-virtual-desktop-notes.plasmoid)，或在終端機執行：

   ```bash
   curl -fL -O https://raw.githubusercontent.com/pulipulichen/kde-virtual-desktop-notes/main/kde-virtual-desktop-notes.plasmoid
   ```

2. 安裝 Plasma 小工具（一般使用者即可，**不需要 sudo**）：

   ```bash
   kpackagetool5 --type Plasma/Applet -i kde-virtual-desktop-notes.plasmoid
   ```

3. 在 KDE 桌面的工具列按右鍵，進入**編輯模式**，選擇**新增元件（Add Widgets）**。
4. 搜尋 **「虛擬桌面臨時備忘錄」**或 **Virtual Desktop Notes**，將元件加入工具列（例如放在時鐘旁）。
5. 點擊元件，輸入第一行與第二行；切換虛擬桌面，即可分別編輯各桌面的內容。

> 初次安裝若未立即出現在元件清單，可以登出後重新登入 Plasma 工作階段再試。

## 更新

下載最新套件後，使用 `-u` 更新已安裝的版本：

```bash
curl -fL -O https://raw.githubusercontent.com/pulipulichen/kde-virtual-desktop-notes/main/kde-virtual-desktop-notes.plasmoid
kpackagetool5 --type Plasma/Applet -u kde-virtual-desktop-notes.plasmoid
```

若更新後仍顯示舊版介面，可重新登入 Plasma 工作階段。**重新啟動 Plasma 也會清空目前的備忘錄內容。**

## 修改寬度與字體

目前沒有圖形化設定選項。專案的 [`contents/ui/main.qml`](./contents/ui/main.qml) 定義了：

```qml
property int displayWidth: 205
property int displayFontSize: 16
```

將 `205` 改成想要的寬度（像素），例如 `280`；也可改 `16` 調整文字大小。修改後，可從下載的專案根目錄重新打包：

```bash
zip -r kde-virtual-desktop-notes-custom.plasmoid metadata.desktop contents README.txt
kpackagetool5 --type Plasma/Applet -u kde-virtual-desktop-notes-custom.plasmoid
```

> 這會修改元件的預設顯示大小，不會讓寬度變成可直接拖曳的互動設定。

## 移除

先從工具列移除元件，再執行：

```bash
kpackagetool5 --type Plasma/Applet -r org.pulipuli.virtualdesktopnotes
```

## 排除問題

若元件無法載入，請檢查 Plasma 版本與使用者工作階段的 QML 記錄：

```bash
plasmashell --version
journalctl --user -b | grep -Ei 'virtualdesktopnotes|pager|qml'
```

## 專案結構

```text
├── README.md
├── README.txt
├── LICENSE
├── metadata.desktop
├── contents/
│   └── ui/
│       └── main.qml
└── kde-virtual-desktop-notes.plasmoid
```

## 授權

[MIT License](./LICENSE)。
