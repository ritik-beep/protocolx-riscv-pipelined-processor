#!/usr/bin/env python3
import os
import shutil
import subprocess
from PIL import Image, ImageDraw, ImageFont

FRAME_DIR = "/tmp/protocolx_frames"
os.makedirs(FRAME_DIR, exist_ok=True)

# Canvas settings
W, H = 1060, 530
FONT_PATH = "/System/Library/Fonts/Helvetica.ttc"

try:
    font_title = ImageFont.truetype(FONT_PATH, 18, index=1)
    font_sub   = ImageFont.truetype(FONT_PATH, 12, index=0)
    font_stage = ImageFont.truetype(FONT_PATH, 14, index=1)
    font_box   = ImageFont.truetype(FONT_PATH, 11, index=1)
    font_small = ImageFont.truetype(FONT_PATH, 9, index=0)
    font_token = ImageFont.truetype(FONT_PATH, 10, index=1)
    font_cycle = ImageFont.truetype(FONT_PATH, 13, index=1)
except Exception:
    font_title = font_sub = font_stage = font_box = font_small = font_token = font_cycle = ImageFont.load_default()

# 5 Stage boundaries
stages = [
    {"name": "STAGE 1: IF", "sub": "Instruction Fetch", "color": "#e0f2fe", "border": "#38bdf8", "x": 30,  "w": 180},
    {"name": "STAGE 2: ID", "sub": "Instruction Decode","color": "#ecfdf5", "border": "#34d399", "x": 235, "w": 185},
    {"name": "STAGE 3: EX", "sub": "Execute / ALU",     "color": "#fff7ed", "border": "#fb923c", "x": 445, "w": 190},
    {"name": "STAGE 4: MEM","sub": "Memory Access",     "color": "#faf5ff", "border": "#c084fc", "x": 660, "w": 175},
    {"name": "STAGE 5: WB", "sub": "Write-Back",        "color": "#f0fdfa", "border": "#2dd4bf", "x": 860, "w": 175},
]

# Pipeline Registers (X positions)
pipe_regs = [
    {"name": "IF/ID", "x": 215, "color": "#2563eb"},
    {"name": "ID/EX", "x": 425, "color": "#10b981"},
    {"name": "EX/MEM","x": 640, "color": "#f97316"},
    {"name": "MEM/WB","x": 840, "color": "#8b5cf6"}
]

# Instructions to trace
instructions = [
    {"id": "I1", "asm": "addi x1, x0, 10", "dest": "x1", "val": "10", "bg": "#1d4ed8", "fg": "#ffffff"},
    {"id": "I2", "asm": "addi x2, x0, 20", "dest": "x2", "val": "20", "bg": "#7c3aed", "fg": "#ffffff"},
    {"id": "I3", "asm": "add  x3, x1, x2", "dest": "x3", "val": "30", "bg": "#ea580c", "fg": "#ffffff"},
    {"id": "I4", "asm": "sub  x4, x2, x1", "dest": "x4", "val": "10", "bg": "#dc2626", "fg": "#ffffff"},
    {"id": "I5", "asm": "sw   x3, 0(x1) ", "dest": "mem","val": "30", "bg": "#0d9488", "fg": "#ffffff"}
]

# Cycle schedule: for each cycle (0 to 8), which stage is each instruction at?
# Stages: 0=IF, 1=ID, 2=EX, 3=MEM, 4=WB, -1=Not yet, 5=Done
schedule = [
    # C1
    {"desc": "Cycle 1: Fetching I1 (addi x1, 10)", "fwd": False,
     "states": [0, -1, -1, -1, -1]},
    # C2
    {"desc": "Cycle 2: I1 in ID, Fetching I2 (addi x2, 20)", "fwd": False,
     "states": [1, 0, -1, -1, -1]},
    # C3
    {"desc": "Cycle 3: I1 in EX (ALU: 0+10=10), I2 in ID, Fetching I3", "fwd": False,
     "states": [2, 1, 0, -1, -1]},
    # C4
    {"desc": "Cycle 4: I1 in MEM, I2 in EX (ALU: 0+20=20), I3 in ID, Fetching I4", "fwd": False,
     "states": [3, 2, 1, 0, -1]},
    # C5
    {"desc": "Cycle 5: [WB: x1<=10] • I3 in EX forwards x1 & x2! (10+20=30)", "fwd": True,
     "states": [4, 3, 2, 1, 0]},
    # C6
    {"desc": "Cycle 6: [WB: x2<=20] • I4 in EX (20-10=10) • I3 in MEM", "fwd": False,
     "states": [5, 4, 3, 2, 1]},
    # C7
    {"desc": "Cycle 7: [WB: x3<=30] • I4 in MEM • I5 in EX (address calc)", "fwd": False,
     "states": [5, 5, 4, 3, 2]},
    # C8
    {"desc": "Cycle 8: [WB: x4<=10] • I5 in MEM (RAM Write: DMEM[10]<=30)", "fwd": False,
     "states": [5, 5, 5, 4, 3]}
]

