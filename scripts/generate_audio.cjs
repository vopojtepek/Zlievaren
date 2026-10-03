const fs = require('fs');
const path = require('path');

const SAMPLE_RATE = 44100;

function createWav(filePath, samples) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  const dataSize = samples.length * 2;
  const buffer = Buffer.alloc(44 + dataSize);

  // RIFF header
  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(36 + dataSize, 4);
  buffer.write('WAVE', 8);

  // fmt subchunk
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16); // Subchunk1Size (16 for PCM)
  buffer.writeUInt16LE(1, 20);  // AudioFormat (1 for PCM)
  buffer.writeUInt16LE(1, 22);  // NumChannels (1 = mono)
  buffer.writeUInt32LE(SAMPLE_RATE, 24); // SampleRate
  buffer.writeUInt32LE(SAMPLE_RATE * 2, 28); // ByteRate
  buffer.writeUInt16LE(2, 32);  // BlockAlign
  buffer.writeUInt16LE(16, 34); // BitsPerSample

  // data subchunk
  buffer.write('data', 36);
  buffer.writeUInt32LE(dataSize, 40);

  let offset = 44;
  for (let i = 0; i < samples.length; i++) {
    const clamped = Math.max(-1.0, Math.min(1.0, samples[i]));
    const intVal = Math.round(clamped * 32767);
    buffer.writeInt16LE(intVal, offset);
    offset += 2;
  }

  fs.writeFileSync(filePath, buffer);
}

function genCoin() {
  const duration = 0.28;
  const numSamples = Math.floor(duration * SAMPLE_RATE);
  const samples = [];
  for (let i = 0; i < numSamples; i++) {
    const t = i / SAMPLE_RATE;
    const freq = t < 0.08 ? 987.0 : 1318.0;
    const env = Math.exp(-t * 12.0);
    const s = Math.sin(2.0 * Math.PI * freq * t) * 0.7 + Math.sin(2.0 * Math.PI * freq * 2.0 * t) * 0.3;
    samples.push(s * env * 0.75);
  }
  return samples;
}

function genPour() {
  const duration = 1.2;
  const numSamples = Math.floor(duration * SAMPLE_RATE);
  const samples = [];
  for (let i = 0; i < numSamples; i++) {
    const t = i / SAMPLE_RATE;
    const env = Math.sqrt(Math.sin((Math.PI * t) / duration));
    const noise = (Math.random() * 2.0 - 1.0) * 0.25;
    const drone = Math.sin(2.0 * Math.PI * 140.0 * t) * 0.4 + Math.sin(2.0 * Math.PI * 280.0 * t) * 0.2;
    samples.push((drone + noise) * env * 0.65);
  }
  return samples;
}

function genSteam() {
  const duration = 1.0;
  const numSamples = Math.floor(duration * SAMPLE_RATE);
  const samples = [];
  let prev = 0.0;
  for (let i = 0; i < numSamples; i++) {
    const t = i / SAMPLE_RATE;
    const env = t < 0.15 ? t / 0.15 : Math.exp(-(t - 0.15) * 3.5);
    const rawNoise = Math.random() * 2.0 - 1.0;
    prev = rawNoise - prev * 0.6;
    samples.push(prev * env * 0.45);
  }
  return samples;
}

function genClank() {
  const duration = 0.45;
  const numSamples = Math.floor(duration * SAMPLE_RATE);
  const samples = [];
  for (let i = 0; i < numSamples; i++) {
    const t = i / SAMPLE_RATE;
    const env = Math.exp(-t * 18.0);
    const thump = Math.sin(2.0 * Math.PI * 95.0 * t) * 0.6;
    const ring1 = Math.sin(2.0 * Math.PI * 720.0 * t) * 0.4;
    const ring2 = Math.sin(2.0 * Math.PI * 1450.0 * t) * 0.2;
    samples.push((thump + ring1 + ring2) * env * 0.8);
  }
  return samples;
}

function genWash() {
  const duration = 1.4;
  const numSamples = Math.floor(duration * SAMPLE_RATE);
  const samples = [];
  for (let i = 0; i < numSamples; i++) {
    const t = i / SAMPLE_RATE;
    const env = Math.sin((Math.PI * t) / duration);
    const mod = 0.5 + 0.5 * Math.sin(2.0 * Math.PI * 5.0 * t);
    const noise = (Math.random() * 2.0 - 1.0) * mod * 0.35;
    samples.push(noise * env * 0.6);
  }
  return samples;
}

function genAlarm() {
  const duration = 0.38;
  const numSamples = Math.floor(duration * SAMPLE_RATE);
  const samples = [];
  for (let i = 0; i < numSamples; i++) {
    const t = i / SAMPLE_RATE;
    const freq = (t % 0.12) < 0.06 ? 520.0 : 880.0;
    const env = Math.exp(-t * 4.0);
    const s = Math.sin(2.0 * Math.PI * freq * t) > 0.0 ? 0.5 : -0.5;
    samples.push(s * env * 0.5);
  }
  return samples;
}

function genFurnaceHum() {
  const duration = 4.0;
  const numSamples = Math.floor(duration * SAMPLE_RATE);
  const samples = [];
  for (let i = 0; i < numSamples; i++) {
    const t = i / SAMPLE_RATE;
    const hum = Math.sin(2.0 * Math.PI * 55.0 * t) * 0.5 + Math.sin(2.0 * Math.PI * 110.0 * t) * 0.25;
    const crackle = (Math.random() * 2.0 - 1.0) * 0.04;
    samples.push((hum + crackle) * 0.4);
  }
  return samples;
}

const sfxDir = path.join('godot', 'assets', 'audio', 'sfx');
const ambDir = path.join('godot', 'assets', 'audio', 'ambient');

createWav(path.join(sfxDir, 'coin.wav'), genCoin());
createWav(path.join(sfxDir, 'pour.wav'), genPour());
createWav(path.join(sfxDir, 'steam.wav'), genSteam());
createWav(path.join(sfxDir, 'clank.wav'), genClank());
createWav(path.join(sfxDir, 'wash.wav'), genWash());
createWav(path.join(sfxDir, 'alarm.wav'), genAlarm());
createWav(path.join(ambDir, 'furnace_hum.wav'), genFurnaceHum());

console.log('All audio WAV assets successfully generated.');
