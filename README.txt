虛擬桌面臨時備忘錄 — KDE Plasma 5 試作版

安裝：
    kpackagetool5 --type Plasma/Applet -i kde-virtual-desktop-notes.plasmoid
如已有舊版：
    kpackagetool5 --type Plasma/Applet -u kde-virtual-desktop-notes.plasmoid
移除：
    kpackagetool5 --type Plasma/Applet -r org.pulipuli.virtualdesktopnotes

接著右鍵底部工具列 → 新增元件 → 搜尋「虛擬桌面臨時備忘錄」
拖曳到時鐘左側，點擊文字可編輯兩行。每個 Virtual Desktop 文字獨立。
文字只暫存於 plasmashell 記憶體；重啟 Plasma 或重開機都會清空。

這是針對 Kubuntu 24.04 預設 Plasma 5.27 撰寫的試作版本；
尚未在使用者實機測試，若有載入錯誤請檢查：
    plasmashell --version
    journalctl --user -b | grep -Ei 'virtualdesktopnotes|taskmanager|qml'
