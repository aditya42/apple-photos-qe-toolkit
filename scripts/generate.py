from pathlib import Path
import json
from PIL import Image

def generate(root):
    root = Path(root); root.mkdir(parents=True, exist_ok=True)
    records = []
    for name, size, color in [('small.png',(64,32),'red'),('landscape.jpg',(640,480),'blue'),('portrait.jpg',(480,640),'green')]:
        image = Image.new('RGB', size, color)
        image.save(root/name)
        records.append({'file':name,'width':size[0],'height':size[1]})
    (root/'manifest.json').write_text(json.dumps(records, indent=2))
    return records

if __name__ == '__main__':
    generate('artifacts/fixtures')
