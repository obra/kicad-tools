#!/usr/bin/env python3
import argparse
import pcbnew

def parse_args():
    parser = argparse.ArgumentParser(description="Fill zones in a KiCad PCB file.  Saves over input file.")
    parser.add_argument("filename")
    args = parser.parse_args()
    return args


def main():
    args = parse_args()
    board = pcbnew.LoadBoard(args.filename)
    filler = pcbnew.ZONE_FILLER(board)
    zones = board.Zones()
    filler.Fill(zones)
    pcbnew.SaveBoard(args.filename, board)


if __name__ == "__main__":
    main()
