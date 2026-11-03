import time
import cv2
import numpy as np

try:
    from ultralytics import YOLO
except ImportError:
    YOLO = None


class VehicleDetector:
    """
    VehicleDetector implements true 4-road incoming-traffic-based adaptive signal control.
    It tracks vehicles across frames, separates incoming vs. outgoing lanes, measures distance delta
    to the intersection center to classify movement as INCOMING, OUTGOING, or UNKNOWN, counts only
    active incoming vehicles, calculates smoothed traffic density, enforces real-time minimum green hold (10s)
    and hysteresis (10%), prioritizes emergency vehicles, and selects EXACTLY ONE physical road for GREEN.

    NOTE: Designed for simulation, project demonstration, and evaluation.
    """

    TARGET_CLASSES = {"car", "motorcycle", "bus", "truck"}
    EMERGENCY_CLASSES = {"ambulance", "fire truck", "police", "emergency", "fire engine"}
    ROADS = ["North", "South", "East", "West"]

    def __init__(
        self,
        model_name: str = "yolov8n.pt",
        road_geometry: dict = None,
        max_road_capacity: dict = None,
        window_size: int = 10,
        min_green_duration: float = 10.0,
        switch_threshold: float = 10.0
    ):
        """
        Initialize the VehicleDetector.

        :param model_name: Path or string for Ultralytics YOLO model.
        :param road_geometry: Dict containing ROI polygons for incoming/outgoing lanes & intersection center.
        :param max_road_capacity: Dict of maximum vehicle capacity per road approach.
        :param window_size: Rolling window size (in frames) for moving average smoothing.
        :param min_green_duration: Minimum real-time duration (seconds) to hold a green signal.
        :param switch_threshold: Minimum density percentage advantage (hysteresis) required to switch green signals.
        """
        print(f"[VehicleDetector] Loading pretrained YOLO model: {model_name}...")
        self.model_name = model_name
        if YOLO is not None:
            self.model = YOLO(model_name)
        else:
            self.model = None

        # Inspect model class names and IDs
        self.model_classes = {}
        if self.model is not None and hasattr(self.model, "names") and isinstance(self.model.names, dict):
            self.model_classes = self.model.names
            print(f"[VehicleDetector] Loaded model classes ({len(self.model_classes)} classes):")
            for cid, cname in sorted(self.model_classes.items()):
                if cid < 10 or cname in self.TARGET_CLASSES or any(ec in cname for ec in self.EMERGENCY_CLASSES):
                    print(f"  ID {cid}: '{cname}'")

        # Check vehicle and emergency class coverage
        present_vehicles = [name for name in self.model_classes.values() if name.lower() in self.TARGET_CLASSES]
        present_emergency = [name for name in self.model_classes.values() if any(ec in name.lower() for ec in self.EMERGENCY_CLASSES)]
        print(f"[VehicleDetector] Vehicle classes supported: {present_vehicles if present_vehicles else 'None'}")
        if present_emergency:
            print(f"[VehicleDetector] Emergency classes detected in model: {present_emergency}")
        else:
            print(f"[VehicleDetector] [NOTE] Emergency classes absent in model weights ({model_name}). Emergency priority logic preserved for external/synthetic triggers.")

        self.road_geometry = road_geometry or {}
        self.max_road_capacity = max_road_capacity or {road: 30 for road in self.ROADS}
        self.window_size = max(1, window_size)
        self.min_green_duration = max(0.0, float(min_green_duration))
        self.switch_threshold = float(switch_threshold)

        # Persistent track history: {track_id: [(cx, cy, frame_idx, dist_to_center), ...]}
        self.track_history = {}
        self.max_history_len = 15

        # Rolling history buffer for incoming vehicle counts per road
        self.count_history = []

        # Real-time signal state tracking
        self.current_green_road = "North"
        self.green_start_time = time.time()
        self.frame_counter = 0
        self.tie_break_index = 0  # Fair round-robin pointer for tie breaking and zero-traffic schedule

        # Movement threshold (pixels) to avoid detection jitter
        self.movement_threshold = 3.0

        # Color mapping (BGR)
        self.colors = {
            "car": (0, 255, 0),          # Green
            "motorcycle": (255, 165, 0),  # Cyan
            "bus": (0, 165, 255),        # Orange
            "truck": (0, 0, 255),        # Red
            "emergency": (255, 0, 255)    # Magenta
        }
        self.default_color = (255, 255, 255)

    def _get_default_geometry(self, frame_width: int, frame_height: int) -> dict:
        """
        Creates default geometry separating incoming and outgoing lane ROIs for North, South, East, West
        aligned with standard cross intersection layout.
        """
        cx = frame_width / 2.0
        cy = frame_height / 2.0
        w = float(frame_width)
        h = float(frame_height)

        return {
            "center": (cx, cy),
            "North_Incoming": [(cx - 80, 0), (cx, 0), (cx, cy - 50), (cx - 80, cy - 50)],
            "North_Outgoing": [(cx, 0), (cx + 80, 0), (cx + 80, cy - 50), (cx, cy - 50)],
            "South_Incoming": [(cx, cy + 50), (cx + 80, cy + 50), (cx + 80, h), (cx, h)],
            "South_Outgoing": [(cx - 80, cy + 50), (cx, cy + 50), (cx, h), (cx - 80, h)],
            "East_Incoming": [(cx + 50, cy), (w, cy), (w, cy + 80), (cx + 50, cy + 80)],
            "East_Outgoing": [(cx + 50, cy - 80), (w, cy - 80), (w, cy), (cx + 50, cy)],
            "West_Incoming": [(0, cy - 80), (cx - 50, cy - 80), (cx - 50, cy), (0, cy)],
            "West_Outgoing": [(0, cy), (cx - 50, cy), (cx - 50, cy + 80), (0, cy + 80)]
        }

    def point_in_polygon(self, px: float, py: float, polygon: list) -> bool:
        """Check if point (px, py) is inside polygon coordinates."""
        if not polygon:
            return False
        pts = np.array(polygon, dtype=np.int32)
        return cv2.pointPolygonTest(pts, (float(px), float(py)), False) >= 0

    def classify_vehicle_movement(self, track_id: int, cx: float, cy: float, frame_width: int, frame_height: int, geom: dict):
        """
        Classifies tracked vehicle as ('North'|'South'|'East'|'West', 'INCOMING'|'OUTGOING'|'UNKNOWN').
        Measures distance delta relative to intersection center & lane ROIs.
        """
        center_x, center_y = geom.get("center", (frame_width / 2.0, frame_height / 2.0))
        curr_dist = float(np.hypot(cx - center_x, cy - center_y))

        # Check ROI polygons first
        assigned_road = None
        assigned_lane = None

        for road in self.ROADS:
            inc_key = f"{road}_Incoming"
            out_key = f"{road}_Outgoing"
            if self.point_in_polygon(cx, cy, geom.get(inc_key, [])):
                assigned_road = road
                assigned_lane = "INCOMING"
                break
            elif self.point_in_polygon(cx, cy, geom.get(out_key, [])):
                assigned_road = road
                assigned_lane = "OUTGOING"
                break

        # Fallback road assignment if outside specific polygon
        if assigned_road is None:
            dx = cx - center_x
            dy = cy - center_y
            if abs(dx) >= abs(dy):
                assigned_road = "East" if dx >= 0 else "West"
            else:
                assigned_road = "South" if dy >= 0 else "North"

        # Track history analysis for movement direction
        history = self.track_history.get(track_id, [])
        if len(history) < 2:
            movement_state = assigned_lane if assigned_lane else "UNKNOWN"
        else:
            prev_cx, prev_cy, _, prev_dist = history[0]
            dist_delta = prev_dist - curr_dist  # Positive = moving toward center (approaching)

            if dist_delta > self.movement_threshold:
                movement_state = "INCOMING"
            elif dist_delta < -self.movement_threshold:
                movement_state = "OUTGOING"
            else:
                movement_state = assigned_lane if assigned_lane else "UNKNOWN"

        return assigned_road, movement_state, curr_dist

    def process_frame(self, frame: np.ndarray, conf_threshold: float = 0.25, frame_time: float = None):
        """
        Processes a single video frame with YOLO tracking, classifies INCOMING vs OUTGOING vehicles,
        computes active incoming counts & densities, enforces real-time min green duration & hysteresis,
        selects EXACTLY ONE physical road for GREEN, and outputs (annotated_frame, stats_dict).
        """
        self.frame_counter += 1
        curr_time = time.time() if frame_time is None else float(frame_time)
        annotated_frame = frame.copy()
        height, width = frame.shape[:2]

        geom = self.road_geometry if self.road_geometry else self._get_default_geometry(width, height)
        center_x, center_y = geom.get("center", (width / 2.0, height / 2.0))

        # Active incoming vehicle counts per road
        incoming_counts = {road: 0 for road in self.ROADS}
        active_incoming_tracks = {road: set() for road in self.ROADS}
        class_counts = {cls_name: 0 for cls_name in self.TARGET_CLASSES}
        emergency_detections = []

        boxes_to_process = []
        raw_detections_count = 0
        filtered_vehicles_count = 0
        detection_status = "NORMAL"

        if self.model is not None:
            try:
                # Use Ultralytics tracking with configured confidence threshold
                results = self.model.track(frame, tracker="botsort.yaml", conf=conf_threshold, persist=True, verbose=False)[0]
                if results.boxes is not None and len(results.boxes) > 0:
                    raw_detections_count = len(results.boxes)
                    for box in results.boxes:
                        conf = float(box.conf[0])
                        if conf < conf_threshold:
                            continue
                        cls_id = int(box.cls[0])
                        cls_name = self.model.names.get(cls_id, "").lower()
                        track_id = int(box.id[0]) if box.id is not None else int(time.time() * 1000) % 100000
                        x1, y1, x2, y2 = map(int, box.xyxy[0])
                        boxes_to_process.append((x1, y1, x2, y2, conf, cls_name, track_id))
            except Exception as track_err:
                # Fallback to standard inference
                try:
                    results = self.model(frame, conf=conf_threshold, verbose=False)[0]
                    if results.boxes is not None and len(results.boxes) > 0:
                        raw_detections_count = len(results.boxes)
                        for idx, box in enumerate(results.boxes):
                            conf = float(box.conf[0])
                            if conf < conf_threshold:
                                continue
                            cls_id = int(box.cls[0])
                            cls_name = self.model.names.get(cls_id, "").lower()
                            x1, y1, x2, y2 = map(int, box.xyxy[0])
                            # Generate deterministic centroid track ID
                            cx_val = (x1 + x2) // 2
                            cy_val = (y1 + y2) // 2
                            track_id = (cx_val * 1000 + cy_val) % 9000 + 1000
                            boxes_to_process.append((x1, y1, x2, y2, conf, cls_name, track_id))
                except Exception as infer_err:
                    detection_status = "DETECTION_UNAVAILABLE"
                    print(f"[VehicleDetector] [WARNING] Detection unavailable on frame {self.frame_counter}: {infer_err}")
        else:
            detection_status = "DETECTION_UNAVAILABLE"

        current_frame_tracks = set()

        for x1, y1, x2, y2, conf, cls_name, track_id in boxes_to_process:
            is_emergency = any(e_cls in cls_name for e_cls in self.EMERGENCY_CLASSES)
            if not is_emergency and cls_name not in self.TARGET_CLASSES:
                continue

            filtered_vehicles_count += 1
            cx = (x1 + x2) / 2.0
            cy = (y1 + y2) / 2.0
            curr_dist = float(np.hypot(cx - center_x, cy - center_y))

            # Update track history
            if track_id not in self.track_history:
                self.track_history[track_id] = []
            self.track_history[track_id].append((cx, cy, self.frame_counter, curr_dist))
            if len(self.track_history[track_id]) > self.max_history_len:
                self.track_history[track_id].pop(0)

            current_frame_tracks.add(track_id)

            # Classify road & movement direction
            road, movement_state, _ = self.classify_vehicle_movement(track_id, cx, cy, width, height, geom)

            if is_emergency:
                emergency_detections.append({
                    "road": road,
                    "class": cls_name,
                    "confidence": conf,
                    "track_id": track_id
                })
                color = self.colors["emergency"]
            else:
                class_counts[cls_name] += 1
                color = self.colors.get(cls_name, self.default_color)
                if movement_state == "INCOMING":
                    incoming_counts[road] += 1
                    active_incoming_tracks[road].add(track_id)

            # Draw visual debug annotations
            cv2.rectangle(annotated_frame, (x1, y1), (x2, y2), color, 2)
            cv2.circle(annotated_frame, (int(cx), int(cy)), 4, color, -1)

            # Movement arrow vector
            history = self.track_history[track_id]
            if len(history) >= 2:
                prev_cx, prev_cy = history[0][0], history[0][1]
                cv2.arrowedLine(annotated_frame, (int(prev_cx), int(prev_cy)), (int(cx), int(cy)), (0, 255, 255), 2, tipLength=0.3)

            # Label format: "#17 CAR EAST INCOMING"
            label = f"#{track_id} {cls_name.upper()} {road.upper()} {movement_state}"
            font = cv2.FONT_HERSHEY_SIMPLEX
            font_scale = 0.4
            thickness = 1
            (text_w, text_h), baseline = cv2.getTextSize(label, font, font_scale, thickness)

            label_y1 = max(y1 - text_h - 6, 0)
            label_y2 = label_y1 + text_h + 6
            label_x2 = x1 + text_w + 6

            cv2.rectangle(annotated_frame, (x1, label_y1), (label_x2, label_y2), color, cv2.FILLED)
            text_color = (0, 0, 0) if color != (0, 0, 255) else (255, 255, 255)
            cv2.putText(annotated_frame, label, (x1 + 3, label_y2 - baseline - 2), font, font_scale, text_color, thickness, lineType=cv2.LINE_AA)

        # Cleanup stale track history
        stale_ids = [tid for tid in self.track_history if tid not in current_frame_tracks]
        for tid in stale_ids:
            if len(self.track_history[tid]) > 0 and (self.frame_counter - self.track_history[tid][-1][2]) > 30:
                del self.track_history[tid]

        # Update moving average rolling history
        self.count_history.append(incoming_counts.copy())
        if len(self.count_history) > self.window_size:
            self.count_history.pop(0)

        # Calculate smoothed incoming vehicle counts per road independently
        history_len = len(self.count_history)
        smoothed_counts = {}
        for road in self.ROADS:
            road_sum = sum(h[road] for h in self.count_history)
            smoothed_counts[road] = round(road_sum / history_len, 2)

        # Calculate traffic density percentage per road independently (capped at 100%)
        density = {}
        for road in self.ROADS:
            cap = max(1, self.max_road_capacity.get(road, 30))
            raw_density = (smoothed_counts[road] / cap) * 100.0
            density[road] = round(min(100.0, raw_density), 1)

        # Signal State & True 4-Way Single Road Selection Logic
        emergency_active = len(emergency_detections) > 0
        emergency_road = None
        emergency_class = None
        emergency_conf = None

        if emergency_active:
            best_emergency = max(emergency_detections, key=lambda x: x["confidence"])
            emergency_road = best_emergency["road"]
            emergency_class = best_emergency["class"]
            emergency_conf = best_emergency["confidence"]

            selected_green_road = emergency_road
            self.current_green_road = selected_green_road
            self.green_start_time = curr_time
        else:
            if self.green_start_time is None or (frame_time is not None and self.frame_counter == 1):
                self.green_start_time = curr_time

            elapsed_green_sec = curr_time - self.green_start_time

            max_dens = max(density.values())
            tied_roads = [r for r in self.ROADS if density[r] == max_dens]

            # Candidate selection with fair tie-breaking and safe zero-traffic schedule
            if len(tied_roads) == 1:
                candidate_road = tied_roads[0]
            else:
                # If current green is among the tied roads, keep it to preserve stability
                if self.current_green_road in tied_roads and elapsed_green_sec < self.min_green_duration:
                    candidate_road = self.current_green_road
                else:
                    # Fair round-robin progression across tied approaches
                    candidate_road = self.ROADS[self.tie_break_index % len(self.ROADS)]
                    if elapsed_green_sec >= self.min_green_duration:
                        # Advance round-robin pointer if we are ready to transition
                        self.tie_break_index = (self.tie_break_index + 1) % len(self.ROADS)

            candidate_density = density[candidate_road]
            current_density = density.get(self.current_green_road, 0.0)

            if self.current_green_road not in self.ROADS:
                self.current_green_road = candidate_road
                self.green_start_time = curr_time

            # Hold current green road for real-time min_green_duration
            if elapsed_green_sec < self.min_green_duration:
                selected_green_road = self.current_green_road
            else:
                # Apply hysteresis switch threshold (or switch on round-robin tie/equal density)
                if candidate_road != self.current_green_road:
                    if candidate_density >= (current_density + self.switch_threshold) or (candidate_density == current_density and max_dens == 0.0):
                        self.current_green_road = candidate_road
                        self.green_start_time = curr_time
                selected_green_road = self.current_green_road

        green_hold_remaining = max(0.0, round(self.min_green_duration - (curr_time - self.green_start_time), 1)) if not emergency_active else 0.0

        # Draw ROI Polygons & Intersection Center
        cv2.circle(annotated_frame, (int(center_x), int(center_y)), 6, (0, 255, 255), -1)
        for road in self.ROADS:
            inc_pts = geom.get(f"{road}_Incoming", [])
            out_pts = geom.get(f"{road}_Outgoing", [])
            if inc_pts:
                cv2.polylines(annotated_frame, [np.array(inc_pts, np.int32)], True, (0, 255, 0), 1, cv2.LINE_AA)
            if out_pts:
                cv2.polylines(annotated_frame, [np.array(out_pts, np.int32)], True, (0, 0, 255), 1, cv2.LINE_AA)

        # Top Visual Debugging HUD Panel
        hud_x, hud_y = 10, 10
        hud_w, hud_h = 300, 185
        overlay = annotated_frame.copy()
        cv2.rectangle(overlay, (hud_x, hud_y), (hud_x + hud_w, hud_y + hud_h), (0, 0, 0), -1)
        cv2.addWeighted(overlay, 0.65, annotated_frame, 0.35, 0, annotated_frame)
        cv2.rectangle(annotated_frame, (hud_x, hud_y), (hud_x + hud_w, hud_y + hud_h), (255, 255, 255), 1)

        cv2.putText(annotated_frame, "VEGMITRA TRUE 4-ROAD HUD", (hud_x + 10, hud_y + 20), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 255), 1, cv2.LINE_AA)

        line_y = hud_y + 40
        for road in self.ROADS:
            is_green = (road == selected_green_road)
            status_text = f"{road.upper()}: Inc={incoming_counts[road]} | Dens={density[road]}%"
            if is_green:
                status_text += " [GREEN]"
                color = (0, 255, 0)
            else:
                color = (200, 200, 200)

            cv2.putText(annotated_frame, status_text, (hud_x + 10, line_y), cv2.FONT_HERSHEY_SIMPLEX, 0.45, color, 1, cv2.LINE_AA)
            line_y += 22

        cv2.putText(annotated_frame, f"GREEN SIGNAL: {selected_green_road.upper()}", (hud_x + 10, line_y), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2, cv2.LINE_AA)

        if emergency_active:
            e_text = f"EMERGENCY PRIORITY {selected_green_road.upper()} GREEN"
            cv2.putText(annotated_frame, e_text, (hud_x + 10, line_y + 22), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (0, 0, 255), 2, cv2.LINE_AA)

        # Construct structured state output dictionary
        total_vehicles = sum(incoming_counts.values())
        stats_dict = {
            "counts": incoming_counts,
            "smoothed_counts": smoothed_counts,
            "density": density,
            "selected_green_road": selected_green_road,
            "emergency_active": emergency_active,
            "emergency_road": emergency_road,
            "emergency_class": emergency_class,
            "emergency_confidence": float(emergency_conf) if emergency_conf is not None else None,
            "total_vehicles": total_vehicles,
            "class_counts": class_counts,
            "frame_index": self.frame_counter,
            "green_hold_remaining": green_hold_remaining,
            "detection_status": detection_status,
            "raw_detections": raw_detections_count,
            "filtered_detections": filtered_vehicles_count,
            "North": {"incoming_count": incoming_counts["North"], "smoothed_count": smoothed_counts["North"], "density": density["North"]},
            "South": {"incoming_count": incoming_counts["South"], "smoothed_count": smoothed_counts["South"], "density": density["South"]},
            "East": {"incoming_count": incoming_counts["East"], "smoothed_count": smoothed_counts["East"], "density": density["East"]},
            "West": {"incoming_count": incoming_counts["West"], "smoothed_count": smoothed_counts["West"], "density": density["West"]}
        }

        return annotated_frame, stats_dict
