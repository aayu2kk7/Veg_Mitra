"""
VegMitra - 4-Direction Traffic Vision & Signal Allocator
Integrates the fine-tuned YOLOv8 model (Epoch 60 checkpoint) to run inference
on 4 intersection approach images (North, South, East, West) and compute the
optimal green signal direction and timing.
"""

import os
import io
import time
import base64
import numpy as np
import cv2
from ultralytics import YOLO

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Candidate checkpoint paths (prefer the trained epoch 60 checkpoint)
CHECKPOINT_CANDIDATES = [
    os.path.join(BASE_DIR, "training", "runs", "traffic_finetune_from43_to60_20261101", "weights", "best.pt"),
    os.path.join(BASE_DIR, "training", "weights", "best.pt"),
    os.path.join(BASE_DIR, "yolov8n.pt")
]

CLASS_COLORS = {
    "car": (240, 160, 40),        # Cyan/Sky blue in BGR
    "motorcycle": (30, 210, 255), # Yellow in BGR
    "bus": (30, 140, 255),        # Orange in BGR
    "truck": (210, 60, 210)       # Purple/Magenta in BGR
}
DEFAULT_COLOR = (0, 230, 120)     # Mint green in BGR

VEHICLE_WEIGHTS = {
    "car": 1.0,
    "motorcycle": 0.6,
    "bus": 2.5,
    "truck": 2.2
}


