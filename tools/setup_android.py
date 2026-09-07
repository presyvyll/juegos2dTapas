"""Download/extract a project-local debug export toolchain. Does not change PATH."""
from pathlib import Path
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / ".tools"
PACKAGES = [
    ("jdk17", "https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse", "jdk"),
    ("build-tools", "https://dl.google.com/android/repository/build-tools_r34-windows.zip", "sdk/build-tools"),
    ("platform-tools", "https://dl.google.com/android/repository/platform-tools-latest-windows.zip", "sdk"),
]

if __name__ == "__main__":
    (TOOLS / "downloads").mkdir(parents=True, exist_ok=True)
    for name, url, folder in PACKAGES:
        archive = TOOLS / "downloads" / (name + ".zip")
        if not archive.exists():
            temporary = archive.with_suffix(".part")
            subprocess.run(["curl.exe", "-fLsS", "--connect-timeout", "15", "--max-time", "240", url, "-o", str(temporary)], check=True)
            temporary.replace(archive)
        destination = TOOLS / folder
        # build_debug renames android-14 to its SDK version directory.
        if name == "build-tools" and (destination / "34.0.0").exists():
            continue
        with zipfile.ZipFile(archive) as source:
            for entry in source.infolist():
                target = (destination / entry.filename).resolve()
                if not target.is_relative_to(destination.resolve()):
                    raise ValueError("Unexpected archive entry")
            source.extractall(destination)
        print("Ready:", name, flush=True)
    subprocess.run([sys.executable, str(ROOT / "tools/fetch_templates.py")], check=True)
