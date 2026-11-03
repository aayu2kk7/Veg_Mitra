# VegMitra Teaching Assistant Presentation Script

**Purpose:** A truthful, practical walkthrough for presenting the current project. Project facts and run history are in [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md); this script is written to speak from.

## Before the presentation

1. Open the project root folder in your local clone.
2. Keep ready: a traffic video at `videos/traffic.mp4`, the current checkpoint `training/runs/traffic_finetune_from43_to60_20261101/weights/best.pt`, and (optionally) the project PDF at `output/pdf/vegmitra_yolo_training_report_2026-11-01.pdf`. The PDF predates the current held-out test evaluation; use this guide and `MODEL_EVALUATION.md` for current test results.
3. The current test split has now been evaluated with the final checkpoint. Use the current report files; the previous test report is preserved with a `pre_current_epoch60_20261102` suffix.
4. `main.py` defaults to the root COCO `yolov8n.pt` when it exists. To demo the current fine-tuned model, pass its explicit path as the first argument.
5. The main script writes/overwrites `output/detected_traffic.mp4` and traffic-state JSON files. Keep a backup if earlier outputs matter.
6. Run a command only if the required video, Python environment, and model are present. Do not promise live performance or real signal actuation.

## 60-second opening

> “Good morning/afternoon. VegMitra is a prototype for adaptive traffic monitoring. It uses a YOLOv8 vehicle detector to find cars, motorcycles, buses, and trucks in video. A tracking and geometry layer estimates which approach vehicles are moving toward, smooths counts, and a separate rule-based controller selects a road for green. The project also includes a MATLAB simulation bridge and a separate tabular machine-learning experiment. Today I’ll show the pipeline, explain how we trained and evaluated the detector, and discuss what still needs validation before deployment.”

## Suggested 5–7 minute walkthrough

### 1. Show the project and dataset (about 1 minute)

Open [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md) and show the dataset section.

Say:

> “We converted BDD100K JSON boxes from pixel coordinates into normalized YOLO labels. The final expanded dataset has 18,862 training, 2,037 validation, and 2,610 test images, 23,509 total. Classes are car, motorcycle, bus, and truck. Train, validation, and test membership follows the corresponding official BDD splits.”

Add the important data caveat:

> “The training data is strongly car-heavy. The validation and test selections were enriched for some minority classes, so their class mix does not represent a natural traffic prevalence estimate. Motorcycle support is still low.”

### 2. Explain training and show evaluation (about 1–2 minutes)

Open [`MODEL_EVALUATION.md`](MODEL_EVALUATION.md), then show the current run plots/PDF if available.

Say:

> “We fine-tuned a COCO-pretrained YOLOv8n checkpoint on the prepared data. The final continuation reached cumulative epoch 60. The selected best checkpoint is chosen using validation performance. On the current validation set, precision is 67.7%, recall 52.8%, mAP@50 57.7%, and mAP@50:95 37.0%. Motorcycle recall and AP are the weakest class results.”

Then state:

> “These validation metrics are not ordinary classification accuracy. We also evaluated the current checkpoint on the untouched 2,610-image test split: precision 67.0%, recall 52.2%, mAP@50 57.3%, and mAP@50:95 35.6%. Older test metrics belong to a previous checkpoint and split.”

If a live evaluation is needed, from the project root:

```powershell
.\.venv\Scripts\python.exe training/evaluate.py --model training/runs/traffic_finetune_from43_to60_20261101/weights/best.pt --split val
```

The evaluator prints an object-detection classification-style per-class report and writes `training/results/evaluation_metrics_val.json` and `training/results/classification_report_val.csv`. Current test outputs are `training/results/evaluation_metrics_test.json` and `training/results/classification_report_test.csv`; earlier files were preserved with a `pre_current_epoch60_20261102` suffix.

### 3. Demonstrate the video pipeline (about 1–2 minutes)

Confirm `videos/traffic.mp4` exists, then run:

```powershell
.\.venv\Scripts\python.exe main.py training/runs/traffic_finetune_from43_to60_20261101/weights/best.pt
```

Explain while it runs:

> “The detector generates vehicle boxes. Tracking and motion/geometry logic estimate approach counts. A rolling window smooths frame-to-frame variation. The controller chooses an approach using programmed density rules and writes state to JSON for the MATLAB simulation.”

Demo notes:

- The code uses configured thresholding and signal rules; results depend on the camera view, video, tracking behavior, and model confidence.
- Vehicle estimates can be duplicated or missed under occlusion, camera motion, dense queues, or poor lighting. Counts should be checked against manually labeled video before making quantitative claims.
- The project simulates signal selection. It does not connect to or control real traffic-light hardware.
- The controller has emergency-priority code, but the detector's four classes do not include ambulance, police, or fire vehicles. Do not claim the present model recognizes them.

