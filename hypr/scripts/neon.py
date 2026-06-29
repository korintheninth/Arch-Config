#!/usr/bin/env python3
import re
import sys
import colorsys

def hex_to_rgb(hex_color):
    """Convert hex #RRGGBB to RGB tuple (0.0 - 1.0)"""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) / 255.0 for i in (0, 2, 4))

def rgb_to_hex(r, g, b):
    """Convert RGB tuple (0.0 - 1.0) back to hex #RRGGBB"""
    return f"#{int(r * 255):02X}{int(g * 255):02X}{int(b * 255):02X}"

def process_match(match):
    """Callback for re.sub to modify the lightness of the matched hex string"""
    attribute_name = match.group(1) 
    original_hex = match.group(2)   
    
    r, g, b = hex_to_rgb(original_hex)
    
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    
    new_l = 0.50
    new_s = 1.0
    
    new_r, new_g, new_b = colorsys.hls_to_rgb(h, new_l, s)
    new_hex = rgb_to_hex(new_r, new_g, new_b)
    
    return f'{attribute_name}="{new_hex}"'

def main():
    if len(sys.argv) < 2:
        print("Usage: python update_neon.py <path_to_svg>")
        sys.exit(1)

    filepath = sys.argv[1]

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    updated_content = re.sub(r'(fill|stop-color)="#([A-Fa-f0-9]{6})"', process_match, content, flags=re.IGNORECASE)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(updated_content)
        
if __name__ == "__main__":
    main()
