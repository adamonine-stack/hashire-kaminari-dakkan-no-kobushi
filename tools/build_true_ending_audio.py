"""Deterministic original film cues, no external audio or run-save mutations."""
from pathlib import Path
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / 'godot/assets/endings/true'
ROOT.mkdir(parents=True, exist_ok=True)
RATE = 22050
rng = random.Random(90817)

def render(name, duration, sample):
    with wave.open(str(ROOT / (name + '.wav')), 'wb') as wav:
        wav.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        data = bytearray()
        for i in range(int(duration * RATE)):
            t = i / RATE
            v = max(-0.96, min(0.96, sample(t)))
            data.extend(struct.pack('<h', int(v * 32767)))
        wav.writeframes(data)

tau = math.tau
render('click', .13, lambda t: (rng.uniform(-1,1)*.65 + math.sin(tau*1850*t)*.2)*math.exp(-t*65))
render('alarm', 2, lambda t: .23*math.sin(tau*620*t - 160*math.cos(tau*.5*t))*(.65+.35*math.sin(tau*t)))
render('rumble', 4, lambda t: .25*math.sin(tau*42*t)+rng.uniform(-.035,.035))
render('engine', 4, lambda t: .12*math.sin(tau*55*t)*(1+.35*math.sin(tau*7*t))+.035*math.sin(tau*110*t))
render('waves', 8, lambda t: rng.uniform(-.2,.2)*(.6+.4*math.sin(tau*t/8)) + .03*math.sin(tau*83*t))
render('explosion', 7, lambda t: (rng.uniform(-.6,.6)*math.exp(-t*.95)+.45*math.sin(tau*(48*t-1.5*t*t))*math.exp(-t*.65))*min(1,t*140))

# Soft piano-like arpeggios with slow consonant pads, without battle percussion.
chords = [(48,55,60,64),(45,52,57,60),(41,48,53,57),(43,50,55,59)]
def music(t):
    chord = chords[int(t/8)%4]
    beat = int(t/1.0)
    phase = t%1.0
    note = chord[beat%4]+12
    hz = 440*2**((note-69)/12)
    piano = (.10*math.sin(tau*hz*t)+.025*math.sin(tau*hz*2*t))*math.exp(-phase*3.8)*min(1,phase*100)
    pad = sum(math.sin(tau*(440*2**((n-69)/12))*t) for n in chord)*.018
    envelope = min(1,(t%8)*2,(8-t%8)*2)
    return piano+pad*envelope
render('ending_music',32,music)
print('TRUE_ENDING_AUDIO_OK')
