import os
import cv2
import numpy as np


def create_traffic_sample_video(output_path="videos/traffic.mp4", num_frames=100, width=640, height=480):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
    out = cv2.VideoWriter(output_path, fourcc, 25.0, (width, height))

    print(f"[Sample Video Generator] Creating test video: {output_path} ({num_frames} frames)...")

    # Load real vehicle images from dataset if available
    im94_path = os.path.join("data", "train", "images", "000000000094.jpg")
    im471_path = os.path.join("data", "train", "images", "000000000471.jpg")
    im64_path = os.path.join("data", "test", "images", "000000000064.jpg")

    if os.path.exists(im94_path) and os.path.exists(im471_path) and os.path.exists(im64_path):
        im94 = cv2.imread(im94_path)
        car_north = cv2.resize(im94[276:310, 356:397], (50, 38))
        car_south = cv2.resize(im94[276:310, 356:397], (48, 36))

        im471 = cv2.imread(im471_path)
        bus_east = cv2.resize(im471[108:323, 115:576], (65, 45))

        im64 = cv2.imread(im64_path)
        car_west = cv2.resize(im64[392:525, 50:228], (52, 40))
        use_sprites = True
    else:
        use_sprites = False

    for i in range(num_frames):
        # Create a road intersection background
        frame = np.full((height, width, 3), 40, dtype=np.uint8)

        # Intersection roads
        cv2.rectangle(frame, (width//2 - 80, 0), (width//2 + 80, height), (70, 70, 70), -1)
        cv2.rectangle(frame, (0, height//2 - 80), (width, height//2 + 80), (70, 70, 70), -1)

        # Dashed lane markings
        for y in range(0, height, 30):
            cv2.line(frame, (width//2, y), (width//2, min(y+15, height)), (255, 255, 255), 2)
        for x in range(0, width, 30):
            cv2.line(frame, (x, height//2), (min(x+15, width), height//2), (255, 255, 255), 2)

        if use_sprites:
            # 1. North incoming: vehicle moving down towards center
            ny = int(20 + (i * 3.5) % 170)
            nx = width//2 - 60
            frame[ny:ny+38, nx:nx+50] = car_north

            # 2. South incoming: vehicle moving up towards center
            sy = int(420 - (i * 3.0) % 150)
            sx = width//2 + 15
            frame[sy:sy+36, sx:sx+48] = car_south

            # 3. East incoming: vehicle moving left towards center
            ex = int(560 - (i * 4.0) % 200)
            ey = height//2 + 15
            frame[ey:ey+45, ex:ex+65] = bus_east

            # 4. West incoming: vehicle moving right towards center
            wx = int(20 + (i * 4.5) % 220)
            wy = height//2 - 60
            frame[wy:wy+40, wx:wx+52] = car_west

            # Dynamic traffic variation: East approach receives heavier traffic after frame 30
            if i >= 30:
                ex2 = int(580 - ((i - 30) * 3.0) % 180)
                ey2 = height//2 + 20
                frame[ey2:ey2+38, ex2:ex2+50] = car_north
        else:
            # Fallback primitive drawing
            ny1 = (i * 3) % (height // 2 - 40)
            cv2.rectangle(frame, (width//2 - 40, ny1), (width//2 - 10, ny1 + 30), (0, 200, 0), -1)
            sy1 = height - (i * 4) % (height // 2 - 40) - 30
            cv2.rectangle(frame, (width//2 + 10, sy1), (width//2 + 40, sy1 + 30), (255, 100, 0), -1)
            ex1 = width - (i * 5) % (width // 2 - 40) - 40
            cv2.rectangle(frame, (ex1, height//2 - 40), (ex1 + 40, height//2 - 10), (0, 165, 255), -1)
            wx1 = (i * 4) % (width // 2 - 40)
            cv2.rectangle(frame, (wx1, height//2 + 10), (wx1 + 40, height//2 + 40), (0, 0, 255), -1)

        # Frame indicator text
        cv2.putText(frame, f"VegMitra Test Traffic Video Frame {i+1}", (15, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
        out.write(frame)

    out.release()
    print(f"[Sample Video Generator] Created video successfully at: {os.path.abspath(output_path)}")


if __name__ == "__main__":
    create_traffic_sample_video()
