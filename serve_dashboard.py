#!/usr/bin/env python3
"""
VegMitra - AI Adaptive Traffic Signal Management System
Dashboard HTTP Server & Live 4-Direction AI Signal Decision Bridge

Provides:
- Static file serving for the frontend dashboard
- POST /api/analyze-4-directions: Runs trained YOLOv8 model on 4 uploaded direction photos
  (North, South, East, West) to detect vehicles and allocate the GREEN signal
- GET /api/sample-images: Preloaded sample test set traffic images for instant 1-click testing
- GET /api/traffic-state: Real-time telemetry bridge to output/traffic_state.json
"""

import os
import sys
import glob
import time
import json
import base64
import argparse
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Ensure .venv site-packages are accessible even if started from system Python
VENV_SITE_PACKAGES = os.path.join(BASE_DIR, ".venv", "Lib", "site-packages")
if os.path.exists(VENV_SITE_PACKAGES) and VENV_SITE_PACKAGES not in sys.path:
    sys.path.insert(0, VENV_SITE_PACKAGES)

FRONTEND_DIR = os.path.join(BASE_DIR, "frontend")
OUTPUT_JSON_PATH = os.path.join(BASE_DIR, "output", "traffic_state.json")
TEST_IMAGES_DIR = os.path.join(BASE_DIR, "data", "test", "images")

# Demo deployments deliberately avoid loading/downloading a model. Set
# VEGMITRA_DEMO_MODE=false when a trained checkpoint is available.
DEMO_MODE = os.environ.get("VEGMITRA_DEMO_MODE", "false").strip().lower() in {
    "1", "true", "yes", "on"
}

if DEMO_MODE:
    TrafficModelAnalyzer = None
else:
    try:
        from model_analyzer import TrafficModelAnalyzer
    except ImportError:
        TrafficModelAnalyzer = None


class VegMitraRequestHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=FRONTEND_DIR, **kwargs)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Accept")
        self.end_headers()

    def do_GET(self):
        clean_path = self.path.split("?")[0].rstrip("/")

        if clean_path == "/healthz":
            model_ready = False
            if TrafficModelAnalyzer is not None:
                instance = TrafficModelAnalyzer._instance
                model_ready = bool(instance and instance.model is not None)
            self.send_json_response({
                "status": "ok",
                "demo_mode": DEMO_MODE,
                "model_ready": model_ready
            })
            return

        if clean_path in ("/api/traffic-state", "/api/state", "/output/traffic_state.json"):
            self.serve_traffic_state()
            return

        if clean_path == "/api/sample-images":
            self.serve_sample_images()
            return

        if clean_path in ("", "/"):
            self.path = "/index.html"

        super().do_GET()

    def do_POST(self):
        clean_path = self.path.split("?")[0].rstrip("/")

        if clean_path in ("/api/analyze-single", "/api/analyze-road"):
            self.handle_analyze_single_road()
            return

        if clean_path in ("/api/analyze-4-directions", "/api/analyze-photos"):
            self.handle_analyze_four_directions()
            return

        if clean_path in ("/api/timer-expire", "/api/next-phase", "/api/rotate-phase"):
            self.handle_timer_expire()
            return

        self.send_error(404, "Endpoint not found")

    def serve_traffic_state(self):
        data = None
        if os.path.exists(OUTPUT_JSON_PATH):
            try:
                with open(OUTPUT_JSON_PATH, "r", encoding="utf-8") as f:
                    data = json.load(f)
            except Exception:
                pass

        if data is None:
            data = {
                "timestamp": None,
                "frame_index": 0,
                "counts": {"North": 0, "South": 0, "East": 0, "West": 0},
                "smoothed_counts": {"North": 0.0, "South": 0.0, "East": 0.0, "West": 0.0},
                "density": {"North": 0.0, "South": 0.0, "East": 0.0, "West": 0.0},
                "selected_green_road": "North",
                "emergency_active": False,
                "emergency_road": None,
                "emergency_class": None,
                "total_vehicles": 0,
                "green_hold_remaining": 0.0,
                "_bridge_status": "WAITING_FOR_PIPELINE"
            }

        self.send_json_response(data)

    def serve_sample_images(self):
        """Loads 4 test split images and returns them as base64 data URLs."""
        sample_dict = {}
        roads = ["North", "South", "East", "West"]
        
        # Pick 4 representative images from data/test/images
        img_files = glob.glob(os.path.join(TEST_IMAGES_DIR, "*.jpg"))
        
        if len(img_files) >= 4:
            for i, road in enumerate(roads):
                file_path = img_files[i % len(img_files)]
                try:
                    with open(file_path, "rb") as f:
                        b64 = base64.b64encode(f.read()).decode("utf-8")
                        sample_dict[road] = f"data:image/jpeg;base64,{b64}"
                except Exception as e:
                    print(f"Error loading sample image {file_path}: {e}")

        self.send_json_response({
            "status": "success",
            "samples": sample_dict
        })

    def handle_analyze_single_road(self):
        """
        Receives 1 base64 image for a specific road (North, South, East, West),
        executes YOLOv8 model inference on that image, updates that road's real count
        and density, evaluates which road now has the maximum vehicle volume,
        and returns the decision and updated 4-direction status.
        """
        try:
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length)
            payload = json.loads(body.decode("utf-8"))
        except Exception as e:
            self.send_error(400, f"Invalid JSON payload: {e}")
            return

        road = payload.get("road", "North")
        image = payload.get("image", "")
        conf_threshold = float(payload.get("conf", 0.25))

        if TrafficModelAnalyzer is None:
            self.send_model_unavailable()
            return

        analyzer = TrafficModelAnalyzer.get_instance()
        result = analyzer.analyze_single_road(road, image, conf_threshold=conf_threshold)
        self.update_traffic_state_file(result)
        self.send_json_response(result)

    def handle_analyze_four_directions(self):
        """
        Receives base64 images, executes YOLOv8 model inference,
        and returns detection counts, bounding box overlays, and
        the assigned green traffic light decision for the road with max vehicles.
        """
        try:
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length)
            payload = json.loads(body.decode("utf-8"))
        except Exception as e:
            self.send_error(400, f"Invalid JSON payload: {e}")
            return

        conf_threshold = float(payload.get("conf", 0.25))
        images = payload.get("images", {})

        if TrafficModelAnalyzer is None:
            self.send_model_unavailable()
            return

        analyzer = TrafficModelAnalyzer.get_instance()
        result = analyzer.analyze_four_directions(images, conf_threshold=conf_threshold)
        self.update_traffic_state_file(result)
        self.send_json_response(result)

    def handle_timer_expire(self):
        """
        Handles green light timer expiration.
        Excludes current road to prevent starvation and switches to the next appropriate road
        (highest density if different, clockwise next if same).
        """
        try:
            content_length = int(self.headers.get("Content-Length", 0))
            if content_length > 0:
                body = self.rfile.read(content_length)
                payload = json.loads(body.decode("utf-8"))
            else:
                payload = {}
        except Exception:
            payload = {}

        current_road = payload.get("current_road")
        if TrafficModelAnalyzer is None:
            self.send_model_unavailable()
            return

        analyzer = TrafficModelAnalyzer.get_instance()
        result = analyzer.rotate_phase_after_timer(current_road=current_road)
        self.update_traffic_state_file(result)
        self.send_json_response(result)

    def update_traffic_state_file(self, result):
        """Persists the real AI detection state to output/traffic_state.json for bridges & UI."""
        try:
            os.makedirs(os.path.dirname(OUTPUT_JSON_PATH), exist_ok=True)
            roads = ["North", "South", "East", "West"]
            approaches = result.get("approaches", {})
            counts = {r: approaches.get(r, {}).get("count", 0) for r in roads}
            density = {r: approaches.get(r, {}).get("density", 0.0) for r in roads}
            total = sum(counts.values())

            state = {
                "timestamp": time.time(),
                "counts": counts,
                "smoothed_counts": {r: float(counts[r]) for r in roads},
                "density": density,
                "wait_seconds": {r: approaches.get(r, {}).get("wait_seconds", 0) for r in roads},
                "priority_scores": {r: approaches.get(r, {}).get("priority_score", 0.0) for r in roads},
                "selected_green_road": result.get("selected_green_road", "North"),
                "signals": result.get("signals", {}),
                "emergency_active": False,
                "emergency_road": None,
                "emergency_class": None,
                "total_vehicles": total,
                "green_hold_remaining": float(result.get("green_time_seconds", 30)),
                "decision_reason": result.get("decision_reason", ""),
                "toggled": result.get("toggled", False),
                "_bridge_status": "REAL_AI_VISION_ACTIVE"
            }
            with open(OUTPUT_JSON_PATH, "w", encoding="utf-8") as f:
                json.dump(state, f, indent=2)
        except Exception as e:
            print(f"[Server] Failed to write traffic_state.json: {e}")

    def send_json_response(self, data, status_code=200):
        response_bytes = json.dumps(data).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(response_bytes)))
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(response_bytes)

    def send_model_unavailable(self):
        self.send_json_response({
            "error": "Image analysis is unavailable until the trained model is configured.",
            "code": "MODEL_NOT_CONFIGURED"
        }, status_code=503)

    def log_message(self, format, *args):
        # Clean log - suppress noisy traffic-state polling
        try:
            if len(args) > 0 and isinstance(args[0], str) and "/api/traffic-state" in args[0]:
                return
        except Exception:
            pass
        super().log_message(format, *args)


def run_server(port=8080):
    if not os.path.exists(FRONTEND_DIR):
        print(f"[ERROR] Frontend directory not found at: {FRONTEND_DIR}")
        sys.exit(1)

    # Initialize model early
    if TrafficModelAnalyzer is not None:
        print("[INIT] Warming up trained YOLOv8 model...")
        TrafficModelAnalyzer.get_instance()
    elif DEMO_MODE:
        print("[INIT] Demo mode enabled; YOLO inference is disabled until a checkpoint is configured.")

    server_address = ("", port)
    
    try:
        httpd = ThreadingHTTPServer(server_address, VegMitraRequestHandler)
    except OSError as e:
        if port == 8080:
            print(f"[NOTICE] Port 8080 in use, attempting fallback to port 8081...")
            return run_server(port=8081)
        print(f"[ERROR] Could not bind to port {port}: {e}")
        sys.exit(1)

    print("==================================================")
    print("      VegMitra 4-Direction Traffic AI Server      ")
    print("==================================================")
    print(f"  Local Dashboard:    http://localhost:{port}/")
    print(f"  4-Photo Vision API: http://localhost:{port}/api/analyze-4-directions")
    print(f"  Sample Images API:  http://localhost:{port}/api/sample-images")
    print("==================================================")
    print("Ready to analyze 4 direction photos. Press Ctrl+C to stop.\n")

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[STOPPING] Shutting down VegMitra dashboard server...")
        httpd.server_close()
        sys.exit(0)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="VegMitra Dashboard Web Server")
    parser.add_argument("--port", type=int, default=int(os.environ.get("PORT", "8080")), help="Port to serve on")
    args = parser.parse_args()

    run_server(port=args.port)
