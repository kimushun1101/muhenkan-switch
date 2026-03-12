#!/usr/bin/env python3
"""Download kanata binary for development."""
import os, sys, platform, zipfile, urllib.request, shutil

VERSION = "v1.11.0"
ext = ".exe" if os.name == "nt" else ""
os.makedirs("./bin", exist_ok=True)
dest = f"./bin/kanata_cmd_allowed{ext}"

if os.path.exists(dest):
    print("[fetch-kanata] kanata_cmd_allowed already exists -- skipping.")
    sys.exit(0)

system = platform.system()
machine = platform.machine()

if system == "Linux":
    asset = "linux-binaries-x64.zip"
    binary = "kanata_linux_cmd_allowed_x64"
elif system == "Darwin":
    if machine == "arm64":
        asset = "macos-binaries-arm64.zip"
        binary = "kanata_macos_cmd_allowed_arm64"
    else:
        asset = "macos-binaries-x64.zip"
        binary = "kanata_macos_cmd_allowed_x64"
elif system == "Windows":
    asset = "windows-binaries-x64.zip"
    binary = "kanata_windows_tty_winIOv2_cmd_allowed_x64.exe"
else:
    print(f"[fetch-kanata] Unsupported OS: {system}")
    sys.exit(1)

url = f"https://github.com/jtroo/kanata/releases/download/{VERSION}/{asset}"
dldir = ".tmp-kanata-dl"
os.makedirs(dldir, exist_ok=True)
zippath = os.path.join(dldir, "kanata.zip")

print(f"[fetch-kanata] Downloading kanata {VERSION} ({asset})...")
urllib.request.urlretrieve(url, zippath)

with zipfile.ZipFile(zippath) as z:
    z.extract(binary, dldir)

src = os.path.join(dldir, binary)
if os.path.exists(src):
    shutil.copy2(src, dest)
    if os.name != "nt":
        os.chmod(dest, 0o755)

shutil.rmtree(dldir, ignore_errors=True)

if not os.path.exists(dest):
    print("[fetch-kanata] ERROR: Binary not found in archive.")
    sys.exit(1)

# GLIBC check (Linux only)
if system == "Linux":
    import subprocess
    r = subprocess.run([dest, "--version"], capture_output=True)
    if r.returncode != 0:
        os.remove(dest)
        print("[fetch-kanata] Prebuilt binary incompatible (likely GLIBC mismatch).")
        print("[fetch-kanata] Building kanata from source...")
        subprocess.run(["cargo", "install", "kanata", "--version", VERSION.lstrip("v"), "--features", "cmd", "--root", "./tmp-kanata-install"], check=True)
        shutil.copy2(f"./tmp-kanata-install/bin/kanata{ext}", dest)
        shutil.rmtree("./tmp-kanata-install", ignore_errors=True)
        print(f"[fetch-kanata] Done -> {dest} (built from source)")
    else:
        print(f"[fetch-kanata] Done -> {dest} (prebuilt)")
else:
    print(f"[fetch-kanata] Done -> {dest} (prebuilt)")
