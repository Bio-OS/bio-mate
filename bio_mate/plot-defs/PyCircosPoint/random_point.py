import sys, re
import random

with open("data/sample_snp.txt", 'r') as f:
    for ln, line in enumerate(f):
        if ln == 0:
            print(line.strip())
            continue
        cols = [l.strip() for l in line.split("\t")]
        cols[3] = random.randint(0, 1000)/10
        if cols[3]<=90 and cols[3]>=10:
            cols[3] = random.randint(0, 1000)/10
        if cols[3]<=90 and cols[3]>=10:
            cols[3] = random.randint(0, 1000)/10
        if cols[3] > 90:
            cols[4] = "rgba(1,0,0,1)"
            cols[5] = cols[5]
        elif cols[3] < 10:
            cols[4] = "rgba(0,0,1,1)"
            cols[5] = ""
        else:
            cols[4] = "rgba(255,185,15,1)"
            cols[5] = ""
        cols[3] = cols[3]/100
        print("\t".join([str(c) for c in cols]))
