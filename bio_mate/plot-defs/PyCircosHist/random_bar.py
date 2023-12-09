import sys, re
import random

with open("data/sample_bar.txt", 'r') as f:
    for ln, line in enumerate(f):
        if ln == 0:
            print(line.strip())
            continue
        cols = [l.strip() for l in line.split("\t")]
        cols[3] = "2"
        cols[4] = "rgba(%s,%s,%s,0.6)"%(
            random.randint(0,255),
            random.randint(0,255),
            random.randint(0,255),
            )
        cols[5] = ""
        print("\t".join([str(c) for c in cols]))
