import sys
import os
import shutil
import subprocess
from PIL import Image

ICON_SIZES = [
    (16, False),
    (16, True),
    (32, False),
    (32, True),
    (128, False),
    (128, True),
    (256, False),
    (256, True),
    (512, False),
    (512, True),
    (1024, False),
]


def create_iconset(png_path, iconset_dir):
    img = Image.open(png_path)
    if img.mode != "RGBA":
        img = img.convert("RGBA")

    os.makedirs(iconset_dir, exist_ok=True)

    for size, is_retina in ICON_SIZES:
        filename = f"icon_{size}x{size}"
        if is_retina:
            filename += "@2x"
            export_size = size * 2
        else:
            export_size = size

        resized = img.resize((export_size, export_size), Image.LANCZOS)
        filepath = os.path.join(iconset_dir, f"{filename}.png")
        resized.save(filepath)


def png_to_icns(png_path, icns_path):
    iconset_dir = "icon.iconset"
    try:
        create_iconset(png_path, iconset_dir)
        subprocess.run(
            ["iconutil", "-c", "icns", iconset_dir, "-o", icns_path], check=True
        )
        print(f"✅ Successfully created {icns_path}")
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        if os.path.exists(iconset_dir):
            shutil.rmtree(iconset_dir)


def main():
    if len(sys.argv) != 3:
        print("Usage: python converter.py <input_png_path> <output_icns_path>")
        sys.exit(1)

    input_png = sys.argv[1]
    output_icns = sys.argv[2]

    if not os.path.isfile(input_png):
        print(f"Error: File {input_png} does not exist.")
        sys.exit(1)

    png_to_icns(input_png, output_icns)


if __name__ == "__main__":
    main()
