import hid
import sys
from dataclasses import dataclass
from time import sleep
import colorsys
import sys

VID = 0x3297
PID = 0x1977
USAGE_PAGE = 0xFF60
MAIN_COLOR_INDEX = 4

FILE_PATH = "/home/korin/.cache/hyprland-dotfiles/keyboard.txt"

@dataclass
class RGB:
    R: int
    G: int
    B: int

def get_voyager_path():
    for device in hid.enumerate(VID, PID):
        if device['usage_page'] == USAGE_PAGE:
            return device['path']
    return None

def get_colors(path):
    colors = []
    with open(path, 'r', encoding='utf-8') as file:
        for line in file:
            hexcode = line.strip().lstrip('#')
            rgb = RGB(R=int(hexcode[0:2], 16), G=int(hexcode[2:4], 16), B=int(hexcode[4:6], 16))
            colors.append(rgb)

    return colors

def rgb_to_hsv_bytes(r, g, b):
    h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
    
    # If the color is grayscale (s == 0), keep saturation at 0.
    # Otherwise, force it to 255 for vibrant keyboard lighting.
    final_s = 255 if s > 0 else 0
    
    return int(h * 255), final_s, 100

if __name__ == "__main__":
    if (len(sys.argv) == 2):
        MAIN_COLOR_INDEX = int(sys.argv[1])
    colors = get_colors(FILE_PATH)
    path = get_voyager_path()
    try:
        try:
            device = hid.device()
            device.open_path(path)
        except AttributeError:
            device = hid.Device(path=path)

        payload1 = [0x00, 0x42]
        payload2 = [0x00, 0x43]

        for i in range(8):
            h, s, v = rgb_to_hsv_bytes(colors[i].R, colors[i].G, colors[i].B)
            payload1.extend([h, s, v])

        payload1 += [0] * (33 - len(payload1))

        for i in range(8):
            h, s, v = rgb_to_hsv_bytes(colors[i].R, colors[i].G, colors[i].B)
            payload2.extend([h, s, v])
        
            h, s, v = rgb_to_hsv_bytes(colors[MAIN_COLOR_INDEX].R, colors[MAIN_COLOR_INDEX].G, colors[MAIN_COLOR_INDEX].B)
            payload2.extend([h, s, v])
            payload2 += [0x00] * (33 - len(payload2))

        device.write(bytes(payload1))
        sleep(0.05)
        device.write(bytes(payload2))

        device.close()

    except Exception as e:
        print(f"Failed to send colors {e}")
