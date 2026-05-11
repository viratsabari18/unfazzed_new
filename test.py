import base64
import os

image_path = r'c:\Users\58him\Zeerah\WhatsApp Image 2026-04-29 at 4.03.49 PM.jpeg'
if os.path.exists(image_path):
    print('Image exists. Size:', os.path.getsize(image_path))
else:
    print('Image not found')