class TrafficModelAnalyzer:
    _instance = None

    def __init__(self):
        self.model = None
        self.model_path = None
        self.cached_results = {
            "North": {"count": 8, "density": 26.7, "weighted_load": 8.0, "classes": {"car": 5, "motorcycle": 2, "bus": 0, "truck": 1}, "boxes": [], "annotated_image": ""},
            "South": {"count": 14, "density": 46.7, "weighted_load": 14.0, "classes": {"car": 8, "motorcycle": 0, "bus": 0, "truck": 6}, "boxes": [], "annotated_image": ""},
            "East": {"count": 29, "density": 96.7, "weighted_load": 30.5, "classes": {"car": 28, "motorcycle": 0, "bus": 1, "truck": 0}, "boxes": [], "annotated_image": ""},
            "West": {"count": 20, "density": 66.7, "weighted_load": 20.0, "classes": {"car": 20, "motorcycle": 0, "bus": 0, "truck": 0}, "boxes": [], "annotated_image": ""}
        }
        self.current_green_road = "East"
        now = time.time()
        self.last_green_time = {
            "North": now - 60.0,
            "South": now - 45.0,
            "East": now,
            "West": now - 30.0
        }
        self.wait_time_weight = 0.1  # alpha = 0.1: each 10s of wait time adds +1.0 virtual vehicle priority
        self._load_initial_samples()
        self._load_model()

    def _load_initial_samples(self):
        sample_path = os.path.join(BASE_DIR, "frontend", "sample_analysis.json")
        if os.path.exists(sample_path):
            try:
                import json
                with open(sample_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    if "approaches" in data:
                        for rd in ["North", "South", "East", "West"]:
                            if rd in data["approaches"]:
                                self.cached_results[rd] = data["approaches"][rd]
                    if "selected_green_road" in data:
                        self.current_green_road = data["selected_green_road"]
            except Exception as e:
                print(f"[ModelAnalyzer] Sample analysis load note: {e}")

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def _load_model(self):
        for candidate in CHECKPOINT_CANDIDATES:
            if os.path.exists(candidate):
                try:
                    print(f"[ModelAnalyzer] Loading checkpoint: {candidate}")
                    self.model = YOLO(candidate)
                    self.model_path = candidate
                    print(f"[ModelAnalyzer] Model loaded successfully: {self.model.names}")
                    return
                except Exception as e:
                    print(f"[ModelAnalyzer] Error loading {candidate}: {e}")

        print("[ModelAnalyzer] Fallback to default yolov8n.pt")
        self.model = YOLO("yolov8n.pt")
        self.model_path = "yolov8n.pt"

    def decode_image(self, img_input):
        """Accepts numpy array, base64 string, bytes, or file path and returns OpenCV BGR image."""
        if isinstance(img_input, np.ndarray):
            return img_input

        if isinstance(img_input, str):
            if not img_input.strip():
                return None
            if os.path.exists(img_input):
                return cv2.imread(img_input)
            
            # Base64 string
            if "," in img_input:
                img_input = img_input.split(",", 1)[1]
            try:
                img_bytes = base64.b64decode(img_input)
                nparr = np.frombuffer(img_bytes, np.uint8)
                return cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            except Exception as e:
                print(f"[ModelAnalyzer] Failed to decode base64: {e}")
                return None
        elif isinstance(img_input, bytes):
            nparr = np.frombuffer(img_input, np.uint8)
            return cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        return None

    def encode_image(self, bgr_img, quality=85):
        """Encodes an OpenCV image to a base64 JPEG data URL."""
        success, buffer = cv2.imencode(".jpg", bgr_img, [int(cv2.IMWRITE_JPEG_QUALITY), quality])
        if not success:
            return ""
        b64_str = base64.b64encode(buffer).decode("utf-8")
        return f"data:image/jpeg;base64,{b64_str}"

    def analyze_single_direction(self, img_bgr, conf_threshold=0.25):
        """
        Runs YOLO inference on a single image, annotates detections,
        and computes vehicle counts and road density.
        """
        if not isinstance(img_bgr, np.ndarray):
            img_bgr = self.decode_image(img_bgr)

        if img_bgr is None:
            return {
                "count": 0,
                "density": 0.0,
                "weighted_load": 0.0,
                "classes": {"car": 0, "motorcycle": 0, "bus": 0, "truck": 0},
                "boxes": [],
                "annotated_image": ""
            }

        annotated = img_bgr.copy()
        h, w = annotated.shape[:2]

        results = self.model(img_bgr, conf=conf_threshold, verbose=False)[0]
        boxes = results.boxes

        counts_by_class = {"car": 0, "motorcycle": 0, "bus": 0, "truck": 0}
        box_records = []
        weighted_load = 0.0

        if boxes is not None and len(boxes) > 0:
            for box in boxes:
                conf = float(box.conf[0])
                if conf < conf_threshold:
                    continue
                cls_id = int(box.cls[0])
                cls_name = self.model.names.get(cls_id, "car").lower()
                
                # Standardize class name
                if "motor" in cls_name or "bike" in cls_name:
                    cls_name = "motorcycle"
                elif cls_name not in counts_by_class:
                    cls_name = "car"

                counts_by_class[cls_name] = counts_by_class.get(cls_name, 0) + 1
                weighted_load += VEHICLE_WEIGHTS.get(cls_name, 1.0)

                x1, y1, x2, y2 = map(int, box.xyxy[0])
                box_records.append({
                    "class": cls_name,
                    "confidence": round(conf, 2),
                    "bbox": [x1, y1, x2, y2]
                })

                # Draw bounding box on annotated image
                color = CLASS_COLORS.get(cls_name, DEFAULT_COLOR)
                cv2.rectangle(annotated, (x1, y1), (x2, y2), color, 2)

                # Label
                label = f"{cls_name.upper()} {conf:.2f}"
                font = cv2.FONT_HERSHEY_SIMPLEX
                font_scale = 0.5
                thickness = 1
                (tw, th), baseline = cv2.getTextSize(label, font, font_scale, thickness)
                cv2.rectangle(annotated, (x1, max(y1 - th - 6, 0)), (x1 + tw + 6, max(y1, th + 6)), color, -1)
                cv2.putText(annotated, label, (x1 + 3, max(y1 - 4, th)), font, font_scale, (0, 0, 0), thickness, cv2.LINE_AA)

        total_vehicles = sum(counts_by_class.values())
        capacity = 30.0  # Standard per-approach vehicle capacity
        density_pct = min(100.0, round((total_vehicles / capacity) * 100.0, 1))

        # Add HUD banner to top of annotated image
        hud_h = 36
        hud_overlay = annotated.copy()
        cv2.rectangle(hud_overlay, (0, 0), (w, hud_h), (15, 23, 42), -1)
        cv2.addWeighted(hud_overlay, 0.75, annotated, 0.25, 0, annotated)
        hud_text = f"DETECTIONS: {total_vehicles} veh | DENSITY: {density_pct:.1f}% | C:{counts_by_class['car']} M:{counts_by_class['motorcycle']} B:{counts_by_class['bus']} T:{counts_by_class['truck']}"
        cv2.putText(annotated, hud_text, (10, 24), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (255, 255, 255), 1, cv2.LINE_AA)

        annotated_b64 = self.encode_image(annotated)

        return {
            "count": total_vehicles,
            "density": density_pct,
            "weighted_load": round(weighted_load, 1),
            "classes": counts_by_class,
            "boxes": box_records,
            "annotated_image": annotated_b64
        }

    def evaluate_signal_decision(self, exclude_road=None):
        """
        Evaluates current 4-approach traffic states.
        Allocates GREEN light based on Weighted Fair Queuing (Vehicle Count + Waiting Time Aging).
        Priority Formula: Score = Count + (alpha * Wait_Seconds), where alpha = 0.1
        If exclude_road is specified (e.g. green phase timer expired):
          - Excludes exclude_road to prevent starvation.
          - Iterates through remaining candidate roads in strict CLOCKWISE sequence starting after exclude_road.
          - Highest priority score wins.
          - When priority scores are identical (tie): next in clockwise sequence wins.
        All other directions are set to RED.
        Detects if the active green signal toggled to a different road.
        """
        now = time.time()
        clockwise_roads = ["North", "East", "South", "West"]

        if exclude_road:
            clean_exclude = exclude_road.strip().capitalize()
            if clean_exclude in clockwise_roads:
                idx = clockwise_roads.index(clean_exclude)
                # Next candidate roads in strict clockwise sequence starting immediately after exclude_road
                candidate_roads = [clockwise_roads[(idx + i) % 4] for i in range(1, 4)]
            else:
                candidate_roads = [r for r in clockwise_roads if r.lower() != exclude_road.strip().lower()]
        else:
            candidate_roads = list(clockwise_roads)

        # Calculate decision-time wait metrics and priority scores for all approaches
        approach_metrics = {}
        for r in clockwise_roads:
            stats = self.cached_results.get(r, {"count": 0, "weighted_load": 0.0})
            count = stats.get("count", 0)
            load = stats.get("weighted_load", 0.0)
            w_secs = int(max(0.0, now - self.last_green_time.get(r, now)))
            w_boost = round(w_secs * self.wait_time_weight, 1)
            p_score = round(count + w_boost, 1)
            approach_metrics[r] = {
                "wait_seconds": w_secs,
                "wait_boost": w_boost,
                "priority_score": p_score,
                "count": count,
                "weighted_load": load
            }

        best_road = candidate_roads[0]
        highest_priority = -1.0
        highest_load = -1.0

        for road in candidate_roads:
            m = approach_metrics[road]
            p_score = m["priority_score"]
            load = m["weighted_load"]

            # Primary criterion: Maximum priority score (Vehicle count + alpha * waiting seconds)
            # Secondary criterion: Higher weighted load
            # Clockwise iteration order breaks ties naturally since candidate_roads is ordered clockwise
            if p_score > highest_priority or (p_score == highest_priority and load > highest_load):
                highest_priority = p_score
                highest_load = load
                best_road = road

        previous_green = self.current_green_road
        toggled = (previous_green is not None and previous_green != best_road)
        self.current_green_road = best_road
        # Reset wait time for the newly chosen green road
        self.last_green_time[best_road] = now

        best_count = self.cached_results.get(best_road, {}).get("count", 0)
        # Dynamic Green Time Allocation (15s - 60s) based on vehicle count
        allocated_green_seconds = int(np.clip(12 + (best_count * 2.2), 15, 60))

        # Selected road is GREEN, all others are RED
        signals = {r: ("GREEN" if r == best_road else "RED") for r in clockwise_roads}

        # Build approach stats with wait metrics
        approaches_with_metrics = {}
        for r in clockwise_roads:
            r_stats = dict(self.cached_results.get(r, {}))
            m = approach_metrics[r]
            r_stats["wait_seconds"] = m["wait_seconds"]
            r_stats["wait_boost"] = m["wait_boost"]
            r_stats["priority_score"] = m["priority_score"]
            approaches_with_metrics[r] = r_stats

        best_stats = approaches_with_metrics.get(best_road, {})
        classes_str = ", ".join([f"{v} {k}s" for k, v in best_stats.get("classes", {}).items() if v > 0]) or "0 vehicles"
        other_scores_str = ", ".join([f"{r}: score {approaches_with_metrics[r].get('priority_score', 0)} ({approaches_with_metrics[r].get('count', 0)} veh, {approaches_with_metrics[r].get('wait_seconds', 0)}s wait)" for r in clockwise_roads if r != best_road])

        if exclude_road:
            action_text = f"PHASE ROTATED (ANTI-STARVATION & WAIT-TIME AGING): GREEN TRANSFERRED FROM {exclude_road.upper()} TO {best_road.upper()}"
            reason_prefix = f"Timer expired on {exclude_road.upper()} corridor (held RED). "
        elif toggled:
            action_text = f"SIGNAL TOGGLED: GREEN SWITCHED FROM {previous_green.upper()} TO {best_road.upper()}"
            reason_prefix = ""
        else:
            action_text = f"GREEN SIGNAL ACTIVE ON {best_road.upper()}"
            reason_prefix = ""

        decision_reason = (
            f"{action_text} - {reason_prefix}Selected approach traffic: {best_stats.get('count', 0)} veh "
            f"({classes_str}) with priority score {highest_priority:.1f} (waited {best_stats.get('wait_seconds', 0)}s, density {best_stats.get('density', 0.0)}%). "
            f"Allocating {allocated_green_seconds}s clearance time. Other approaches ({other_scores_str}) held at RED."
        )

        return {
            "selected_green_road": best_road,
            "previous_green_road": previous_green,
            "toggled": toggled,
            "green_time_seconds": allocated_green_seconds,
            "decision_reason": decision_reason,
            "signals": signals,
            "approaches": approaches_with_metrics,
            "model_checkpoint": os.path.basename(self.model_path or "yolov8n.pt")
        }

    def rotate_phase_after_timer(self, current_road=None):
        """
        Called when the green light timer expires for current_road.
        Excludes current_road to handle starvation, selects the next appropriate road
        (highest density if different, clockwise next if same), and returns the new decision.
        """
        cur = current_road or self.current_green_road or "North"
        return self.evaluate_signal_decision(exclude_road=cur)

    def analyze_single_road(self, road, image_input, conf_threshold=0.25):
        """
        Analyzes a newly uploaded photo for a single road, updates that road's real count & density,
        re-evaluates all 4 roads, and assigns GREEN to the road with the maximum vehicles.
        """
        clean_road = road.strip().capitalize()
        if clean_road not in ["North", "South", "East", "West"]:
            # Match case-insensitively
            for r in ["North", "South", "East", "West"]:
                if r.lower() == road.strip().lower():
                    clean_road = r
                    break
            else:
                clean_road = "North"

        analysis = self.analyze_single_direction(image_input, conf_threshold=conf_threshold)
        self.cached_results[clean_road] = analysis
        return self.evaluate_signal_decision()

    def analyze_four_directions(self, images_dict, conf_threshold=0.25):
        """
        Analyzes provided images from 4 directions (North, South, East, West).
        Updates real counts and densities, determines which approach has max vehicles,
        and assigns GREEN accordingly.
        """
        roads = ["North", "South", "East", "West"]

        for road in roads:
            raw_input = images_dict.get(road) or images_dict.get(road.lower())
            if raw_input:
                analysis = self.analyze_single_direction(raw_input, conf_threshold=conf_threshold)
                self.cached_results[road] = analysis

        return self.evaluate_signal_decision()
