from scipy.spatial import distance
from collections import defaultdict
import re

game_code_lines = [l.strip() for l in open('game.asm','r').readlines()]

iterator = iter(game_code_lines)
line = next(iterator)
while (line != "tbl_scr_disaster_lo:"):
    line = next(iterator)


lines = [next(iterator), next(iterator), next(iterator), next(iterator)]

rampen = []

for line in lines:
    rampen += [(int(p[0]), int(p[1])) for p in re.findall(r"(\d+)\s+\*\s+\d+\s+\+\s+(\d+)", line)]

city_positions = [(17, 3), (12, 18), (33, 6), (6, 6)]

def afstand(ramp):
    def f(stad):
        return distance.euclidean(ramp, stad)


ramp_data = defaultdict(dict)

for ramp in rampen:
    ramp_data[ramp]['distances'] = map(afstand(ramp), city_positions)

