# VegMitra: Vehicle Detection and Adaptive Traffic Simulation

## B.Tech Machine Learning and Data Mining Project Report

## Abstract

VegMitra is a prototype that processes traffic video with a fine-tuned YOLOv8n detector, estimates incoming vehicle counts by intersection approach, and visualizes a rule-based signal choice. Python exports traffic state as JSON for a MATLAB intersection simulation. A separate `traffic_ml/` experiment compares classic classifiers on synthetic traffic-feature rows. The detector is learned from labeled images; approach assignment and signal selection are programmed algorithms. The repository has no physical signal-controller connection.

## Problem and objectives

Fixed-time signals do not respond to current queue observations. This project explores how video-based vehicle detection can support a simple adaptive intersection simulation.

Objectives:

1. Fine-tune a compact object detector for cars, motorcycles, buses, and trucks.
2. Track detections and estimate inbound traffic by North, South, East, and West approaches.
3. Smooth count estimates and select a simulated green approach using transparent rules.
4. Export state for visualization in MATLAB and the web dashboard.
5. Demonstrate Decision Tree, Random Forest, AdaBoost, and Gradient Boosting on synthetic tabular traffic features.

## System architecture

```text
Video → OpenCV frames → YOLOv8n boxes/classes → BoT-SORT track IDs
      → road/movement geometry → incoming counts → rolling mean/density
      → programmed green selection → JSON → MATLAB / dashboard

Separate experiment: synthetic traffic-feature CSV → scikit-learn classifiers
```

The tabular classifiers are not called by the video pipeline. The MATLAB app also includes simulated emergency and pedestrian scenarios; those are not detector-trained behaviors.

## Dataset and preprocessing

The detector dataset derives from BDD100K annotations. JSON pixel-coordinate boxes are converted to normalized YOLO labels in the form `class_id x_center y_center width height`.

| ID | Class | BDD100K source |
| ---: | --- | --- |
| 0 | car | `car` |
| 1 | motorcycle | `motor` |
| 2 | bus | `bus` |
| 3 | truck | `truck` |

The expanded split contains 18,862 train, 2,037 validation, and 2,610 test images (23,509 total). It contains 267,323 labeled boxes. Cars dominate the data; motorcycles have substantially lower support. BDD `bike` (bicycle), pedestrians, and traffic lights are not among the four detector classes. See [`DATASET.md`](DATASET.md) for counts, local paths, and preparation cautions.

The active `training/dataset.yaml` points to a local Downloads dataset path. The repository's `data/` copy is not currently the configured path. The older `training/prepare_dataset.py` targets 15,000 images and can clear split directories, so inspect it before use.

## Learning methodology

### YOLO vehicle detector

The vision model is Ultralytics YOLOv8n, a one-stage convolutional object detector. The current best checkpoint was fine-tuned from an earlier VegMitra checkpoint that originated from COCO-pretrained YOLO weights. The continuation began from epoch-43 weights and trained 17 more epochs to cumulative epoch 60. The selected checkpoint is:

```text
training/runs/traffic_finetune_from43_to60_20261101/weights/best.pt
```

Recorded continuation settings include 640-pixel input size, batch size 4, AdamW, initial learning rate 0.0002, final learning-rate fraction 0.1, momentum 0.937, weight decay 0.0005, and random seed 42. Augmentations included HSV changes, translation, scaling, horizontal flipping, and mosaic; vertical flipping and rotation were disabled. See the run's `args.yaml` and [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md) for provenance.

This is transfer learning: pretrained image features are adapted to project classes. Training minimizes detector losses for box localization and class prediction; YOLOv8 uses box, classification, and distribution focal loss terms. Backpropagation computes gradients, and AdamW updates weights. Validation is used for checkpoint selection; test metrics are kept for final evaluation.

`training/train.py` starts a new config-driven run. Its current `training/config.yaml` is not the final continuation configuration and does not automatically resume the epoch-60 run.

### Separate synthetic tabular experiment

`traffic_ml/feature_extraction.py` creates 600 synthetic rows with vehicle class counts, total vehicles, average speed, lane occupancy, time slot, density, and a LOW/MEDIUM/HIGH target derived from density thresholds. `train_classifiers.py` uses eight numeric features and an 80/20 stratified split (`random_state=42`) to train:

| Model | Method and configuration |
| --- | --- |
| Decision Tree | Single baseline, maximum depth 5 |
| Random Forest | Bagging, 100 trees, maximum depth 5 |
| AdaBoost | Boosting, 50 estimators |
| Gradient Boosting | 100 estimators, learning rate 0.1, depth 3 |

