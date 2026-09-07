"""Fetch only required entries from the official Godot release ZIP using HTTP ranges."""
import io
import os
from pathlib import Path
import urllib.request
import zipfile

URL = "https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_export_templates.tpz"


class RemoteZip(io.RawIOBase):
    def __init__(self, url):
        response = urllib.request.urlopen(urllib.request.Request(url, method="HEAD"), timeout=30)
        self.url = response.url
        self.length = int(response.headers["Content-Length"])
        self.position = 0

    def seekable(self):
        return True

    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else self.position + offset if whence == 1 else self.length + offset
        return self.position

    def tell(self):
        return self.position

    def read(self, count=-1):
        if count < 0:
            count = self.length - self.position
        count = min(count, self.length - self.position)
        if count <= 0:
            return b""
        end = self.position + count - 1
        request = urllib.request.Request(self.url, headers={"Range": f"bytes={self.position}-{end}"})
        with urllib.request.urlopen(request, timeout=90) as response:
            if response.status != 206:
                raise RuntimeError("Server does not support selective download")
            result = response.read()
        if len(result) != count:
            raise RuntimeError("Incomplete range response")
        self.position += len(result)
        return result


if __name__ == "__main__":
    output = Path(os.environ["APPDATA"]) / "Godot/export_templates/4.3.stable"
    output.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(RemoteZip(URL)) as archive:
        for filename in ("android_debug.apk", "windows_debug_x86_64.exe", "version.txt"):
            entry = "templates/" + filename
            print("Downloading", entry, flush=True)
            data = archive.read(entry)  # zipfile validates the entry CRC.
            (output / filename).write_bytes(data)
            print("Installed", filename, len(data), flush=True)
