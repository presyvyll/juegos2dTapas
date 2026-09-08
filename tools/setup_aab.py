"""Install the official, pinned Godot 4.3 Gradle template without replacing a build."""
import os
from pathlib import Path
import zipfile
from fetch_templates import RemoteZip, URL

root = Path(__file__).resolve().parent.parent
destination = root / 'android/build'
if destination.exists():
    raise SystemExit('android/build already exists; preserved without changes.')
source = Path(os.environ['APPDATA']) / 'Godot/export_templates/4.3.stable/android_source.zip'
if not source.exists():
    source.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(RemoteZip(URL)) as archive:
        source.write_bytes(archive.read('templates/android_source.zip'))
with zipfile.ZipFile(source) as archive:
    archive.extractall(destination)
with (destination / 'gradle.properties').open('a', encoding='utf-8') as settings:
    settings.write('\n# Let the headless Godot exporter finish after the build.\norg.gradle.daemon=false\n')
(root / 'android/.gdignore').touch()
(root / 'android/.build_version').write_text('4.3.stable', encoding='utf-8')
print('Installed Android Gradle template for Godot 4.3.')