The script saves models in `traffic_ml/models/` and comparison metrics/plots in `traffic_ml/results/`. Since labels are generated from density rules, near-perfect scores demonstrate learning of a synthetic rule, not validated real-world congestion prediction. This experiment is not integrated into the controller.

## Evaluation

Object detection is evaluated with precision, recall, and AP/mAP because predictions must match both object class and box location; ordinary classification accuracy is not an appropriate summary.

### Current results

| Split | Images | Precision | Recall | mAP@50 | mAP@50:95 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Validation | 2,037 | 67.7% | 52.8% | 57.7% | 37.0% |
| Held-out test | 2,610 | 67.0% | 52.2% | 57.3% | 35.6% |

The test set has 29,970 labeled objects. Motorcycle recall is notably lower than car recall, consistent with the class imbalance. Full per-class details are in [`MODEL_EVALUATION.md`](MODEL_EVALUATION.md). These numbers describe detector performance on BDD-derived still images; they do not establish approach-count accuracy, latency, or signal-control quality on local traffic video.

### Metric definitions

- **IoU:** area of intersection divided by area of union for a predicted and labeled box.
- **Precision:** fraction of predicted detections that match a labeled object.
- **Recall:** fraction of labeled objects that are detected.
- **AP@50:** area under a class precision-recall curve at IoU 0.50.
- **mAP@50:95:** mean AP across IoU thresholds 0.50 through 0.95.
- **F1:** harmonic mean of precision and recall at an operating point; not ordinary accuracy.

## Traffic counting and signal selection

`detector.py` calls Ultralytics tracking with persistent BoT-SORT tracks. It assigns boxes to configured/default road regions (or a nearest-side fallback), uses recent positions and distance to intersection center to estimate incoming/outgoing movement, and counts incoming tracks by road. It averages recent counts over a rolling window and computes capped density using default capacity 30 vehicles per approach.

Normal green selection is programmed logic: choose the highest-density road subject to minimum green hold, a density hysteresis margin, and round-robin tie handling (including zero traffic). `main.py` configures a 10-frame window, 1.5-second minimum green, and 2 percentage-point threshold. `VehicleDetector` class defaults are 10 seconds and 10 points. These are prototype settings, not validated safety timings. There is no weighted-fair-queue priority formula or learned signal policy in this pipeline.

Python writes frame/count/density/selected-road state to `output/traffic_state.json` and `VegMitra_MATLAB/traffic_state.json` using a temporary file and replacement. `VegMitra_MATLAB/VegMitraApp.m` reads that state for simulation/visualization. The web dashboard lives under `frontend/` and is served by `serve_dashboard.py`.

## Emergency and pedestrian features

The Python code has emergency-related hooks, but the current detector classes are only car, motorcycle, bus, and truck. It cannot reliably recognize an ambulance, fire truck, or police vehicle from pixels. MATLAB's emergency-vehicle behavior is a simulated scenario, not a capability learned by YOLO. Pedestrian movement is also part of MATLAB simulation, not a detector class.

## Limitations and future work

1. Recall of 52.2% on the current test split means many labeled vehicles are missed; downstream counts can inherit misses and track errors.
2. The image dataset is car-heavy and may not represent local cameras, weather, lighting, or intersection geometry.
3. Validate per-approach counts and track identity against manually reviewed video; report MAE/RMSE, latency, and FPS.
4. Calibrate road regions for a fixed camera and test occlusion, night, rain, and camera movement.
5. Use real sensor/video data and independent labels to validate congestion classifiers.
6. Validate signal timing and fail-safe behavior in simulation and qualified safety review before any physical deployment.
7. Add emergency-vehicle labels and evaluation before claiming image-based emergency priority.

## Conclusion

VegMitra is an academic prototype combining a fine-tuned YOLO vehicle detector, classical tracking and geometry, transparent density-based signal rules, a JSON bridge, and MATLAB/web visualization. Its tabular ensemble experiment is separate and uses synthetic labels. The measured detector results are documented by split; controller accuracy, field safety, and real-world deployment performance remain unverified.

## References and project sources

- Ultralytics YOLO documentation and implementation: <https://docs.ultralytics.com>
- BDD100K dataset: <https://bdd-data.berkeley.edu/>
- Breiman, L. (2001). “Random Forests.” *Machine Learning*, 45, 5–32.
- Friedman, J. H. (2001). “Greedy Function Approximation: A Gradient Boosting Machine.” *Annals of Statistics*.
- Current project provenance: [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md), [`MODEL_EVALUATION.md`](MODEL_EVALUATION.md), and [`MODEL_COMPARISON.md`](MODEL_COMPARISON.md).
