<p align="center"><img src="https://massgrave.dev/img/logo_small.png" alt="MAS Logo"></p>

<h1 align="center">Microsoft  Activation  Scripts (MAS)</h1>

<p align="center">開源的 Windows 與 Office 啟用工具，支援 HWID、Ohook、TSforge、Online KMS 等啟用方式，並內建進階疑難排解。本版本為繁體中文版。</p>

<hr>
  
## 如何啟用 Windows / Office / 延伸安全性更新 (ESU)？

### 方法 1 - PowerShell ❤️

1. 點選**開始功能表**，輸入 `PowerShell` 並開啟。

2. 複製並貼上下方程式碼，然後按 **Enter。**  
   - 適用於 **Windows 8.1、10 和 11**：
     ```
     irm https://get.activated.win | iex
     ```
	 若上方網址被擋（ISP/DNS），改試這個（需要已更新的 Windows 10 或 11）：  
	 ```
	 iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)
	 ```
	- **腳本無法啟動？請改用下方的方法 2。**

3. 在出現的選單中，輸入**綠色**選項對應的數字。

---

### 方法 2 - 傳統方式（Windows Vista 及之後版本）

1.   下載腳本：
      *   [**MAS_AIO.cmd**](https://dev.azure.com/massgrave/Microsoft-Activation-Scripts/_apis/git/repositories/Microsoft-Activation-Scripts/items?path=/MAS/All-In-One-Version-KL/MAS_AIO.cmd&download=true)（直接下載腳本）
      *   [**MAS_AIO.zip**](https://dev.azure.com/massgrave/Microsoft-Activation-Scripts/_apis/git/repositories/Microsoft-Activation-Scripts/items?$format=zip)（若直接下載腳本被瀏覽器擋下）
2.   執行 `MAS_AIO.cmd` 檔案。
3.   在出現的選單中，輸入**綠色**選項對應的數字。

---

> [!TIP]
> - 部分 ISP／DNS 供應商會封鎖我們的網域。可以在瀏覽器啟用 [DNS-over-HTTPS (DoH)](https://developers.cloudflare.com/1.1.1.1/encryption/dns-over-https/encrypted-dns-browsers/) 繞過封鎖。
> - **遇到問題**？請造訪[疑難排解頁面](https://massgrave.dev/troubleshoot)，或到 [GitHub](https://github.com/massgravel/Microsoft-Activation-Scripts/issues) 回報。

> [!NOTE]
>
> - PowerShell 的 `irm` 命令會從指定網址下載腳本，`iex` 命令則會執行它。
> - 執行命令前務必確認網址正確；手動下載檔案時也請確認來源可信。
> - 請提防第三方竄改 PowerShell 命令中的網址、散布偽裝成 MAS 的惡意軟體。

### 本繁體中文版注意事項

- 腳本以繁體中文 Windows 預設的 **Big5 (CP950)** 編碼儲存，不需切換 `chcp 65001`，徹底避開 Windows 批次解析器在 UTF-8 下的解析錯誤，並天然相容 Windows 7、8、10、11 繁體中文環境。
- 非繁體中文系統（如英文版 Windows 且未將「非 Unicode 程式語言」設為繁體中文）可能顯示亂碼，請在繁體中文 Windows 環境下使用。
- 由排程工作執行的 `Activation_task.cmd` 與特定內嵌腳本維持英文，以確保系統排程在任何字碼頁環境下都能穩定運行。

---

<div align="center">
	
### 首頁 - [https://massgrave.dev/](https://massgrave.dev/)
  
[![1.1]][1]
[![1.2]][2]
[![1.3]][3]
[![1.4]][4]
[![1.5]][5]
[![1.6]][6]
[![1.7]][7]

[1.1]: https://massgrave.dev/img/logo_discord.png (Chat with us without signup)
[1.2]: https://massgrave.dev/img/logo_reddit.png (Reddit)
[1.3]: https://massgrave.dev/img/logo_bluesky.png (Bluesky)
[1.4]: https://massgrave.dev/img/logo_x.png (Twitter)

[1.5]: https://massgrave.dev/img/logo_github.png (GitHub)
[1.6]: https://massgrave.dev/img/logo_azuredevops.png (AzureDevOps)
[1.7]: https://massgrave.dev/img/logo_gitea.png (Self-hosted Git)

[1]: https://discord.gg/j2yFsV5ZVC
[2]: https://www.reddit.com/r/MAS_Activator
[3]: https://bsky.app/profile/massgrave.dev
[4]: https://twitter.com/massgravel
[5]: https://github.com/massgravel/Microsoft-Activation-Scripts
[6]: https://dev.azure.com/massgrave/_git/Microsoft-Activation-Scripts
[7]: https://git.activated.win/Microsoft-Activation-Scripts

---

最新版本：3.14  
發布日期：2026-11-11
