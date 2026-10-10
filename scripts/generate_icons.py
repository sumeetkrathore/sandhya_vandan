import os
from PIL import Image

def resize_and_save(img, size, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img_resized = img.resize((size, size), Image.Resampling.LANCZOS)
    img_resized.save(path)
    print(f"Saved {path}")

def generate_icons():
    base_dir = "d:/SandyaVandanApp/sandya_vandan"
    source_path = os.path.join(base_dir, "dev_assets/app_icon_source_1024.png")
    
    if not os.path.exists(source_path):
        print("Source image not found.")
        return

    try:
        img = Image.open(source_path)
    except Exception as e:
        print(f"Error opening image: {e}")
        return
        
    img = img.convert("RGBA")
    
    # Android sizes
    android_res_path = os.path.join(base_dir, "android/app/src/main/res")
    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192
    }
    
    for folder, size in android_sizes.items():
        path = os.path.join(android_res_path, folder, "ic_launcher.png")
        resize_and_save(img, size, path)
        
    # iOS sizes
    ios_res_path = os.path.join(base_dir, "ios/Runner/Assets.xcassets/AppIcon.appiconset")
    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    
    for filename, size in ios_sizes.items():
        path = os.path.join(ios_res_path, filename)
        resize_and_save(img, size, path)

    print("Successfully generated all icons!")

if __name__ == "__main__":
    generate_icons()
