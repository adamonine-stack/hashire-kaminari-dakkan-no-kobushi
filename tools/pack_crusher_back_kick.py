"""Pack the separately reviewed evasive kick with the same calibration rules."""
from pack_crusher_forward_kick import ROOT,main
if __name__=='__main__':
    main(ROOT/'art_sources/crusher_back_kick_v13',ROOT/'godot/assets/characters/enemy01/animations/unified_back_kick_v13','crusher_back_kick')
