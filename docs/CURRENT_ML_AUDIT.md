# VegMitra: Current ML and Control Audit

**Updated:** 03 November 2026  
**Purpose:** Describe the current repository state and distinguish learned components from programmed logic.

## Executive summary

VegMitra currently contains three related but separate pieces:

1. A fine-tuned YOLOv8n detector for four vehicle classes, used in the Python video pipeline.
2. A deterministic tracking/counting/density/signal-selection pipeline around that detector.
3. An educational scikit-learn classifier comparison trained on synthetic traffic-feature rows. It is not connected to the video controller.

The MATLAB application visualizes and simulates an intersection, reads exported traffic state, and has its own simulation behavior. The project does not actuate real traffic lights.

## Current learned models

### Vehicle detector

- **Architecture family:** Ultralytics YOLOv8n (Nano), PyTorch.
- **Task/classes:** bounding-box object detection for `car`, `motorcycle`, `bus`, and `truck`.
- **Starting point:** an earlier VegMitra checkpoint fine-tuned from COCO-pretrained YOLO weights; the final continuation resumed from the epoch-43 run's weights and reached cumulative epoch 60.
- **Current best checkpoint:** `training/runs/traffic_finetune_from43_to60_20261101/weights/best.pt`.
- **Current split sizes:** 18,862 train, 2,037 validation, and 2,610 test images.
- **Validation:** precision 67.7%, recall 52.8%, mAP@50 57.7%, mAP@50:95 37.0%.
- **Held-out test:** precision 67.0%, recall 52.2%, mAP@50 57.3%, mAP@50:95 35.6%.

Consult [`MODEL_EVALUATION.md`](MODEL_EVALUATION.md) and [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md) for per-class results and provenance. Root `yolov8n.pt` is the general COCO checkpoint, not the current fine-tuned model.

### Tabular classifiers

`traffic_ml/` compares a depth-limited Decision Tree, Random Forest, AdaBoost, and Gradient Boosting. The source table has 600 synthetic rows; its LOW/MEDIUM/HIGH labels are computed from density thresholds. The classifiers use eight engineered numeric features and an 80/20 stratified split. Their high scores do not establish generalization to real traffic, and these saved models are not consumed by `main.py` or `detector.py`.

## Learned perception vs. programmed logic

| Component | Category | What it does |
| --- | --- | --- |
| YOLOv8n | Deep learning | Predicts bounding boxes, class IDs, and confidence scores from each frame. |
| BoT-SORT interface | Tracking algorithm | Associates detections across frames to provide persistent track IDs when tracking succeeds. |
| Road/flow assignment | Geometry and heuristics | Uses polygons or a nearest-side fallback, then position history and distance-to-center changes to estimate incoming/outgoing movement. |
| Count smoothing | Statistics | Computes a rolling mean over recent frame counts. |
| Density | Programmed formula | `min(100, smoothed_count / road_capacity × 100)`; default capacity is 30 per road. |
| Green-road selection | Rule-based control | Chooses by density, with minimum green hold, hysteresis, and round-robin tie/zero-traffic behavior. `main.py` uses 1.5 seconds and a 2 percentage-point margin; class defaults are 10 seconds and 10 points. |
| Tabular congestion class | Classic supervised ML demo | Predicts synthetic density-derived categories; not integrated into live control. |
| MATLAB app | Simulation and visualization | Displays a four-way junction, traffic, signals, emergency scenarios, and pedestrian movement. |

## Emergency and safety scope

Emergency-priority branches exist in the Python and MATLAB code. The trained detector has no ambulance, police, or fire class, so it cannot reliably trigger Python preemption from image pixels. MATLAB's emergency vehicles are simulated objects. Neither feature demonstrates real-world emergency response or safety certification.

## Important defaults

- `main.py` prefers root `yolov8n.pt` if no explicit model path/`VEGMITRA_MODEL` is provided. Pass the current fine-tuned checkpoint explicitly for a demo.
- `training/train.py` starts a new configured run; the checked-in config is not the final epoch-60 continuation configuration.
- Evaluation and prediction helpers may default to older `training/weights/` checkpoints. Supply the intended model explicitly.
- `training/dataset.yaml` has a local Downloads path. Update it on another machine.
- `training/prepare_dataset.py` reflects the older 15,000-image preparation target and can clear the split directories. Review before running.

## Work still needed for stronger claims

- Measure per-class/per-approach count error against manually labeled intersection video.
- Measure latency/FPS on the intended deployment hardware and camera stream.
- Evaluate across lighting, occlusion, weather, and camera placement changes.
- Improve minority-class coverage and validate data labels.
- Use real sensor observations and an independent dataset before claiming tabular congestion prediction.
- Validate signal timing and fail-safe behavior in a suitable simulator and safety review before any real-world actuation.

The historical audit of the original COCO-only baseline should not be read as the current state. The current run, data, metrics, and defaults are documented in [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md).
