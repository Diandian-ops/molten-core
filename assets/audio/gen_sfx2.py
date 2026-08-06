#!/usr/bin/env python3
"""3 个新音效: heartbeat / critical_hit / boss_roar / tower_skill / core_skill / branch_pick"""
import os, math, struct, wave, random

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "sfx")
os.makedirs(OUT, exist_ok=True)

def write_wav(path, samples):
    with wave.open(path, "w") as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(SR)
        peak = max(1.0, max(abs(s) for s in samples))
        data = b"".join(struct.pack("<h", int(max(-1, min(1, s/peak)) * 32767)) for s in samples)
        f.writeframes(data)

def tone(freq, dur, vol=0.5, slide=0.0, type_="sine"):
    n = int(SR * dur); out = []
    for i in range(n):
        t = i / SR
        f = freq + slide * t
        phase = 2 * math.pi * f * t
        if type_ == "sine": v = math.sin(phase)
        elif type_ == "square": v = 1 if math.sin(phase) > 0 else -1
        else: v = math.sin(phase)
        env = 1.0
        a, r = int(n*0.05), int(n*0.4)
        if i < a: env = i / a
        elif i > n - r: env = max(0, (n - i) / r)
        out.append(v * vol * env)
    return out

def noise(dur, vol=0.3):
    n = int(SR * dur)
    return [random.uniform(-1, 1) * vol for _ in range(n)]

# 1. heartbeat: 双重低频"咚...咚"
beat1 = tone(45, 0.10, 0.7)
beat2 = [0.0] * int(SR * 0.10) + tone(45, 0.10, 0.6)
write_wav(os.path.join(OUT, "heartbeat.wav"), beat1 + beat2)

# 2. critical_hit: 短促高频爆裂 + 低频冲击
crit = tone(1500, 0.05, 0.6) + tone(80, 0.12, 0.7, slide=-30) + noise(0.05, 0.4)
write_wav(os.path.join(OUT, "critical_hit.wav"), crit)

# 3. boss_roar: 拖长的低频咆哮
roar = tone(60, 1.2, 0.8, slide=-15) + tone(120, 1.0, 0.5) + noise(0.8, 0.3)
write_wav(os.path.join(OUT, "boss_roar.wav"), roar)

# 4. tower_skill: 上升音 + 闪烁
sk = tone(400, 0.05, 0.5) + tone(800, 0.05, 0.5) + tone(1200, 0.15, 0.6)
write_wav(os.path.join(OUT, "tower_skill.wav"), sk)

# 5. core_skill: 低频轰鸣 + 上行
cs = tone(80, 0.15, 0.7) + tone(200, 0.10, 0.5) + tone(523, 0.20, 0.4)
write_wav(os.path.join(OUT, "core_skill.wav"), cs)

# 6. branch_pick: 清脆双音
bp = tone(659, 0.10, 0.5) + tone(880, 0.10, 0.5)
write_wav(os.path.join(OUT, "branch_pick.wav"), bp)

# 7. 慢动作whoosh (命中/暴击瞬间镜头慢动作)
wo = noise(0.3, 0.4)
write_wav(os.path.join(OUT, "whoosh.wav"), wo)

# 8. 暴击时屏幕震
boom = tone(50, 0.20, 0.9) + noise(0.20, 0.5)
write_wav(os.path.join(OUT, "boom.wav"), boom)

print(f"完成: {len([f for f in os.listdir(OUT) if f.endswith('.wav')])} 个 wav")
