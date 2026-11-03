import os
import sys
import json
import time
import cv2
from detector import VehicleDetector


def export_traffic_state(stats: dict, output_paths: list):
    """
    Exports the current frame traffic statistics to JSON files
    so MATLAB (VegMitraApp.m) and external listeners can consume real-time state.
    """
    payload = {
        "timestamp": time.time(),
        "frame_index": stats.get("frame_index", 0),
        "counts": stats.get("counts", {}),
        "smoothed_counts": stats.get("smoothed_counts", {}),
        "density": stats.get("density", {}),
        "selected_green_road": stats.get("selected_green_road", "North"),
        "emergency_active": stats.get("emergency_active", False),
        "emergency_road": stats.get("emergency_road", None),
        "emergency_class": stats.get("emergency_class", None),
        "total_vehicles": stats.get("total_vehicles", 0),
        "green_hold_remaining": stats.get("green_hold_remaining", 0)
    }

    for path in output_paths:
        try:
            os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
            temp_path = path + ".tmp"
            with open(temp_path, "w") as f:
                json.dump(payload, f, indent=2)
            os.replace(temp_path, path)
        except Exception as e:
            pass


def main():
    input_video_path = os.path.join("videos", "traffic.mp4")
    output_dir = "output"
    output_video_path = os.path.join(output_dir, "detected_traffic.mp4")

    # State JSON bridge destinations (local output & MATLAB directory)
    json_bridge_paths = [
        os.path.join(output_dir, "traffic_state.json"),
        os.path.join("VegMitra_MATLAB", "traffic_state.json")
    ]

    print("==================================================")
    print("         VegMitra - AI Adaptive Traffic System    ")
    print("      YOLO Road-Wise Density & Emergency Pipeline ")
    print("==================================================")

    # 1. Check input video file
    if not os.path.exists(input_video_path):
        print(f"\n[INPUT REQUIRED] Video file not found at: '{input_video_path}'")
        print("Please place your video file at 'videos/traffic.mp4' and run 'python main.py' again.\n")
        sys.exit(0)

    # 2. Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)

    # Configurable model path: check command-line argument, env var, or fallback
    # Note: training/weights/best.pt has mAP=0.0 due to 5-epoch underfitting; default to yolov8n.pt unless explicitly requested
    model_path = os.environ.get("VEGMITRA_MODEL")
    if len(sys.argv) > 1 and not sys.argv[1].startswith("--"):
        model_path = sys.argv[1]
    
    if not model_path:
        best_candidate = os.path.join("training", "weights", "best.pt")
        # Check if user specifically requested best.pt or if yolov8n.pt is available
        if os.path.exists("yolov8n.pt"):
            model_path = "yolov8n.pt"
        elif os.path.exists(best_candidate):
            model_path = best_candidate
        else:
            model_path = "yolov8n.pt"

    print(f"\n[Model Configuration]")
    print(f"  Model Path: {os.path.abspath(model_path)}")
    print(f"  Confidence Threshold: 0.25")
    print(f"  IoU / NMS Threshold: 0.45")
    print(f"  Input Resolution: 640x480")

    # 3. Initialize VehicleDetector
    try:
        detector = VehicleDetector(
            model_name=model_path,
            window_size=10,
            min_green_duration=1.5,
            switch_threshold=2.0
        )

    except Exception as e:
        print(f"[ERROR] Failed to load YOLO model: {e}")
        sys.exit(1)

    # 4. Open Video Capture Stream
    cap = cv2.VideoCapture(input_video_path)
    if not cap.isOpened():
        print(f"[ERROR] Could not open video file: '{input_video_path}'")
        sys.exit(1)

    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = cap.get(cv2.CAP_PROP_FPS)
    if fps <= 0 or fps != fps:
        fps = 25.0
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    print(f"\n[Video Info] Source: {input_video_path}")
    print(f"[Video Info] Resolution: {width}x{height} | FPS: {fps:.2f} | Total Frames: {total_frames}")
    print(f"[Output Info] Saving video to: {output_video_path}")
    print(f"[Bridge Info] Exporting state JSON for MATLAB at: {json_bridge_paths[1]}\n")

    # 5. Setup Video Writer
    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
    out = cv2.VideoWriter(output_video_path, fourcc, fps, (width, height))

    frame_index = 0
    display_enabled = True
    log_interval = max(1, int(fps))  # Log formatted summary once every second

    try:
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            frame_index += 1

            # Video stream timestamp (seconds) based on frame index and FPS
            video_time = (frame_index - 1) / fps

            # Process frame using detector with calibrated confidence threshold and video timing
            annotated_frame, stats = detector.process_frame(frame, conf_threshold=0.25, frame_time=video_time)

            # Frame 1 diagnostic reporting
            if frame_index == 1:
                print(f"[Frame 1 Diagnostics]")
                print(f"  Raw detections before filter: {stats.get('raw_detections', 0)}")
                print(f"  Vehicles after class filter: {stats.get('filtered_detections', 0)}")
                print(f"  Detection status: {stats.get('detection_status', 'NORMAL')}")

            # Export structured state to JSON bridge for MATLAB
            export_traffic_state(stats, json_bridge_paths)

            # Write frame to output video
            out.write(annotated_frame)

            # Periodic console log summary (every 1 second of video time)
            if frame_index == 1 or frame_index % log_interval == 0 or stats["emergency_active"]:
                c = stats["counts"]
                sm = stats["smoothed_counts"]
                d = stats["density"]
                green = stats["selected_green_road"]
                emerg = "ACTIVE" if stats["emergency_active"] else "INACTIVE"

                print(f"--- Frame {frame_index}/{total_frames} ---")
                print(f"Vehicle counts:")
                print(f"  North: {c['North']} | South: {c['South']} | East: {c['East']} | West: {c['West']}")
                print(f"Smoothed counts:")
                print(f"  North: {sm['North']} | South: {sm['South']} | East: {sm['East']} | West: {sm['West']}")
                print(f"Density:")
                print(f"  North: {d['North']}% | South: {d['South']}% | East: {d['East']}% | West: {d['West']}%")
                print(f"Decision:")
                print(f"  GREEN: {green}")
                print(f"Emergency:")
                print(f"  {emerg}")
                if stats["emergency_active"]:
                    print(f"  Class: {stats['emergency_class']} | Road: {stats['emergency_road']}")
                print("-" * 35)

            # Display video window if supported
            if display_enabled:
                try:
                    cv2.imshow("VegMitra - AI Adaptive Traffic Control", annotated_frame)
                    key = cv2.waitKey(1) & 0xFF
                    if key == ord('q'):
                        print("\n[User Interrupted] 'q' pressed. Stopping...")
                        break
                except cv2.error:
                    display_enabled = False

    except KeyboardInterrupt:
        print("\n[User Interrupted] Stopping processing...")
    finally:
        cap.release()
        out.release()
        cv2.destroyAllWindows()

    print(f"\n[COMPLETED] Processing finished successfully!")
    print(f"[COMPLETED] Output video saved to: {os.path.abspath(output_video_path)}")


if __name__ == "__main__":
    main()
