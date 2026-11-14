# 上游同步與監控（sync/）

本資料夾放的是「把上游官方英文版重新變成繁中版」的**唯一**管線。
網路上任何一次手動改檔都會在下次同步時被覆蓋，要改翻譯請改 `translation_map.txt`。

## 為什麼要有這支

上游 [massgravel/Microsoft-Activation-Scripts](https://github.com/massgravel/Microsoft-Activation-Scripts)
每次改版都會動到同幾支 `.cmd`。若靠人工比對，很容易出現「翻好了但漏掉幾行」或
「新版某段沒翻到」，而且無法證明沒有漏。這裡改成 **字典驅動的重建**：

```
上游原文（英文）  +  translation_map.txt  →  繁中 Big5 檔
```

好處是結果可重現、可驗證：對同一個上游 commit 重跑，輸出必須與已提交的檔案
**逐位元組相同**。目前基準 `6cfd6f4`（MAS 3.14）已通過此檢查。

## 用法

```bat
:: 只檢查有沒有新版（0 = 最新，1 = 有新版）
python sync\sync_upstream.py --check-only

:: 給排程用：有新版才推播 LINE，不改任何檔案（0 = 無更新，2 = 有更新）
python sync\sync_upstream.py --monitor

:: 實際同步（重建 + 驗證 + 打包 zip）
python sync\sync_upstream.py

:: 同步並提交、推上 GitHub；上游有新 tag 時順便建 Release
python sync\sync_upstream.py --commit --release

:: 忽略 SHA 比對，強制重建一次
python sync\sync_upstream.py --force --no-notify
```

`--no-notify` 只印出推播內容、不實際發送，測試用。

## 排程監控

| 檔案 | 用途 |
|---|---|
| `install_task.bat` | 註冊每日 09:30 的 `MAS-ZhSyncMonitor` 工作（只監控、不自動改檔） |
| `uninstall_task.bat` | 移除該工作 |
| `run_check.bat` | 手動立即檢查一次，視窗保留結果 |

偵測到上游更新時會發一則 LINE（憑證沿用 `..\gmail-monitor\.env`），內容包含新
commit／版本與**有變動的檔案清單**。

> 刻意**不**讓排程自動 commit：新版本幾乎一定會夾帶新英文句子，那些需要人工翻。
> 若自動推上去，公開的「繁體中文版」會悄悄混入英文，反而比落後一版更糟。
> 接到通知後再跑 `--commit --release` 即可。

## 翻譯規則（改字典前先看）

1. **只翻使用者看得到的字**：`echo`、`call :dk_color`、`title`、`choice`、
   `CONOUT`、`Write-Host`。註解與程式邏輯不動。
2. **空白正規化後備比對**：上游同一句話在不同選單的對齊空白數不一樣
   （`echo [0] Go Back` vs `echo [0]  Go Back`），只做精確比對會漏翻，
   導致已翻好的行被還原成英文。後備索引只收「正規化後譯文相同」的鍵，
   有歧義的一律不採用——寧可漏翻，不可誤翻。
3. **ASCII 寫出區塊不翻**：凡是用 `[System.Text.Encoding]::ASCII` 寫成檔案的
   heredoc 區塊（`:_extracttask:` → `Activation_task.cmd`、Extract_OEM_Folder 的
   `:xxx_setup:` → `SetupComplete.cmd`），內容一律保持英文。原因：ASCII 編碼會把
   Big5 位元組換成 `?`，產生一份壞掉的排程工作檔。
4. **PowerShell heredoc 一律明確 CP950 解碼**：`[IO.File]::ReadAllText('!_batp!')`
   在 .NET 預設按 UTF-8 讀，Big5 中文會變 `?`。管線會自動補上
   `[IO.File]::ReadAllText('!_batp!', [Text.Encoding]::GetEncoding(950))`。
5. **編碼固定 Big5 (CP950)、CRLF、無 BOM、無 `chcp 65001`**：
   UTF-8 + `chcp 65001` 會讓 cmd.exe 出現機率性的解析錯誤
   （`'[6]' is not recognized`），Big5 是繁體中文 Windows 的原生路徑。

## 未翻譯清單

`untranslated_new.log` 會列出「看起來是使用者訊息、但字典沒有」的行，
是下次補翻譯的工作清單。它會被 `.gitignore` 排除，屬臨時產物。

## 已知限制

- 字典是**整行比對**（含 `echo` 等前綴），不是字串片段替換。上游若把一句話
  改寫，舊條目會失效並出現在 `untranslated_new.log`，需人工補。
- 排程工作檔（`Activation_task.cmd`）維持英文，這是刻意的。
- 非繁體中文 Windows（未把「非 Unicode 程式語言」設為繁中）會顯示亂碼。
