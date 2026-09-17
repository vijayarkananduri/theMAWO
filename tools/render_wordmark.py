from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[1]
font_path = root / 'assets/fonts/SpaceGrotesk-Bold.ttf'
outputs = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
}
for density, size in outputs.items():
    image = Image.new('RGBA', (size, size), (12, 11, 9, 255))
    draw = ImageDraw.Draw(image)
    font = ImageFont.truetype(str(font_path), max(10, int(size * 0.28)))
    text = 'MAWO'
    box = draw.textbbox((0, 0), text, font=font)
    x = (size - (box[2] - box[0])) // 2
    y = (size - (box[3] - box[1])) // 2 - box[1]
    draw.text((x, y), text, font=font, fill=(232, 133, 10, 255))
    output = root / f'android/app/src/main/res/mipmap-{density}/ic_launcher.png'
    image.save(output)
