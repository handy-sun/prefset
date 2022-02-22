#!/usr/bin/env python
import sys
import io
import struct
from PIL import Image

def make_integar(s):
    b = s.encode('ascii')
    return (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3]

if len(sys.argv) < 2:
    print("Please select a .png as input image!")
    sys.exit(-1)

src_file = sys.argv[1]

bit_image = Image.open(src_file)

print(bit_image)

# 10种尺寸大小及标志
os_type_size_dict = {
    'ic12' : 64, # 32x32@2x
    'ic07' : 128,
    'ic13' : 256,# 128x128@2x
    'ic08' : 256,
    'ic04' : 16, 
    'ic14' : 512, # 256x256@2x
    'ic09' : 512,
    'ic05' : 32,    
    'ic10' : 1024,# ( or 512x512@2x )
    'ic11' : 32, # 16x16@2x     
}

HEADER_SIZE = 8
fileSize = 8
entries = []

for key, size in os_type_size_dict.items():
    temp = io.BytesIO()
    scaled_image = bit_image.resize((size, size))
    scaled_image.save(temp, 'png')
    total_size = len(temp.getvalue()) + HEADER_SIZE
    fileSize += total_size
    entries.append({
        'type': key,
        'size': total_size,
        'stream': temp
    })

byte_arr = io.BytesIO()
# Header
byte_arr.write(struct.pack('i', make_integar("icns"))[::-1])
byte_arr.write(struct.pack('i', fileSize)[::-1])

'''
TOC = 'TOC '
# TOC content
tocSize = HEADER_SIZE + (len(entries) * HEADER_SIZE)
byte_arr.write(struct.pack('i', make_integar(TOC))[::-1])
byte_arr.write(struct.pack('i', tocSize)[::-1])

for e in entries:
    byte_arr.write(struct.pack('i', make_integar(e.get('type')))[::-1])
    byte_arr.write(struct.pack('i', HEADER_SIZE + e.get('size'))[::-1])
'''

# Data
for index, e in enumerate(entries):
    byte_arr.write(struct.pack('i', make_integar(e.get('type')))[::-1])
    byte_arr.write(struct.pack('i', e.get('size'))[::-1])
    byte_arr.write(e.get('stream').getvalue())

byte_arr.flush()

if len(sys.argv) > 2:
    dest_icns = sys.argv[2]
else:
    dest_icns = src_file[0:src_file.rfind('.')] + '.icns'

print('out_icns: %s, size: %ld B.' % (dest_icns, len(byte_arr.getvalue())) )

ff = open(dest_icns, 'wb')
ff.write(byte_arr.getvalue())
ff.flush()
ff.close()
