import os
import time
from pathlib import Path
import cv2
import numpy as np
from ultralytics import YOLO

def predict_on_unseen(
    video_path='videos/traffic.mp4',
    model_path='training/weights/best.pt',
    output_video_path='training/results/unseen_prediction.mp4',
    conf_threshold=0.25
):
    print('==================================================')
    print('      VegMitra Inference on Unseen Traffic Video   ')
    print('==================================================')
    
    if not os.path.exists(video_path):
        print(f'[Error] Video file not found: {video_path}')
        return

    print(f'[Predict] Loading Model: {model_path}')
    print(f'[Predict] Video Source:  {video_path}')
    model = YOLO(model_path)

    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print(f'[Error] Cannot open video stream {video_path}')
        return

    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = cap.get(cv2.CAP_PROP_FPS) or 25.0
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    Path(output_video_path).parent.mkdir(parents=True, exist_ok=True)
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(output_video_path, fourcc, fps, (width, height))

    frame_idx = 0
    total_time = 0.0
    detected_classes_count = {}

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        frame_idx += 1

        t0 = time.time()
        results = model.predict(frame, conf=conf_threshold, verbose=False)[0]
        dt = time.time() - t0
        total_time += dt

        annotated_frame = results.plot()
        
        # Count classes
        for box in results.boxes:
            cid = int(box.cls[0])
            cname = model.names.get(cid, str(cid))
            detected_classes_count[cname] = detected_classes_count.get(cname, 0) + 1

        # Draw FPS overlay
        inst_fps = 1.0 / dt if dt > 0 else 0.0
        cv2.putText(
            annotated_frame,
            f'Model: {Path(model_path).name} | FPS: {inst_fps:.1f}',
            (20, 30),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (0, 255, 0),
            2
        )

        out.write(annotated_frame)

    cap.release()
    out.release()

    avg_fps = (frame_idx / total_time) if total_time > 0 else 0.0
    print(f'[Done] Processed {frame_idx} frames in {total_time:.2f}s ({avg_fps:.1f} FPS)')
    print(f'[Done] Detections across video: {detected_classes_count}')
    print(f'[Done] Saved output to: {output_video_path}')

if __name__ == '__main__':
    predict_on_unseen()