# Stage center X positions
stage_centers = [120, 327, 540, 747, 947]

def draw_base_architecture(draw):
    # Background
    draw.rectangle([0, 0, W, H], fill="#0f172a") # Dark slate background for premium look

    # Header bar
    draw.rectangle([20, 15, W-20, 70], fill="#1e293b", outline="#334155", width=1)
    draw.text((35, 23), "PROTOCOLX — 5-STAGE RISC-V PIPELINED PROCESSOR", fill="#f8fafc", font=font_title)
    draw.text((35, 48), "Live Pipeline Cycle Animation • Instructions Overlapping in Real-Time", fill="#94a3b8", font=font_sub)

    # Stages boxes
    for idx, stg in enumerate(stages):
        x0, w = stg["x"], stg["w"]
        # Outer stage card
        draw.rounded_rectangle([x0, 85, x0+w, 440], radius=8, fill="#1e293b", outline=stg["border"], width=2)
        # Stage title pill
        draw.rounded_rectangle([x0+10, 95, x0+w-10, 130], radius=5, fill=stg["color"], outline=stg["border"], width=1)
        draw.text((x0+w//2, 102), stg["name"], fill="#0f172a", font=font_stage, anchor="mm")
        draw.text((x0+w//2, 119), stg["sub"], fill="#475569", font=font_small, anchor="mm")

    # Internal sub-blocks
    # IF
    draw.rounded_rectangle([45, 145, 105, 190], radius=4, fill="#0f172a", outline="#38bdf8", width=1)
    draw.text((75, 162), "PC Reg", fill="#38bdf8", font=font_box, anchor="mm")
    draw.text((75, 178), "+4 Adder", fill="#94a3b8", font=font_small, anchor="mm")

    draw.rounded_rectangle([115, 145, 195, 240], radius=4, fill="#0f172a", outline="#38bdf8", width=1)
    draw.text((155, 185), "Instruction", fill="#38bdf8", font=font_box, anchor="mm")
    draw.text((155, 202), "Memory", fill="#38bdf8", font=font_box, anchor="mm")
    draw.text((155, 220), "4KB ROM", fill="#64748b", font=font_small, anchor="mm")

    # ID
    draw.rounded_rectangle([250, 145, 405, 185], radius=4, fill="#0f172a", outline="#34d399", width=1)
    draw.text((327, 165), "Control Unit Decoder", fill="#34d399", font=font_box, anchor="mm")

    draw.rounded_rectangle([250, 195, 405, 280], radius=4, fill="#0f172a", outline="#34d399", width=1)
    draw.text((327, 225), "Register File (x0-x31)", fill="#34d399", font=font_box, anchor="mm")
    draw.text((327, 245), "x0=0 Hardwired • Dual Read", fill="#94a3b8", font=font_small, anchor="mm")
    draw.text((327, 262), "Same-Cycle WB Bypass", fill="#64748b", font=font_small, anchor="mm")

    draw.rounded_rectangle([250, 290, 405, 330], radius=4, fill="#0f172a", outline="#34d399", width=1)
    draw.text((327, 310), "Immediate Generator", fill="#34d399", font=font_box, anchor="mm")

    # EX
    draw.polygon([(465, 170), (510, 195), (510, 235), (465, 260), (465, 225), (475, 215), (465, 205)], fill="#0f172a", outline="#fb923c")
    draw.text((490, 215), "ALU", fill="#fb923c", font=font_box, anchor="mm")

    draw.rounded_rectangle([525, 175, 620, 220], radius=4, fill="#0f172a", outline="#fb923c", width=1)
    draw.text((572, 192), "Forward Mux", fill="#fb923c", font=font_box, anchor="mm")
    draw.text((572, 208), "EX/MEM • MEM/WB", fill="#64748b", font=font_small, anchor="mm")

    draw.rounded_rectangle([465, 280, 620, 325], radius=4, fill="#0f172a", outline="#fb923c", width=1)
    draw.text((542, 298), "Branch / Jump Adder", fill="#fb923c", font=font_box, anchor="mm")
    draw.text((542, 314), "Target = PC + Imm", fill="#64748b", font=font_small, anchor="mm")

    # MEM
    draw.rounded_rectangle([680, 165, 815, 270], radius=4, fill="#0f172a", outline="#c084fc", width=1)
    draw.text((747, 205), "Data Memory", fill="#c084fc", font=font_box, anchor="mm")
    draw.text((747, 225), "4KB RAM", fill="#c084fc", font=font_box, anchor="mm")
    draw.text((747, 245), "Synchronous LW/SW", fill="#64748b", font=font_small, anchor="mm")

    # WB
    draw.polygon([(885, 185), (920, 200), (920, 250), (885, 265)], fill="#0f172a", outline="#2dd4bf")
    draw.text((902, 225), "Mux", fill="#2dd4bf", font=font_box, anchor="mm")
    draw.text((975, 200), "ALU Result", fill="#94a3b8", font=font_small, anchor="mm")
    draw.text((975, 225), "Mem Data", fill="#94a3b8", font=font_small, anchor="mm")
    draw.text((975, 250), "PC + 4 (JAL)", fill="#64748b", font=font_small, anchor="mm")

    # Pipeline Registers (Vertical Pillars)
    for pr in pipe_regs:
        rx = pr["x"]
        draw.rounded_rectangle([rx, 100, rx+16, 425], radius=3, fill=pr["color"], outline="#cbd5e1", width=1)

    # Bottom Hazard & Forwarding Unit
    draw.rounded_rectangle([235, 455, 835, 510], radius=6, fill="#1e293b", outline="#64748b", width=1)
    draw.text((535, 473), "Central Hazard Detection & Data Forwarding Unit", fill="#f8fafc", font=font_box, anchor="mm")
    draw.text((535, 493), "Resolves RAW Hazards (EX/MEM, MEM/WB) • 1-Cycle Load-Use Stall • Branch Flush", fill="#94a3b8", font=font_small, anchor="mm")

frame_idx = 0
TOTAL_CYCLES = len(schedule)
SUB_FRAMES = 8  # frames per cycle for smooth motion

for c_idx in range(TOTAL_CYCLES):
    cur = schedule[c_idx]
    nxt = schedule[(c_idx + 1) % TOTAL_CYCLES]

    for sub in range(SUB_FRAMES):
        # Progress 0.0 to 1.0 within the cycle
        t = sub / float(SUB_FRAMES)
        
        img = Image.new("RGB", (W, H), "#0f172a")
        draw = ImageDraw.Draw(img)
        draw_base_architecture(draw)

        # Draw cycle banner in top right
        c_num = c_idx + 1
        draw.rounded_rectangle([730, 23, W-30, 60], radius=5, fill="#0284c7" if not cur["fwd"] else "#059669")
        draw.text((880, 42), f"CLOCK CYCLE {c_num} / 8", fill="#ffffff", font=font_cycle, anchor="mm")

        # Bottom info pill
        draw.rounded_rectangle([30, 410, W-30, 442], radius=4, fill="#334155")
        draw.text((W//2, 426), cur["desc"], fill="#38bdf8" if not cur["fwd"] else "#4ade80", font=font_box, anchor="mm")

        # Forwarding Wire Highlight if active
        if cur["fwd"]:
            # Forward wire glowing from EX/MEM & MEM/WB back to EX
            draw.line([(648, 140), (648, 120), (510, 120), (510, 185)], fill="#22c55e", width=3)
            draw.text((579, 110), ">>> FORWARDING ACTIVE (RAW RESOLVED) >>>", fill="#22c55e", font=font_small, anchor="mm")

        # Draw active instructions flowing
        for i_idx, inst in enumerate(instructions):
            st_cur = cur["states"][i_idx]
            st_nxt = nxt["states"][i_idx]

            # If moving or static in a valid stage (0..4)
            if st_cur != -1 and st_cur != 5:
                # Interpolate X position
                x_start = stage_centers[st_cur]
                if st_nxt != -1 and st_nxt != 5:
                    x_end = stage_centers[st_nxt]
                elif st_nxt == 5:
                    x_end = stage_centers[4] + 90
                else:
                    x_end = x_start

                # Smooth ease-in-out movement
                x_pos = x_start + (x_end - x_start) * (t if sub >= 3 else 0.0)
                y_pos = 350 + (i_idx * 15) % 45

                # Draw Instruction Token Badge
                box_w = 145
                box_h = 24
                bx0 = x_pos - box_w // 2
                bx1 = x_pos + box_w // 2

                # Stage highlight glow
                draw.rounded_rectangle([bx0-2, y_pos-2, bx1+2, y_pos+box_h+2], radius=6, fill="#38bdf8" if i_idx==2 else "#94a3b8")
                draw.rounded_rectangle([bx0, y_pos, bx1, y_pos+box_h], radius=4, fill=inst["bg"])
                draw.text((x_pos, y_pos + box_h // 2), f"{inst['id']}: {inst['asm']}", fill=inst["fg"], font=font_token, anchor="mm")

        # Save frame
        frame_path = f"{FRAME_DIR}/frame_{frame_idx:04d}.png"
        img.save(frame_path)
        frame_idx += 1

print(f"Generated {frame_idx} frames in {FRAME_DIR}")

# Convert to high-quality animated GIF using ffmpeg
GIF_OUTPUT = "/Users/n2/Desktop/mca project/diagrams/pipeline_animation.gif"
cmd = [
    "ffmpeg", "-y",
    "-framerate", "10",
    "-i", f"{FRAME_DIR}/frame_%04d.png",
    "-vf", "split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer",
    GIF_OUTPUT
]
subprocess.run(cmd, check=True)
print(f"Successfully generated animated GIF: {GIF_OUTPUT}")
shutil.rmtree(FRAME_DIR)
