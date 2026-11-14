#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
sync_upstream.py - MAS 繁體中文版自動同步與維護管線
--------------------------------------------------
功能：
1. 監控上游原始倉庫 (massgravel/Microsoft-Activation-Scripts) 之 master 分支與最新發布 (Release)。
2. 偵測到新版本或新 commit 時，自動拉取最新程式碼。
3. 自動套用繁體中文對照字典 (translation_map.txt)，保留所有語法結構。
4. 全面執行 Big5 (CP950) 轉碼、PowerShell 內嵌區塊 CP950 解碼修復、OEM 位元組複製修復、ASCII 區塊保護。
5. 執行嚴格靜態安全與相容性驗證（零 BOM、純 CRLF、零 chcp 65001、受保護字串完好）。
6. 自動打包 MAS_AIO.zip，更新 README.md，並支援自動 commit / push / 建立 GitHub Release。
7. 可選：透過 gmail-monitor/.env 發送 LINE 推播通知。
"""

import os
import re
import sys
import json
import shutil
import zipfile
import argparse
import subprocess
import urllib.request
import urllib.error
from datetime import datetime

UPSTREAM_REPO = "massgravel/Microsoft-Activation-Scripts"
UPSTREAM_BRANCH = "master"
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_DIR = os.path.dirname(SCRIPT_DIR)
STATE_FILE = os.path.join(SCRIPT_DIR, "sync-state.json")
MAP_FILE = os.path.join(SCRIPT_DIR, "translation_map.txt")
LINE_ENV_FILE = os.path.join(REPO_DIR, "..", "gmail-monitor", ".env")
NOTIFY_ENABLED = True

TARGET_CMD_FILES = [
    "MAS/All-In-One-Version-KL/MAS_AIO.cmd",
    "MAS/Separate-Files-Version/Activators/HWID_Activation.cmd",
    "MAS/Separate-Files-Version/Activators/Ohook_Activation_AIO.cmd",
    "MAS/Separate-Files-Version/Activators/Online_KMS_Activation.cmd",
    "MAS/Separate-Files-Version/Activators/TSforge_Activation.cmd",
    "MAS/Separate-Files-Version/Change_Office_Edition.cmd",
    "MAS/Separate-Files-Version/Change_Windows_Edition.cmd",
    "MAS/Separate-Files-Version/Check_Activation_Status.cmd",
    "MAS/Separate-Files-Version/Extract_OEM_Folder.cmd",
    "MAS/Separate-Files-Version/Troubleshoot.cmd",
]


def log(msg, level="INFO"):
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] [{level}] {msg}")


def notify_line(message):
    """若本機環境存在 gmail-monitor/.env 則推播 LINE 通知"""
    if not NOTIFY_ENABLED:
        log("[no-notify] 略過推播，內容：\n" + message)
        return False
    if not os.path.isfile(LINE_ENV_FILE):
        return False
    token, uid = None, None
    try:
        with open(LINE_ENV_FILE, "r", encoding="utf-8") as f:
            for raw in f:
                line = raw.strip().lstrip("\ufeff")
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                if k.strip() == "LINE_CHANNEL_ACCESS_TOKEN":
                    token = v.strip().strip('"').strip("'")
                elif k.strip() == "LINE_USER_ID":
                    uid = v.strip().strip('"').strip("'")
    except Exception as e:
        log(f"讀取 LINE 設定失敗: {e}", "WARN")
        return False

    if not token or not uid:
        return False

    try:
        payload = json.dumps({"to": uid, "messages": [{"type": "text", "text": message[:4800]}]}).encode("utf-8")
        req = urllib.request.Request("https://api.line.me/v2/bot/message/push", data=payload, method="POST")
        req.add_header("Authorization", f"Bearer {token}")
        req.add_header("Content-Type", "application/json")
        with urllib.request.urlopen(req, timeout=15) as resp:
            if resp.getcode() == 200:
                log("LINE 推播發送成功")
                return True
    except Exception as e:
        log(f"LINE 推播失敗: {e}", "WARN")
    return False


def load_state():
    if os.path.isfile(STATE_FILE):
        try:
            with open(STATE_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            log(f"載入 sync-state.json 失敗: {e}", "WARN")
    return {
        "upstream_repo": UPSTREAM_REPO,
        "upstream_branch": UPSTREAM_BRANCH,
        "last_synced_sha": "",
        "last_synced_tag": "",
        "last_synced_at": ""
    }


def save_state(state):
    state["last_synced_at"] = datetime.now().isoformat()
    with open(STATE_FILE, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2, ensure_ascii=False)
    log(f"已更新 sync-state.json: SHA={state.get('last_synced_sha')[:7]} Tag={state.get('last_synced_tag')}")


def get_upstream_info():
    """查詢上游最新 Commit SHA、Release Tag 與發布日期"""
    sha = None
    tag = None
    published = None

    # 優先嘗試 git ls-remote / git rev-parse（快速且免 API 限制）
    try:
        out = subprocess.check_output(
            ["git", "ls-remote", f"https://github.com/{UPSTREAM_REPO}.git", f"refs/heads/{UPSTREAM_BRANCH}"],
            stderr=subprocess.DEVNULL, timeout=15
        ).decode("utf-8").strip()
        if out:
            sha = out.split()[0]
    except Exception:
        pass

    if not sha:
        try:
            url = f"https://api.github.com/repos/{UPSTREAM_REPO}/commits/{UPSTREAM_BRANCH}"
            req = urllib.request.Request(url, headers={"User-Agent": "MAS-Sync-Bot"})
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                sha = data.get("sha")
        except Exception as e:
            log(f"取得上游 Commit SHA 失敗: {e}", "ERROR")

    try:
        url = f"https://api.github.com/repos/{UPSTREAM_REPO}/releases/latest"
        req = urllib.request.Request(url, headers={"User-Agent": "MAS-Sync-Bot"})
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            tag = data.get("tag_name")
            published = (data.get("published_at") or "")[:10] or None
    except Exception:
        pass

    return sha, tag, published


def load_map():
    translation_map = {}
    if not os.path.isfile(MAP_FILE):
        log(f"找不到字典檔案: {MAP_FILE}", "ERROR")
        return translation_map

    with open(MAP_FILE, "r", encoding="utf-8") as f:
        for line in f:
            t = line.strip()
            if not t or t.startswith("#"):
                continue
            if "\t" in line:
                k, v = line.split("\t", 1)
                translation_map[k.strip()] = v.rstrip("\r\n")
    log(f"已載入繁中對照字典: 共 {len(translation_map)} 條項目")
    return translation_map


_WS = re.compile(r"\s+")


def build_norm_index(translation_map):
    """建立「空白正規化」索引，作為精確比對失敗時的後備。

    為什麼需要：上游同一句提示在不同選單裡縮排/對齊空白數不同（例如
    `echo [0] Go Back` 與 `echo [0]  Go Back`），精確比對會漏翻，導致已經
    翻好的行被還原成英文。此處只收「正規化後中文譯文也相同」的鍵，
    譯文正規化後不同者視為有歧義，一律不採用，寧可漏翻也不誤翻。
    """
    buckets = {}
    for k, v in translation_map.items():
        buckets.setdefault(_WS.sub(" ", k), []).append((k, v))

    index = {}
    ambiguous = []
    for nk, items in buckets.items():
        norm_vals = {_WS.sub(" ", v) for _, v in items}
        if len(norm_vals) > 1:
            ambiguous.append(nk)
            continue
        # 同組譯文只差空白時，取空白最少（最緊湊）的那一筆當代表
        items.sort(key=lambda kv: len(kv[1]))
        index[nk] = items[0][1]

    if ambiguous:
        log(f"空白正規化索引：{len(ambiguous)} 組具歧義已跳過（不影響精確比對）", "WARN")
    return index


def fetch_upstream_pristine(rel_path, sha=None):
    """從 upstream 提取原始英文內容。

    sha 有給時，只有在本地 upstream/master 正好等於該 SHA 才用 git show，
    否則改用 raw.githubusercontent 指定 SHA 下載 —— 避免 fetch 失敗時拿舊
    ref 的內容去產生新版本，卻把 state 記成新 SHA。
    """
    if sha:
        try:
            local_ref = subprocess.check_output(
                ["git", "-C", REPO_DIR, "rev-parse", "upstream/master"],
                stderr=subprocess.DEVNULL
            ).decode("utf-8").strip()
        except Exception:
            local_ref = ""
        if local_ref == sha:
            try:
                return subprocess.check_output(
                    ["git", "-C", REPO_DIR, "show", f"{sha}:{rel_path}"],
                    stderr=subprocess.DEVNULL
                ).decode("utf-8")
            except Exception as e:
                log(f"git show {sha[:7]}:{rel_path} 失敗: {e}", "WARN")
        else:
            log(f"本地 upstream/master ({local_ref[:7] or 'None'}) != 目標 {sha[:7]}，改用 raw 下載", "WARN")

    ref = sha or f"refs/heads/{UPSTREAM_BRANCH}"
    url = f"https://raw.githubusercontent.com/{UPSTREAM_REPO}/{ref}/{rel_path}"
    req = urllib.request.Request(url, headers={"User-Agent": "MAS-Sync-Bot"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return resp.read().decode("utf-8")


_HAS_WORDS = re.compile(r"[A-Za-z]{3,}")
_UI_PREFIXES = ("echo ", "echo:", "call :dk_color", "choice ", "title ")
_NOISE_CHARS = (">", "<", "|", "&")
_TWO_WORDS = re.compile(r"[A-Za-z]{3,}[^A-Za-z]{1,3}[A-Za-z]{3,}")


def looks_like_ui_text(trimmed):
    """判斷是否為「值得補翻譯」的英文使用者訊息。

    用意是讓 untranslated_new.log 保持可讀：`echo:`、分隔線、純路徑、
    含底線的識別字（視窗標題）都不算。
    """
    for p in _UI_PREFIXES:
        if trimmed.startswith(p):
            body = trimmed[len(p):].strip()
            break
    else:
        return False
    if not body or "_" in body:
        return False
    return bool(_TWO_WORDS.search(body))


def protected_line_ranges(lines):
    """找出「不可翻譯」的行區間（1-based，含頭尾）。

    判斷依據是程式自己寫檔的方式，不是靠猜：
    只要某一行用 `[System.Text.Encoding]::ASCII` 把 heredoc 區塊寫成檔案
    （例如 `:_extracttask:` → Activation_task.cmd、Extract_OEM_Folder 的
    `:xxx_setup:` → SetupComplete.cmd），那區塊內的文字就不能出現中文，
    否則 .NET 會把 Big5 位元組換成 `?`，產生一份壞掉的排程工作檔。
    """
    tags = set()
    for line in lines:
        if "Encoding]::ASCII" in line:
            for m in re.finditer(r":\\?([A-Za-z0-9_]+)\\?:", line):
                tags.add(m.group(1))
    # Extract_OEM_Folder 用 :%~1: 動態挑區塊，靜態偵測不到，改用命名規則補上
    for line in lines:
        m = re.match(r"^:([A-Za-z0-9_]+_setup):\s*$", line)
        if m:
            tags.add(m.group(1))

    if not tags:
        return set(), tags

    protected = set()
    for tag in tags:
        marker = re.compile(rf"^:{re.escape(tag)}:\s*$")
        starts = [i for i, l in enumerate(lines) if marker.match(l)]
        if len(starts) >= 2:
            for a, b in zip(starts, starts[1:]):
                protected.update(range(a + 1, b + 2))  # 1-based，含收尾標記
    return protected, tags


def translate_content(text, rel_path, translation_map, norm_index=None):
    """套用繁中翻譯、修復解碼與編碼轉換"""
    norm_index = norm_index or {}
    lines = text.splitlines()
    translated_lines = []
    unmapped_lines = []
    protected, _tags = protected_line_ranges(lines)
    if _tags:
        log(f"[{rel_path}] 受保護區塊（ASCII 寫出）: {', '.join(sorted(':' + t + ':' for t in _tags))}", "INFO")

    is_aio = rel_path.endswith("MAS_AIO.cmd")

    for idx, line in enumerate(lines):
        trimmed = line.strip()

        # 1. 移除 chcp 65001 >nul
        if trimmed == "chcp 65001 >nul":
            continue

        # 2. MAS_AIO.cmd L619 位元組陣列安全複製
        if is_aio and "$OEM$\\$$\\Setup\\Scripts\\MAS_AIO.cmd" in line and "WriteAllText" in line:
            translated_lines.append(
                '%psc% "$r=[Text.Encoding]::ASCII.GetBytes(\'@::RANDOM-\' + [Guid]::NewGuid().Guid + [Environment]::NewLine); [io.file]::WriteAllBytes(\'!_pdesk!\\$OEM$\\$$\\Setup\\Scripts\\MAS_AIO.cmd\', $r + [IO.File]::ReadAllBytes(\'!_batp!\'))"'
            )
            continue

        # 3. 字典比對替換：先精確比對，再退回空白正規化比對
        mapped_val = None
        if (idx + 1) not in protected:
            if trimmed in translation_map:
                mapped_val = translation_map[trimmed]
            elif trimmed in norm_index:
                mapped_val = norm_index[trimmed]

        if mapped_val is not None:
            # 保留原行開頭縮排
            indent = line[: len(line) - len(line.lstrip())]
            new_line = indent + mapped_val
        else:
            new_line = line
            # 偵測是否為未翻譯的全新英文使用者訊息（供人工補字典）
            if (idx + 1) not in protected and not any(c in trimmed for c in _NOISE_CHARS) and looks_like_ui_text(trimmed):
                unmapped_lines.append((idx + 1, trimmed))

        # 4. 修復 PowerShell heredoc 讀取帶 Big5 (CP950) 解碼
        if "[IO.File]::ReadAllText('!_batp!')" in new_line:
            new_line = new_line.replace(
                "[IO.File]::ReadAllText('!_batp!')",
                "[IO.File]::ReadAllText('!_batp!', [Text.Encoding]::GetEncoding(950))"
            )

        translated_lines.append(new_line)

    # 確保純 CRLF 與 Big5 編碼
    body = "\r\n".join(translated_lines) + "\r\n"
    encoded_bytes = body.encode("cp950")
    return encoded_bytes, unmapped_lines


def validate_all_files():
    """執行完整靜態安全驗證"""
    log("開始執行靜態驗證...")
    all_ok = True

    for rel in TARGET_CMD_FILES:
        full_path = os.path.join(REPO_DIR, rel)
        if not os.path.isfile(full_path):
            log(f"缺少檔案: {rel}", "ERROR")
            all_ok = False
            continue

        with open(full_path, "rb") as f:
            raw = f.read()

        # Check 1: No BOM
        if raw.startswith(b"\xef\xbb\xbf") or raw.startswith(b"\xff\xfe"):
            log(f"驗證失敗: {rel} 包含 BOM!", "ERROR")
            all_ok = False

        # Check 2: No Lone LF
        lone_lf = 0
        for i in range(len(raw)):
            if raw[i] == 10:
                if i == 0 or raw[i - 1] != 13:
                    lone_lf += 1
        if lone_lf > 0:
            log(f"驗證失敗: {rel} 包含 {lone_lf} 個孤立 LF!", "ERROR")
            all_ok = False

        # Check 3: Big5 decode and no chcp 65001
        try:
            text = raw.decode("cp950")
        except Exception as e:
            log(f"驗證失敗: {rel} 無法以 Big5 解碼: {e}", "ERROR")
            all_ok = False
            continue

        if "chcp 65001" in text:
            log(f"驗證失敗: {rel} 仍包含 chcp 65001!", "ERROR")
            all_ok = False

        # Check 4: Protected strings
        if rel.endswith("MAS_AIO.cmd"):
            if 'Write-Host "Target Edition : $candidate"' not in text:
                log(f"驗證失敗: {rel} 受保護字串 'Target Edition' 缺失!", "ERROR")
                all_ok = False

    if all_ok:
        log("靜態安全驗證全數通過 (10/10)")
    return all_ok


def package_release_zip():
    """打包 MAS_AIO.zip"""
    src = os.path.join(REPO_DIR, "MAS", "All-In-One-Version-KL", "MAS_AIO.cmd")
    dst = os.path.join(SCRIPT_DIR, "MAS_AIO.zip")
    with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.write(src, arcname="MAS_AIO.cmd")
    log(f"已建立發布壓縮檔: {dst} ({os.path.getsize(dst)} bytes)")
    return dst


def update_readme(upstream_tag, published_date=None):
    """更新 README.md 的版本號與上游發布日期。

    刻意保留行尾空白：README 的 `最新版本：x.y  ` 行尾兩個空白是 Markdown
    強制換行語法，用 str.rstrip 後重寫會讓下一行黏上來。
    """
    readme_path = os.path.join(REPO_DIR, "README.md")
    if not os.path.isfile(readme_path):
        return

    with open(readme_path, "r", encoding="utf-8") as f:
        text = f.read()

    def replace_value(line, prefix, value):
        rest = line[len(prefix):]
        trailing = rest[len(rest.rstrip()):]
        return prefix + value + trailing

    changed = False
    lines = text.splitlines()
    for i, line in enumerate(lines):
        if line.startswith("最新版本：") and upstream_tag:
            new = replace_value(line, "最新版本：", upstream_tag)
            changed |= new != line
            lines[i] = new
        elif line.startswith("發布日期：") and published_date:
            new = replace_value(line, "發布日期：", published_date)
            changed |= new != line
            lines[i] = new

    if not changed:
        log("README.md 版本資訊無變動，未改寫。")
        return

    with open(readme_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    log(f"已更新 README.md (版本: {upstream_tag}, 日期: {published_date})")


def run_sync(force=False, create_release=False, do_commit=False):
    log("=== 啟動 MAS 上游自動同步監控 ===")
    state = load_state()
    last_sha = state.get("last_synced_sha", "")
    last_tag = state.get("last_synced_tag", "")

    current_sha, current_tag, current_published = get_upstream_info()
    if not current_sha:
        log("無法取得上游資訊，結束本次執行。", "ERROR")
        return False

    log(f"本機記錄 SHA: {last_sha[:7] if last_sha else 'None'} (Tag: {last_tag})")
    log(f"上游最新 SHA: {current_sha[:7]} (Tag: {current_tag}, 發布: {current_published or '?'})")

    if not force and current_sha == last_sha:
        log("上游無新更新，本機已是最新狀態，無需同步。")
        return True

    log(f"偵測到上游新異動！開始執行繁中化同步作業 (新 SHA: {current_sha[:7]})...")

    # 1. 確保 upstream remote 最末 commit 已 fetch
    try:
        subprocess.call(["git", "-C", REPO_DIR, "fetch", "upstream"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass
    try:
        local_ref = subprocess.check_output(
            ["git", "-C", REPO_DIR, "rev-parse", "upstream/master"], stderr=subprocess.DEVNULL
        ).decode("utf-8").strip()
    except Exception:
        local_ref = ""
    if local_ref != current_sha:
        log(f"本地 upstream/master ({local_ref[:7] or 'None'}) 尚未追上 {current_sha[:7]}；"
            f"將改由 raw.githubusercontent 逐檔下載指定 SHA 的內容。", "WARN")

    # 2. 載入對照字典
    translation_map = load_map()
    if not translation_map:
        log("字典為空，終止同步以防覆蓋程式碼。", "ERROR")
        return False
    norm_index = build_norm_index(translation_map)

    # 3. 處理每個目標檔案
    all_unmapped = []
    for rel in TARGET_CMD_FILES:
        log(f"處理: {rel}")
        pristine_text = fetch_upstream_pristine(rel, current_sha)
        encoded_bytes, unmapped = translate_content(pristine_text, rel, translation_map, norm_index)
        if unmapped:
            all_unmapped.extend([(rel, line_no, text) for line_no, text in unmapped])

        target_path = os.path.join(REPO_DIR, rel)
        os.makedirs(os.path.dirname(target_path), exist_ok=True)
        with open(target_path, "wb") as f:
            f.write(encoded_bytes)

    # 處理 _ReadMe.txt（同一份字典，最後幾條是這個檔案的專屬條目）
    readme_txt_rel = "MAS/Separate-Files-Version/Activators/_ReadMe.txt"
    try:
        txt = fetch_upstream_pristine(readme_txt_rel, current_sha)
        enc_b, txt_unmapped = translate_content(txt, readme_txt_rel, translation_map, norm_index)
        all_unmapped.extend([(readme_txt_rel, n, t) for n, t in txt_unmapped])
        with open(os.path.join(REPO_DIR, readme_txt_rel), "wb") as f:
            f.write(enc_b)
    except Exception as e:
        log(f"處理 {readme_txt_rel} 失敗: {e}", "WARN")


    # 4. 靜態驗證
    if not validate_all_files():
        log("同步後驗證失敗！中止提交流程，請檢視檔案。", "ERROR")
        notify_line(f"【MAS 繁中同步失敗】上游更新至 {current_sha[:7]}，但靜態驗證未通過，請至電腦檢查！")
        return False

    # 5. 更新 README 與打包 ZIP
    update_readme(current_tag or last_tag, current_published)
    zip_path = package_release_zip()

    # 6. 記錄未翻譯新行（去重，只留真正需要補字典的英文訊息）
    unmapped_log = os.path.join(SCRIPT_DIR, "untranslated_new.log")
    unique_unmapped = []
    seen = set()
    for rel, line_no, text in all_unmapped:
        key = _WS.sub(" ", text)
        if key in seen:
            continue
        seen.add(key)
        unique_unmapped.append((rel, line_no, text))
    if unique_unmapped:
        with open(unmapped_log, "w", encoding="utf-8") as f:
            for rel, line_no, text in unique_unmapped:
                f.write(f"{rel} L{line_no}: {text}\n")
        log(f"發現 {len(unique_unmapped)} 條上游新文字未在字典中，已記錄至 untranslated_new.log", "WARN")
    elif os.path.exists(unmapped_log):
        os.remove(unmapped_log)

    # 7. 更新 state
    state["last_synced_sha"] = current_sha
    if current_tag:
        state["last_synced_tag"] = current_tag
    save_state(state)

    # 8. Git Commit & Push (若開啟)
    if do_commit:
        log("執行 Git Commit & Push...")
        try:
            # 指名路徑，不用 -A：sync/ 內的 zip 與日誌是產物，不進版控
            subprocess.check_call(["git", "-C", REPO_DIR, "add", "MAS", "README.md", "sync/sync_upstream.py",
                                   "sync/translation_map.txt", "sync/sync-state.json"])
            commit_msg = f"chore(sync): sync with upstream {current_sha[:7]}"
            if current_tag and current_tag != last_tag:
                commit_msg += f" (MAS {current_tag})"
            subprocess.check_call(["git", "-C", REPO_DIR, "commit", "-m", commit_msg])
            subprocess.check_call(["git", "-C", REPO_DIR, "push", "origin", "master"])
            log("Git 推送完成。")
        except Exception as e:
            log(f"Git 提交或推送失敗: {e}", "ERROR")

    # 9. 建立 GitHub Release (若為新 Tag 且允許)
    if create_release and current_tag and current_tag != last_tag:
        log(f"偵測到新版本 Tag: {current_tag}，建立 GitHub Release...")
        tag_name = f"v{current_tag}-chts"
        cmd_asset = os.path.join(REPO_DIR, "MAS", "All-In-One-Version-KL", "MAS_AIO.cmd")
        try:
            subprocess.check_call([
                "gh", "release", "create", tag_name,
                cmd_asset, zip_path,
                "-R", f"pkjoe88/Microsoft-Activation-Script-chts",
                "--title", f"Microsoft Activation Scripts v{current_tag} 繁體中文版",
                "--notes", f"同步上游 MAS v{current_tag} (Commit {current_sha[:7]})。\n\n採用 Big5 (CP950) 編碼，100% 原生相容 Windows 7 / 8 / 10 / 11 繁體中文環境。"
            ])
            log(f"GitHub Release {tag_name} 建立完成！")
        except Exception as e:
            log(f"建立 Release 失敗: {e}", "ERROR")

    notify_msg = (f"【MAS 繁中同步成功】\n上游已同步至 Commit {current_sha[:7]}\n"
                  f"版本：{current_tag or last_tag}\n驗證結果：全部通過")
    if unique_unmapped:
        notify_msg += f"\n待補翻譯：{len(unique_unmapped)} 條（詳見 sync/untranslated_new.log）"
    notify_line(notify_msg)
    log("=== MAS 上游同步管線順利完成 ===")
    return True


def run_monitor():
    """只監控不寫檔：偵測到上游變動就推播通知，供排程工作每日呼叫。"""
    log("=== MAS 上游監控檢查 ===")
    state = load_state()
    last_sha = state.get("last_synced_sha", "")
    last_tag = state.get("last_synced_tag", "")

    current_sha, current_tag, current_published = get_upstream_info()
    if not current_sha:
        log("無法取得上游資訊（網路或 GitHub API 異常）。", "ERROR")
        return 3

    if current_sha == last_sha:
        log(f"上游無更新（維持 {current_sha[:7]} / MAS {last_tag}），不發通知。")
        return 0

    log(f"偵測到上游更新！{last_sha[:7] or 'None'} -> {current_sha[:7]} (MAS {current_tag})", "WARN")
    changed = []
    for rel in TARGET_CMD_FILES:
        try:
            new_text = fetch_upstream_pristine(rel, current_sha)
        except Exception as e:
            log(f"下載 {rel} 失敗: {e}", "WARN")
            continue
        try:
            old_text = subprocess.check_output(
                ["git", "-C", REPO_DIR, "show", f"{last_sha}:{rel}"], stderr=subprocess.DEVNULL
            ).decode("utf-8") if last_sha else ""
        except Exception:
            old_text = ""
        if new_text != old_text:
            changed.append(rel)

    msg = [f"【MAS 上游有新版本】",
           f"目前同步基準：{last_sha[:7] or 'None'} (MAS {last_tag or '?'})",
           f"上游最新：{current_sha[:7]} (MAS {current_tag or '?'}"
           + (f", 發布 {current_published}" if current_published else "") + ")"]
    if changed:
        msg.append("")
        msg.append("有變動的檔案：")
        msg.extend(f"-{rel}" for rel in changed)
    msg.append("")
    msg.append("請執行同步：python sync\\sync_upstream.py --commit --release")
    notify_line("\n".join(msg))
    for line in msg:
        log(line)
    return 2


if __name__ == "__main__":
    # 主控台是 cp950 時，遇到 Big5 沒有的字元（例如 '-'）print 會直接丟
    # UnicodeEncodeError 中斷整個排程。改成取代字元，寧可顯示 '?' 也不要失敗。
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(errors="replace")
        except Exception:
            pass

    parser = argparse.ArgumentParser(description="MAS 繁體中文版上游同步工具")
    parser.add_argument("--force", action="store_true", help="強制重新套用同步（忽略 SHA 比對）")
    parser.add_argument("--check-only", action="store_true", help="僅檢查上游是否有新更新，不執行同步")
    parser.add_argument("--monitor", action="store_true", help="排程用：偵測到更新才推播通知（不改動任何檔案）")
    parser.add_argument("--no-notify", action="store_true", help="不實際發送 LINE 推播（僅印出內容，測試用）")
    parser.add_argument("--commit", action="store_true", help="同步完成後自動執行 git commit + push")
    parser.add_argument("--release", action="store_true", help="若上游有新 Tag 則自動建立 GitHub Release")
    args = parser.parse_args()

    if args.no_notify:
        NOTIFY_ENABLED = False

    if args.monitor:
        sys.exit(run_monitor())

    if args.check_only:
        sha, tag, published = get_upstream_info()
        st = load_state()
        print(f"Current recorded SHA: {st.get('last_synced_sha')[:7]}")
        print(f"Upstream latest SHA : {sha[:7] if sha else 'Unknown'}")
        print(f"Upstream latest Tag : {tag}  (published {published})")
        sys.exit(0 if (sha and sha == st.get("last_synced_sha")) else 1)

    success = run_sync(force=args.force, create_release=args.release, do_commit=args.commit)
    sys.exit(0 if success else 1)
