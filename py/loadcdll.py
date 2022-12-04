#!/usr/bin/env python

from ctypes import *

if __name__ == '__main__':
    try:
        shared_obj = cdll.LoadLibrary("./libssf.so")
        count = 10
        # method1
        char_array = (c_char * count)()
        result = shared_obj.pr_test(char_array) # void pr_test(char *)
        print(char_array)
        print('res = ', result)
        # print(repr(char_array.raw))
        print(char_array.value)

        # method2 python3?
        # 如需要可改变内容的字符串，须使用create_string_buffer()
        sbuf = create_string_buffer(b'assign', count)  # create a 10 byte buffer
        print(sbuf.value)
    except Exception as err:
        # pass
        print("Exception = ", err)
