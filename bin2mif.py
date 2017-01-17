#!/bin/env python

import sys

def main():
    argc = len(sys.argv)
    if(argc < 2 or argc > 3):
        print("Usage: {0} <binfile> [outfile]".format(sys.argv[0]))
        return
    infile = open(sys.argv[1], "rb", 0)
    outfile = open(sys.argv[2] if argc == 3 else sys.argv[1].replace(".bin", ".mif"), "w", 1)

    infile.seek(0, 2)
    inlen = infile.tell()
    infile.seek(0, 0)

    for i in range(inlen >> 1):
        outfile.write("{0:016b}\n".format(int.from_bytes(infile.read(2), byteorder="big")))
    
    infile.close()
    outfile.close()

main()