### 4. Mention the separate tabular ML experiment (about 45 seconds)

Open [`MODEL_COMPARISON.md`](MODEL_COMPARISON.md).

Say:

> “We also compared decision trees and ensemble methods on structured traffic features. This experiment uses 600 synthetic records, and the LOW/MEDIUM/HIGH targets are generated from density rules. Its near-perfect scores show the code can learn that synthetic rule; they are not real-world traffic accuracy. This classifier is not currently wired into the video controller.”

Only run `traffic_ml/train_classifiers.py` if you want to demonstrate model training; it regenerates experiment artifacts. Do not present its scores as evidence of field performance.

### 5. Close with limitations and next steps (about 1 minute)

> “The main benefits are a compact end-to-end prototype, automated vehicle localization, interpretable approach-count and signal-selection logic, reproducible dataset conversion, and visual diagnostics. The main gaps are missed vehicles—especially motorcycles—limited validation on local intersection video, and no real hardware integration. Our next steps are to review false positives and misses, collect representative local footage, measure per-approach count error and latency, and validate controller behavior in simulation before considering deployment.”

## Project benefits to emphasize

- A single detector returns both vehicle category and approximate location, which supports per-approach counting.
- YOLOv8n is relatively small and is suitable for experimentation on the available laptop GPU.
- The dataset conversion and split handling create a repeatable object-detection workflow.
- The control logic is visible and explainable, rather than hidden inside an unvalidated end-to-end policy.
- Python can export structured state for visualization in MATLAB.

## Problems and lessons learned to disclose

- The original 15,000-image target was later expanded; the current actual total is 23,509. Older documents/artifacts may describe the earlier target.
- The source labels required conversion from BDD JSON to YOLO text format. Image/label alignment and class-ID mapping had to be checked.
- The class distribution is imbalanced, and motorcycle recall is comparatively weak. More targeted, representative motorcycle data and label review are likely needed.
- The epoch-43 checkpoint had no optimizer state. The continuation initialized fresh optimizer state at the handoff, so its epoch counter is cumulative for reporting but optimization was not an uninterrupted resume from the original optimizer.
- Fine-tuning does not guarantee every metric rises. Checkpoint selection uses validation fitness and can trade off precision, recall, and localization quality.
- The held-out test results are available, but should not be used for threshold tuning; historical test files refer to an older run.
- Emergency vehicle priority is only as capable as its detector inputs; those classes are not in the current model.
- The tabular classifier's synthetic labels create an easy, circular task. Real sensor/video observations and an independent evaluation are required.
- Tests use mock detections to check controller logic. They do not establish real-video detection quality or traffic safety.

## Likely TA questions: short, defensible answers

**Is 57.3% the accuracy?**  
“No. It is mAP@50 on the test split. For detection we report precision, recall, and mAP because a conventional true-negative count is not well-defined. Test mAP@50:95 is 35.6%.”

**What is the difference between mAP@50 and mAP@50:95?**  
“mAP@50 accepts a matched box at IoU 0.50. mAP@50:95 averages over thresholds from 0.50 to 0.95, so it rewards more precise box placement and is stricter.”

**Can the model decide which of four roads is busiest?**  
“The detector itself does not reason about road phases. The pipeline can estimate counts by approach from a suitable fixed camera view, then the separate controller selects a road using those estimates. That counting behavior still needs evaluation on representative four-approach video.”

**Does it count unique vehicles?**  
“It uses tracking/frame logic to reduce repeat counts, but the output is not automatically a reliable unique-vehicle count over a whole video. Track continuity and camera geometry need calibration and validation.”

**Why train on BDD100K?**  
“It provides road-scene images and bounding-box annotations that can be converted into the four target classes. It is a useful starting point, but it is not a substitute for representative local intersection footage.”

**Does it control an actual traffic light?**  
“No. The present project estimates traffic state and simulates a signal choice; it does not actuate physical traffic hardware.”

**What would you improve first?**  
“Evaluate the current checkpoint on the untouched test split, inspect class-specific false negatives, improve representative minority-class data, and measure vehicle-count error and latency on local intersection videos.”

## Files to have open during Q&A

- [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md): complete project state and path reference.
- [`MODEL_EVALUATION.md`](MODEL_EVALUATION.md): definitions and current validation results.
- [`MODEL_COMPARISON.md`](MODEL_COMPARISON.md): fair comparison caveats.
- [`DATASET.md`](DATASET.md): dataset details (check against the current context guide if older counts appear).
- [`output/pdf/vegmitra_yolo_training_report_2026-11-01.pdf`](../output/pdf/vegmitra_yolo_training_report_2026-11-01.pdf): generated visual report; refresh after current test evaluation.
