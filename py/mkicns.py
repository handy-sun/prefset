#!/usr/bin/env python
import sys
import io
import os
import struct
from PIL import Image

def make_integar(s, is_string = True):
    b = s.encode('ascii') if is_string else s
    return (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3]

def write_to_file(fname, fsize, entries):
    byte_arr = io.BytesIO()
    # Header
    byte_arr.write(struct.pack('i', make_integar("icns"))[::-1])
    byte_arr.write(struct.pack('i', fsize)[::-1])

    # Data
    for _, e in enumerate(entries):
        byte_arr.write(struct.pack('i', make_integar(e.get('type')))[::-1])
        byte_arr.write(struct.pack('i', e.get('size'))[::-1])
        byte_arr.write(e.get('stream').getvalue())

    byte_arr.flush()

    ff = open(fname, 'wb')
    ff.write(byte_arr.getvalue())
    ff.flush()
    ff.close()
    print('write %s, size: %ld B.' % (fname, len(byte_arr.getvalue())) )

def compress_to_icns(out_icns, png_dict):
    HEADER_SIZE = 8
    fileSize = 8
    entries = []

    for key, png_file in png_dict.items():
        cleaned_key = str(key).replace('-', '')        
        size = os_type_size_dict.get(cleaned_key)
        if size != None:
            temp = io.BytesIO()
            bit_image = Image.open(png_file)
            print('clean = %s, png = %s' % (cleaned_key, png_file) )
            # bit_image.size()
            # scaled_image = bit_image.resize((size, size))
            bit_image.save(temp, 'png')
            total_size = len(temp.getvalue()) + HEADER_SIZE
            fileSize += total_size
            print(bit_image, total_size)
            entries.append({
                'type': cleaned_key,
                'size': total_size,
                'stream': temp
            })

    write_to_file(out_icns, fileSize, entries)

def uncompress_to_iconset(in_icns: str):
    if not os.path.isfile(in_icns): 
        print('don\'t exist :', in_icns)
        return

    fd = open(in_icns, 'rb')

    header = fd.read(8)
    sign, b = struct.unpack('4s4s', header)
    real_len = os.path.getsize(in_icns)
    flen = make_integar(b, False)

    if str(sign, 'utf-8') != 'icns' or real_len != flen:
        fd.close()
        print('sign is wrong or real_len %d is not equal to len: %d' % (real_len, flen))
        return
    
    iconset_dir = in_icns.replace('.icns', '.iconset')
    if not os.path.isdir(iconset_dir):
        os.mkdir(iconset_dir)
    
    while fd.tell() < real_len:
        print('pos:', fd.tell())
        header = fd.read(8)
        sign, b = struct.unpack('4s4s', header)
        block_len = make_integar(b, False)
        image_bytes = fd.read(block_len - 8)
        str_sign = str(sign, 'utf-8')   
        suffix = '.png' if os_type_size_dict.get(str_sign, 0) != 0 else '.ico'
        f = open(iconset_dir + '/' + str_sign + suffix, 'wb')
        f.write(image_bytes)
        f.flush()
        f.close()

    print('end_pos:', fd.tell())
    fd.close()

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Please select a *.png as input image!")
        sys.exit(-1)

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
        # 'is32' : 16,
    }

    arg_map = {}
    used_argv = sys.argv[1:]
    for idx, arg in enumerate(used_argv):
        if idx % 2 == 0 and idx + 1 <= len(used_argv):
            arg_map[arg] = used_argv[idx + 1]

    icns_file = arg_map.get('-c')
    unicns_file = arg_map.get('-x')
    if icns_file != None:
        del arg_map['-c']
        compress_to_icns(icns_file, arg_map)
    elif unicns_file != None:
        # del arg_map['-x']
        uncompress_to_iconset(unicns_file)

'''
# TOC content
TOC = 'TOC '
tocSize = HEADER_SIZE + (len(entries) * HEADER_SIZE)
byte_arr.write(struct.pack('i', make_integar(TOC))[::-1])
byte_arr.write(struct.pack('i', tocSize)[::-1])

for e in entries:
    byte_arr.write(struct.pack('i', make_integar(e.get('type')))[::-1])
    byte_arr.write(struct.pack('i', HEADER_SIZE + e.get('size'))[::-1])
'''
