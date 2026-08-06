#!/usr/bin/env python3
"""生成塔防游戏音效 — 全部 CC0 (自主生成,无版权)"""
import math, struct, wave, os, random

SR = 22050  # 22050Hz 足够塔防游戏用
OUT = os.path.join(os.path.dirname(__file__), "sfx")
os.makedirs(OUT, exist_ok=True)

def write_wav(path, samples):
    with wave.open(path, "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        # clamp + 16-bit
        peak = max(1.0, max(abs(s) for s in samples))
        data = b"".join(struct.pack("<h", int(max(-1, min(1, s/peak)) * 32767)) for s in samples)
        f.writeframes(data)

def tone(freq, dur, vol=0.5, type_="sine", slide=0.0):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        f = freq + slide * t
        phase = 2 * math.pi * f * t
        if type_ == "sine":
            v = math.sin(phase)
        elif type_ == "square":
            v = 1 if math.sin(phase) > 0 else -1
        elif type_ == "saw":
            v = 2 * ((f * t) - math.floor(0.5 + f * t))
        else:
            v = math.sin(phase)
        # ADSR envelope
        env = 1.0
        attack = int(n * 0.05)
        release = int(n * 0.4)
        if i < attack:
            env = i / attack
        elif i > n - release:
            env = max(0, (n - i) / release)
        out.append(v * vol * env)
    return out

def mix(*sources):
    n = max(len(s) for s in sources)
    out = [0.0] * n
    for s in sources:
        for i, v in enumerate(s):
            out[i] += v
    return out

def noise(dur, vol=0.3):
    n = int(SR * dur)
    return [random.uniform(-1, 1) * vol for _ in range(n)]

def add(s1, s2):
    n = max(len(s1), len(s2))
    out = list(s1) + [0.0] * (n - len(s1))
    for i, v in enumerate(s2):
        if i < n:
            out[i] += v
    return out

# === SFX 库 ===
print("生成音效…")

# 1. 塔开火 (短而脆,高频)
write_wav(os.path.join(OUT, "tower_shoot.wav"),
          tone(880, 0.06, 0.4) + tone(660, 0.05, 0.25, slide=-2000))

# 2. 弹道命中 (清脆高频脉冲)
write_wav(os.path.join(OUT, "projectile_hit.wav"),
          tone(1200, 0.05, 0.5) + tone(600, 0.05, 0.3, slide=-3000))

# 3. 敌人击杀 (低频 thud)
write_wav(os.path.join(OUT, "enemy_kill.wav"),
          tone(200, 0.12, 0.6) + tone(100, 0.15, 0.4, slide=-100))

# 4. 建造 (上升的"叮")
write_wav(os.path.join(OUT, "tower_place.wav"),
          tone(400, 0.10, 0.5, slide=2000))

# 5. 升级 (上行的琶音)
write_wav(os.path.join(OUT, "tower_upgrade.wav"),
          mix(tone(523, 0.08, 0.45), tone(659, 0.08, 0.45), tone(784, 0.12, 0.45)))

# 6. 熔核受击 (警告短音)
write_wav(os.path.join(OUT, "core_damaged.wav"),
          tone(220, 0.15, 0.6) + tone(110, 0.20, 0.4, slide=-50))

# 7. 熔核摧毁 (沉重低音)
write_wav(os.path.join(OUT, "core_destroyed.wav"),
          tone(80, 0.6, 0.7, slide=-30) + noise(0.5, 0.3))

# 8. UI 点击 1
write_wav(os.path.join(OUT, "ui_click.wav"),
          tone(1000, 0.05, 0.4))

# 9. UI 点击 2
write_wav(os.path.join(OUT, "ui_click_2.wav"),
          tone(700, 0.06, 0.4))

# 10. 波次开始 (鼓点)
write_wav(os.path.join(OUT, "wave_start.wav"),
          mix(tone(60, 0.15, 0.7), tone(400, 0.10, 0.3)))

# 11. 胜利 (上行旋律)
write_wav(os.path.join(OUT, "win.wav"),
          mix(tone(523, 0.15, 0.5), tone(659, 0.15, 0.5), tone(784, 0.15, 0.5),
              tone(1047, 0.30, 0.5)))

# 12. 失败 (下行)
write_wav(os.path.join(OUT, "lose.wav"),
          mix(tone(523, 0.20, 0.5, slide=-100),
              tone(392, 0.20, 0.5, slide=-100),
              tone(294, 0.40, 0.5, slide=-50)))

print(f"完成: {len(os.listdir(OUT))} 个音效 → {OUT}")
