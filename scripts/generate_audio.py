import wave
import math
import struct
import os
import random

SAMPLE_RATE = 44100

def create_wav(filename, samples):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(SAMPLE_RATE)
        for s in samples:
            clamped = max(-1.0, min(1.0, s))
            int_val = int(clamped * 32767.0)
            wav_file.writeframes(struct.pack('<h', int_val))

def gen_coin():
    duration = 0.28
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Two fast ascending chime notes: B5 (987 Hz) then E6 (1318 Hz)
        freq = 987.0 if t < 0.08 else 1318.0
        env = math.exp(-t * 12.0)
        s = math.sin(2.0 * math.pi * freq * t) * 0.7 + math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.3
        samples.append(s * env * 0.75)
    return samples

def gen_pour():
    duration = 1.2
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    # Molten rumble and fluid trickle
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * t / duration) ** 0.5
        noise = (random.random() * 2.0 - 1.0) * 0.25
        drone = math.sin(2.0 * math.pi * 140.0 * t) * 0.4 + math.sin(2.0 * math.pi * 280.0 * t) * 0.2
        samples.append((drone + noise) * env * 0.65)
    return samples

def gen_steam():
    duration = 1.0
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    # White noise with high frequency hiss
    prev = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = (t / 0.15) if t < 0.15 else math.exp(-(t - 0.15) * 3.5)
        raw_noise = random.random() * 2.0 - 1.0
        # High pass / bandpass filter simulation
        prev = raw_noise - prev * 0.6
        samples.append(prev * env * 0.45)
    return samples

def gen_clank():
    duration = 0.45
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 18.0)
        thump = math.sin(2.0 * math.pi * 95.0 * t) * 0.6
        ring1 = math.sin(2.0 * math.pi * 720.0 * t) * 0.4
        ring2 = math.sin(2.0 * math.pi * 1450.0 * t) * 0.2
        samples.append((thump + ring1 + ring2) * env * 0.8)
    return samples

def gen_wash():
    duration = 1.4
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * t / duration)
        # Modulated water spray
        mod = 0.5 + 0.5 * math.sin(2.0 * math.pi * 5.0 * t)
        noise = (random.random() * 2.0 - 1.0) * mod * 0.35
        samples.append(noise * env * 0.6)
    return samples

def gen_alarm():
    duration = 0.38
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 520.0 if math.fmod(t, 0.12) < 0.06 else 880.0
        env = math.exp(-t * 4.0)
        # Square-ish sound
        s = 0.5 if math.sin(2.0 * math.pi * freq * t) > 0.0 else -0.5
        samples.append(s * env * 0.5)
    return samples

def gen_furnace_hum():
    duration = 4.0
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Seamless loop of 55 Hz and harmonics
        hum = math.sin(2.0 * math.pi * 55.0 * t) * 0.5 + math.sin(2.0 * math.pi * 110.0 * t) * 0.25
        crackle = (random.random() * 2.0 - 1.0) * 0.04
        samples.append((hum + crackle) * 0.4)
    return samples

if __name__ == '__main__':
    sfx_dir = os.path.join('godot', 'assets', 'audio', 'sfx')
    amb_dir = os.path.join('godot', 'assets', 'audio', 'ambient')
    
    create_wav(os.path.join(sfx_dir, 'coin.wav'), gen_coin())
    create_wav(os.path.join(sfx_dir, 'pour.wav'), gen_pour())
    create_wav(os.path.join(sfx_dir, 'steam.wav'), gen_steam())
    create_wav(os.path.join(sfx_dir, 'clank.wav'), gen_clank())
    create_wav(os.path.join(sfx_dir, 'wash.wav'), gen_wash())
    create_wav(os.path.join(sfx_dir, 'alarm.wav'), gen_alarm())
    create_wav(os.path.join(amb_dir, 'furnace_hum.wav'), gen_furnace_hum())
    
    print("Audio assets generated successfully.")
