# VegMitra Project Context and Operations Guide

**Project:** VegMitra - AI Adaptive Traffic Management System  
**Guide status:** Current project context as of 02 November 2026  
**Workspace:** project root

This guide is the practical source of truth for understanding the repository, the current data and model, what has been trained, how the application pieces fit together, and what remains to be verified. Older project documents are retained, but some describe earlier dataset and model states; those differences are called out below.

## Contents

1. [Project at a glance](#1-project-at-a-glance)
2. [System architecture](#2-system-architecture)
3. [Repository map](#3-repository-map)
4. [Detection dataset: source, conversion, and current splits](#4-detection-dataset-source-conversion-and-current-splits)
5. [Model training history](#5-model-training-history)
6. [Current checkpoint and validation results](#6-current-checkpoint-and-validation-results)
7. [Metrics: what they mean](#7-metrics-what-they-mean)
8. [Environment and reproducible commands](#8-environment-and-reproducible-commands)
9. [Important defaults and stale artifacts](#9-important-defaults-and-stale-artifacts)
10. [Traffic counting and signal logic](#10-traffic-counting-and-signal-logic)
11. [Tabular machine-learning experiment](#11-tabular-machine-learning-experiment)
12. [MATLAB simulation and JSON bridge](#12-matlab-simulation-and-json-bridge)
13. [Tests and verification status](#13-tests-and-verification-status)
14. [Known limitations and risks](#14-known-limitations-and-risks)
15. [Recommended next steps](#15-recommended-next-steps)
16. [Project timeline](#16-project-timeline)
17. [Glossary](#17-glossary)

## 1. Project at a glance

VegMitra is a student project that combines video-based vehicle detection, traffic-counting and signal-selection logic, a MATLAB visualization, and a separate tabular machine-learning experiment.

The principal vision model is an Ultralytics YOLOv8n object detector fine-tuned to recognize four vehicle classes:

| Model class ID | Class name | BDD100K source category |
| ---: | --- | --- |
| 0 | car | `car` |
| 1 | motorcycle | `motor` |
| 2 | bus | `bus` |
| 3 | truck | `truck` |

The latest trained checkpoint is a **vehicle detector**, not a traffic-light-state detector and not a complete traffic controller. It predicts vehicle boxes and classes in individual images. The Python controller then estimates approach counts from tracked boxes and applies programmed logic to select one road for green. The application does not actuate real traffic signals.

### Current project state

- Final training target reached: cumulative epoch 60 (43 epochs in the preceding run plus a 17-epoch continuation from its saved weights).
- Current best checkpoint: [`training/runs/traffic_finetune_from43_to60_20261101/weights/best.pt`](../training/runs/traffic_finetune_from43_to60_20261101/weights/best.pt).
- Current expanded split: **18,862 train**, **2,037 validation**, and **2,610 test** images, each with a YOLO label file.
- Final best-checkpoint validation result: **67.7% precision**, **52.8% recall**, **57.7% mAP@50**, **37.0% mAP@50-95**.
- The current 2,610-image test split has been evaluated for this checkpoint: precision 67.0%, recall 52.2%, mAP@50 57.3%, and mAP@50-95 35.6%. Previous test artifacts were preserved with a `pre_current_epoch60_20261102` suffix.
- Current validation plots and detailed images are in the current run directory. The expanded report is [`output/pdf/vegmitra_yolo_training_report_2026-11-01.pdf`](../output/pdf/vegmitra_yolo_training_report_2026-11-01.pdf).

## 2. System architecture

```text
Traffic video (`videos/traffic.mp4`)
        |
        v
OpenCV reads each frame
        |
        v
YOLO model predicts vehicle boxes/classes
        |
        v
BoT-SORT track IDs associate boxes across frames
        |
        v
Road geometry + movement over time classify approach and direction
        |
        v
Incoming vehicle counts per North/South/East/West
        |
        +--> rolling count smoothing --> density estimates
        |                               |
        |                               v
        |                  minimum-green and hysteresis logic
        |                               |
        |                               v
        |                  selected green road for simulation
        |
        +--> JSON state --> MATLAB GUI / other listeners

Separate experiment:
engineered or synthetic traffic feature rows --> sklearn classifiers
```

The Python video pipeline and the tabular classifier experiment are separate in the current code. `main.py` and `detector.py` do not call the saved scikit-learn classifiers. The MATLAB GUI is a simulator/visualizer that reads the exported state; there is no physical signal-controller connection.

## 3. Repository map

| Path | Purpose and status |
| --- | --- |
| [`main.py`](../main.py) | Runs the video loop, loads a model, calls `VehicleDetector`, writes an annotated video, and exports JSON state. |
| [`create_sample_video.py`](../create_sample_video.py) | Generates a 100-frame demo intersection clip; if BDD image crops are available it uses them as vehicle sprites, otherwise it draws simple shapes. Default output is `videos/traffic.mp4`, so running it can replace that input video. |
| [`detector.py`](../detector.py) | YOLO tracking, incoming/outgoing movement classification, approach counts, density smoothing, and simulated green-road choice. |
| [`test_detector.py`](../test_detector.py) | Unit tests using mock boxes to exercise detector geometry and signal logic. This is not a test of real model accuracy. |
| [`yolov8n.pt`](../yolov8n.pt) | Original COCO-pretrained YOLOv8n weights. This is an 80-class general-purpose checkpoint, not the current four-class fine-tuned model. |
| `data/` | Project copy of the active expanded train/val/test image and YOLO-label directories, plus expansion metadata and excluded legacy examples. |
| `training/` | Dataset YAML, training/evaluation/prediction scripts, config, run folders, and older shared artifacts. |
| `training/runs/` | Run-specific results. The final current model and its plots are in `traffic_finetune_from43_to60_20261101/`. |
| Root `runs/` and `weights/` | Ultralytics or other earlier experiment output. Not the authoritative final checkpoint; use the explicit current run path. |
| `training/weights/` | Shared `best.pt` and `last.pt` from an earlier workflow. These were not updated by the final direct Ultralytics continuation; they are not the current model. |
| `traffic_ml/` | Separate tabular feature-generation, classifier-training, and sample-evaluation code and artifacts. |
| `VegMitra_MATLAB/` | MATLAB GUI/simulation, state JSON, scenario checks, and screenshots. |
| `videos/` | Video input location; `main.py` expects `videos/traffic.mp4`. |
| `output/` | Annotated-video and JSON outputs from the main Python pipeline, plus generated reports. |
| `docs/` | Academic report, data notes, audits, model/metric explanations, and this current guide. Some older documents need reconciliation with this guide. |
| `archive(1)/`, `datasets/` | Local archive/sample material. The BDD100K source used for preparation is under the Downloads path listed below. |

## 4. Detection dataset: source, conversion, and current splits

### Source and label conversion

The source BDD100K archive used in preparation is:

```text
<BDD100K_ROOT> (the local BDD100K source archive)
```

The source structure is BDD100K images by official split under `images/100k/{train,val,test}` and per-image JSON annotations under `labels/{train,val,test}`. The preparation scripts read object records from the first annotated frame, use each object's category and `box2d` coordinates, and write YOLO detection labels. Each YOLO text line is:

```text
class_id x_center y_center box_width box_height
```

Coordinates are normalized to the image dimensions. The target mapping is car=0, motorcycle=1 (BDD100K `motor`), bus=2, truck=3. Non-target categories, including pedestrians, bicycles, and traffic lights, are not trained as classes. BDD's `bike` category is a bicycle and is not mapped to motorcycle.

### Where the current split files are

Inside the project copy:

```text
data/train/images
data/train/labels
data/val/images
data/val/labels
data/test/images
data/test/labels
```

The recorded training YAML pointed at a local working copy; the portable repository configuration uses `data/` by default:

```text
<EXPANDED_DATASET_ROOT> (the local expanded dataset used for the recorded run)
```

That working copy has the same split names and counts. Its path is configured in [`training/dataset.yaml`](../training/dataset.yaml): `train: train/images`, `val: val/images`, `test: test/images` relative to the YAML `path`.

### Current split sizes and box counts

| Split | Images | Car boxes | Motorcycle boxes | Bus boxes | Truck boxes | Total boxes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Train | 18,862 | 193,754 | 3,002 | 7,642 | 10,002 | 214,400 |
| Validation | 2,037 | 21,059 | 358 | 532 | 1,004 | 22,953 |
| Test | 2,610 | 26,903 | 803 | 764 | 1,500 | 29,970 |
| **Total** | **23,509** | **241,716** | **4,163** | **8,938** | **12,506** | **267,323** |

These are image and bounding-box counts, not counts of unique vehicles. The train set is strongly car-heavy. The source BDD training split had no unused motorcycle boxes available for the expansion selection, so the motorcycle training-box count stayed at 3,002 even though validation/test were enriched for minority classes. The validation and test sets were also selected to increase representation of motorcycle, bus, and truck; results on these splits are not a direct estimate of naturally occurring class prevalence at a particular intersection.

### How the dataset reached its current size

The earlier preparation target was 15,000 total images (12,000 train, 1,500 val, 1,500 test). The later expansion added images from the matching official BDD split: 5,182 train, 537 validation, and 1,109 test images. The final actual total is therefore **23,509**, not 15,000. Existing images with missing labels were repaired as part of the process. The current directories have equal image/label file counts per split.

[`training/expand_bdd_splits.py`](../training/expand_bdd_splits.py) records the expansion selection logic and its fixed seed (24017); [`data/expansion_manifest.json`](../data/expansion_manifest.json) records the manifest. The manifest's `recovered_labels` list reflects the last execution pass and may not include every repair made in earlier passes; use the final split counts and file inventory as the current state. Image selection was kept within each matching BDD official split, so validation/test examples were not moved into training.

### Important data safety note

[`training/prepare_dataset.py`](../training/prepare_dataset.py) is the older 15,000-image preparation script. It deletes files in each `data/{split}/images` and `data/{split}/labels` directory before writing its selected 12,000/1,500/1,500 set. Do **not** rerun it casually: doing so would replace the current expanded dataset. It reads `BDD100K_ROOT` or expects a local `bdd100k/` source folder. Review the script and back up active data before any regeneration.

The upstream BDD100K terms should be reviewed before redistributing the images or labels outside the project.

## 5. Model training history

| Run folder | What happened | How to treat it |
| --- | --- | --- |
| `training/runs/traffic_finetune/` | Older 5-epoch experiment. Associated generic metric JSON contains zero metrics from an earlier/invalid data state. | Historical only. Do not use as current performance. |
| `training/runs/traffic_finetune_20261101_012056_855193/` | Earlier 100-epoch configured run, completed/early-stopped after 94 epochs. Its `best.pt` was used to initialize later fine-tuning. | Preserved baseline checkpoint and historical results. Evaluated on an earlier 1,500-image test split. |
| `training/runs/traffic_finetune_20261101_103033_712271/` | Fine-tuned the preceding checkpoint on the expanded dataset. Configured for 50 epochs and stopped at epoch 43. | This is the epoch-43 source checkpoint for the final continuation. Its optimizer state was stripped when the completed run was finalized. |
| `training/runs/traffic_finetune_extension7_20261101/` | A short 7-epoch extension was started, then stopped after 2 completed epochs when the target changed to cumulative epoch 60. It contains an auxiliary `resume15_epoch2.pt` checkpoint copy. | Partial/abandoned branch; not the selected final model. |
| `training/runs/traffic_finetune_from43_to60_20261101/` | Started from the epoch-43 weights, trained 17 additional epochs to cumulative epoch 60. The optimizer was newly initialized at the transition; a later interruption was resumed from a mid-run checkpoint that still had optimizer state. | **Current final run.** Use its `weights/best.pt` and run-specific validation results. |

The epoch-43 run's `patience` setting was 12. Early stopping is a likely reason it ended before 50, but the saved records do not conclusively establish the stop reason. The later continuation stopped at cumulative epoch 60 as requested. Its best recorded mAP@50 in that continuation was 57.76% at cumulative epoch 46; this is not a promise that every metric improved over epoch 43.

The final continuation used YOLOv8n, 640-pixel images, batch size 4, AdamW, initial LR 0.0002, final LR fraction 0.1, 8 workers, seed 42, and the same general HSV/translation/scale/flip/mosaic augmentations. It used patience 18 and closed mosaic for the final two continuation epochs. The original 43-epoch checkpoint had no optimizer state; the later resumption at cumulative epoch 54 used the continuation's saved optimizer state.

## 6. Current checkpoint and validation results

### Checkpoint to use

```text
training/runs/traffic_finetune_from43_to60_20261101/weights/best.pt
```

The run also contains `weights/last.pt`, which represents the final epoch rather than the checkpoint selected by validation fitness. Use `best.pt` for evaluation/inference unless there is a specific reason to inspect the last-epoch weights.

### Final validation metrics for the selected best checkpoint

The final validation pass covered 2,037 images and 22,953 labeled objects.

| Class | Images with class | Support (objects) | Precision | Recall | F1* | AP@50 | AP@50-95 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Car | 2,027 | 21,059 | 77.2% | 66.1% | 71.2% | 73.2% | 44.4% |
| Motorcycle | 276 | 358 | 65.2% | 40.5% | 50.0% | 42.4% | 20.1% |
| Bus | 427 | 532 | 63.6% | 55.6% | 59.3% | 60.3% | 45.3% |
| Truck | 633 | 1,004 | 64.8% | 48.9% | 55.7% | 54.9% | 38.1% |
| **Overall validator result** | **2,037** | **22,953** | **67.7%** | **52.8%** | **59.3%*** | **57.7%** | **37.0%** |

`F1*` is calculated from the displayed precision/recall, rounded to one decimal place. It is included as an intuitive summary; the evaluator's core detector metrics are precision, recall, AP/mAP, and localization-aware IoU metrics. The continuation's best per-epoch mAP@50 was 57.76% at cumulative epoch 46. The selected checkpoint is chosen by validation fitness, so the best checkpoint does not necessarily maximize every metric independently.

The current run folder contains `results.csv`, `results.png`, `labels.jpg`, `BoxPR_curve.png`, `BoxP_curve.png`, `BoxR_curve.png`, `BoxF1_curve.png`, `confusion_matrix.png`, `confusion_matrix_normalized.png`, and `val_batch0-2_{labels,pred}.jpg`. The updated multi-page report is at [`output/pdf/vegmitra_yolo_training_report_2026-11-01.pdf`](../output/pdf/vegmitra_yolo_training_report_2026-11-01.pdf).

### Current held-out test results

The current best checkpoint was evaluated on 2,610 test images and 29,970 labeled objects using CUDA. Results: precision 66.96%, recall 52.23%, F1 58.68%, mAP@50 57.28%, and mAP@50-95 35.58%.

| Class | Images with class | Support (objects) | Precision | Recall | F1 | AP@50 | AP@75 | AP@50-95 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Car | 2,588 | 26,903 | 76.2% | 67.7% | 71.7% | 73.5% | 44.7% | 44.6% |
| Motorcycle | 607 | 803 | 69.9% | 42.7% | 53.0% | 50.3% | 18.0% | 23.2% |
| Bus | 574 | 764 | 56.4% | 51.0% | 53.6% | 51.0% | 40.3% | 36.9% |
| Truck | 974 | 1,500 | 65.3% | 47.5% | 55.0% | 54.3% | 41.5% | 37.5% |

Per-class artifacts are [`training/results/classification_report_test.csv`](../training/results/classification_report_test.csv) and [`training/results/evaluation_metrics_test.json`](../training/results/evaluation_metrics_test.json). The run output and confusion matrix are under `runs/detect/val-5/`.

### Historical test result - earlier checkpoint and split

The preserved file [`training/results/evaluation_metrics_test_pre_current_epoch60_20261102.json`](../training/results/evaluation_metrics_test_pre_current_epoch60_20261102.json) reports the earlier checkpoint on the earlier 1,500-image test split: precision 67.46%, recall 44.76%, F1 53.81%, mAP@50 52.91%, and mAP@50-95 33.20%. Its class supports (15,495 cars, 68 motorcycles, 220 buses, 646 trucks) match the previous split, not today's 2,610-image test split. This historical result must not be described as the epoch-60 model's test score.

## 7. Metrics: what they mean

- **Precision:** Of the boxes the detector predicted, the fraction that matched a real labeled object/class under the evaluator's rules. Higher precision means fewer false detections.
- **Recall:** Of the labeled objects, the fraction the detector found. Higher recall means fewer missed vehicles.
- **IoU:** Intersection over Union, the overlap between a predicted box and its ground-truth box.
- **AP@50:** Per-class area under the precision-recall curve when a box match requires at least 0.50 IoU; mAP@50 averages AP over classes.
- **AP@50-95:** AP averaged across IoU thresholds 0.50, 0.55, ..., 0.95; mAP@50-95 is stricter about box placement.
- **F1:** Harmonic mean of precision and recall at a particular operating point. It is not the same as accuracy.
- **Support:** Number of ground-truth object instances for the class in the evaluated split, not number of unique vehicles or images.

A single ordinary classification accuracy is not meaningful for this bounding-box task because an image contains many possible background locations and correctness depends on box localization, class, and matching rules. For the traffic application, choose confidence thresholds using representative validation video and consider the cost of missed versus extra vehicles. Do not optimize the held-out test set.

## 8. Environment and reproducible commands

### Hardware and software used for the final run

- Windows, PowerShell.
- NVIDIA GeForce RTX 5050 Laptop GPU, approximately 8 GB reported VRAM.
- Training log: Python 3.13.15, PyTorch 2.15.0+cu132, Ultralytics 8.4.195, CUDA device 0.
- Project virtual environment: `.venv`; use its interpreter directly to avoid accidentally selecting a different Python installation.

The exact active command pattern is `\.venv\Scripts\python.exe ...` from the project root. Dependency manifests are [`requirements.txt`](../requirements.txt), [`requirements-training.txt`](../requirements-training.txt), and [`requirements-pytorch-cu132.txt`](../requirements-pytorch-cu132.txt). The CUDA requirements file pins the CUDA-enabled PyTorch/torchvision build used for this setup.

### Setup commands

```powershell
# From the Vegmitra - Copy project root
.\.venv\Scripts\python.exe --version
.\.venv\Scripts\python.exe -m pip install -r requirements-pytorch-cu132.txt
.\.venv\Scripts\python.exe -m pip install -r requirements-training.txt
```

Do not reinstall or upgrade torch just to rerun evaluation if the current `.venv` remains intact. First check that CUDA is visible and the expected GPU is reported.

### Evaluate the current model

Validation (safe for tuning):

```powershell
.\.venv\Scripts\python.exe training\evaluate.py --model training\runs\traffic_finetune_from43_to60_20261101\weights\best.pt --split val
```

Held-out test (only after choosing the model and thresholds):

```powershell
.\.venv\Scripts\python.exe training\evaluate.py --model training\runs\traffic_finetune_from43_to60_20261101\weights\best.pt --split test
```

**Output warning:** `training/evaluate.py` always writes `training/results/evaluation_metrics_{split}.json` and `classification_report_{split}.csv`. The test command will overwrite the old historical test files. Back them up first if you need to preserve the old result, or update the evaluator to write run-specific output before evaluating.

### Run the video application with the current model

`main.py` needs `videos/traffic.mp4`. Pass the current checkpoint explicitly:

```powershell
.\.venv\Scripts\python.exe main.py training\runs\traffic_finetune_from43_to60_20261101\weights\best.pt
```

This prevents the root `yolov8n.pt` COCO baseline from being selected by default. The annotated output is `output/detected_traffic.mp4`; state is exported to `output/traffic_state.json` and `VegMitra_MATLAB/traffic_state.json`.

`training/predict.py` exposes `predict_on_unseen(...)` but has no CLI argument parser. Calling `python training/predict.py` uses its default checkpoint `training/weights/best.pt`, which is not the current epoch-60 checkpoint. Pass `model_path` explicitly when invoking the function, and choose a distinct output path if you want to preserve existing videos.

### Training command caution

`training/train.py` reads `training/config.yaml` and starts a new timestamped run; it does not resume the final run. The current config still names the original 94-epoch baseline checkpoint and sets 50 epochs, LR 0.001, patience 12. Running it unchanged will not start from the current epoch-60 `best.pt`. Set `model.pretrained_weights` intentionally before a new training experiment and give that experiment its own run name/artifact record.

Also note `training/prepare_dataset.py` regenerates and clears split folders. Read [Section 4](#4-detection-dataset-source-conversion-and-current-splits) before using it.

## 9. Important defaults and stale artifacts

This section prevents accidentally evaluating or demonstrating the wrong model.

1. **`main.py` default:** If no path is passed, the code prefers root `yolov8n.pt` when present. It does not automatically select `training/runs/traffic_finetune_from43_to60_20261101/weights/best.pt`.
2. **Evaluator default:** `training/evaluate.py` defaults to `training/weights/best.pt`, an older shared checkpoint. Always supply `--model` for the epoch-60 model.
3. **Prediction default:** `training/predict.py` also defaults to `training/weights/best.pt`; pass the final run checkpoint explicitly.
4. **Shared artifacts:** The final direct Ultralytics continuation wrote to its run folder. It did not run the post-processing copy logic in `training/train.py`; therefore `training/weights/` and much of `training/results/` are not authoritative for the final run.
5. **Historical report files:** `training/results/evaluation_metrics_test.json` and `classification_report_test.csv` describe the earlier model/split. `training/results/evaluation_metrics.json` contains an old zero-score state. Do not merge those files with current validation results.
6. **Older artifacts:** Some historical run folders and archived reports refer to the 15,000-image target or earlier checkpoints. Current project documentation and the run-specific epoch-60 results use the expanded 23,509-image split and current held-out test evaluation.
7. **Dataset availability:** The dataset is excluded from the source repository. Set `BDD100K_ROOT` or use `--source-root` and confirm BDD100K's terms before running preparation.

## 10. Traffic counting and signal logic

`VehicleDetector.process_frame` calls Ultralytics tracking with BoT-SORT (`botsort.yaml`, persistent tracks). It filters to car, motorcycle, bus, and truck, assigns detections to a road using configured/default polygons (or nearest side of the frame), estimates incoming/outgoing motion from track history and distance to the frame's intersection center, and counts incoming tracks for North, South, East, and West.

Counts are smoothed over a rolling frame window. Density is computed per road as `smoothed_count / road_capacity * 100`, capped at 100%. The detector's default capacity is 30 vehicles per road. The signal selector chooses the highest-density approach, applies a minimum green hold and a density hysteresis threshold, and uses round-robin behavior for ties/zero traffic. In `main.py`, the detector is constructed with a 10-frame window, **1.5-second** minimum green, and **2.0 percentage-point** switch threshold. These override detector defaults of 10 seconds and 10 points.

The JSON state includes current and smoothed counts, density, selected road, emergency fields, frame index, and remaining green hold. Counts are per frame/track logic; they should not be interpreted automatically as a stable unique-vehicle count across an entire video without checking track behavior and camera geometry.

### Emergency priority gap

The controller has code paths for emergency classes, but the current four-class model does not include ambulance, fire truck, police, or other emergency classes. The original COCO checkpoint also lacks these custom classes. Consequently, the current YOLO model cannot reliably trigger emergency preemption from pixels. Emergency priority needs an emergency-labeled dataset/model or a trusted external emergency input before it can be claimed as functional.

## 11. Tabular machine-learning experiment

`traffic_ml/feature_extraction.py` generates 600 synthetic traffic observations using seeded random ranges. It includes class counts, total vehicles, average speed, lane occupancy, time slot, a calculated density, and a LOW/MEDIUM/HIGH label derived from density thresholds. `train_classifiers.py` fits Decision Tree, Random Forest, AdaBoost, and Gradient Boosting models using an 80/20 stratified split and stores model files plus comparison results. `evaluate_classifiers.py` predicts one hand-created sample using saved models.

Current recorded results are near-perfect (three models at 100%, Gradient Boosting about 99.17%). These scores reflect a synthetic dataset whose label is deterministically calculated from input features; they are not evidence of performance on real intersection sensor data. The classifiers are not currently connected to `main.py` or the signal selector. Treat this as a methodological demonstration until real observations, an independent split, and application integration are added.

## 12. MATLAB simulation and JSON bridge

`main.py` writes the same state payload to:

- `output/traffic_state.json`
- `VegMitra_MATLAB/traffic_state.json`

It writes a temporary file and renames it to reduce the chance of MATLAB reading a partially written JSON file. The MATLAB app and scenario scripts are in `VegMitra_MATLAB/`, including `VegMitraApp.m`, `launchVegMitra.m`, acceptance tests, and phase/emergency/pedestrian verification scripts. The MATLAB project is a simulation/visualization layer; do not describe it as controlling live signal hardware without a separate integration.

## 13. Tests and verification status

`test_detector.py` contains mock-based tests for road assignment, incoming/outgoing movement, repeated counting, rolling averages, density calculation/capping, road selection, tie-breaking, green hold/hysteresis, and emergency-trigger behavior. These tests validate logic under simulated detections; they do not evaluate YOLO accuracy or prove correct behavior on a real intersection camera.

The MATLAB folder includes acceptance and scenario verification scripts. Their existence does not by itself establish that they pass in the current environment. No test suite was run while preparing this context guide.

The current final YOLO run generated validation plots and visual predictions. A fresh test-split evaluation for its best checkpoint remains outstanding.

## 14. Known limitations and risks

- **Domain gap:** BDD100K road images are not necessarily representative of the target intersection cameras, vehicle mix, viewing angles, weather, or lighting. Validate with local camera footage.
- **Class imbalance:** Cars dominate training. Motorcycle recall/AP are weakest; support and representative data matter.
- **Test status:** The epoch-60 checkpoint has current held-out test metrics recorded above. Older generic artifacts were preserved separately and belong to an earlier split/model.
- **Detector vs. controller:** Good box AP does not prove correct four-road counts, queue-length estimates, safe signal timing, or deployment readiness.
- **Geometry assumptions:** Default road polygons and center-of-frame logic need calibration for each fixed camera. A single forward-facing dashcam view is not automatically a four-approach intersection view.
- **Emergency class absence:** The current detector cannot recognize emergency vehicles as a custom class.
- **Signal safety:** This is a simulation/demo controller, not a certified safety-critical signal controller. No real signal should be actuated from it without safety design, fail-safe logic, field validation, and qualified review.
- **Tabular synthetic labels:** The classifier scores are not a real-world traffic forecast benchmark.
- **Old defaults:** Scripts may silently use the original COCO model or shared older checkpoint if the model path is omitted.
- **Data regeneration:** The old preparation script deletes split contents before writing its 15,000-image selection.
- **Data license:** Check BDD100K conditions before sharing data or derived files.

## 15. Recommended next steps

1. Preserve the current checkpoint and run folder; keep a copy of this guide with project deliverables.
2. Inspect the current test report and confusion matrix; do not tune the model or thresholds against the held-out test split.
3. Report test precision, recall, F1, mAP@50, mAP@50-95, per-class AP, and support. Keep validation and test results separate.
4. Inspect failures by class, especially missed motorcycles/trucks and background confusions. Review annotations and add target-domain data rather than judging only by aggregate mAP.
5. Calibrate confidence thresholds on validation intersection footage and measure count error per approach over time. Use the test split only once the model and thresholds are fixed.
6. Calibrate each camera's approach polygons and validate tracking/counting on real video. Add congestion logic and a safe controller separately from the detector.
7. If emergency priority is a requirement, add emergency classes/data or a trusted external emergency signal; validate it independently.
8. Update README, `docs/DATASET.md`, `docs/MODEL_EVALUATION.md`, `training/config.yaml`, and default model selection so they match the current dataset/checkpoint and do not point at stale artifacts.
9. Before another training run, explicitly choose whether it starts from the epoch-60 best weights or another baseline, set an isolated run name/output path, verify split counts, and preserve the current best checkpoint.
10. Replace the synthetic tabular dataset with real, independently labeled traffic windows before presenting those classifiers as operational ML results.

## 16. Project timeline

| Stage | Work completed | Result |
| --- | --- | --- |
| Original application | YOLO COCO inference, vehicle tracking/counting logic, basic signal selection, MATLAB state visualization. | Demonstration pipeline existed, but no custom four-class training dataset was initially present. |
| Initial dataset preparation | BDD100K JSON boxes converted to normalized YOLO labels; initial target was 12,000/1,500/1,500. | Initial 15,000-image four-class dataset. |
| Dataset expansion | Added split-preserving BDD100K images targeted to bus/truck and rarer validation/test classes; repaired missing annotations; staged local training copy. | Current 18,862/2,037/2,610 split, 23,509 total. |
| Baseline training | Earlier 100-epoch configured run completed/early-stopped at epoch 94. | Preserved baseline checkpoint, then used to initialize expanded-data fine-tuning. |
| Expanded-data fine-tuning | Fine-tuning run stopped at epoch 43; checkpoint was finalized without optimizer state. | Epoch-43 learned weights retained; optimizer reset for continuation. |
| Final continuation | Started from epoch-43 weights for 17 more epochs, later resumed from its own optimizer checkpoint. | Cumulative epoch 60; current best checkpoint and validation plots saved. |
| Current reporting | Final validation and held-out test metrics, class reports, confusion matrices, curves, labels, and prediction examples compiled. | PDF report generated before the current test evaluation; refresh it if final test metrics should appear in the PDF. |

## 17. Glossary

- **BDD100K:** Public driving-scene dataset providing images and object annotations.
- **YOLO label:** Normalized class and bounding-box coordinates stored as one text row per object.
- **Checkpoint:** Saved model weights; a training checkpoint may also contain optimizer/scheduler state.
- **Best checkpoint:** Weights selected by validation fitness during a run.
- **Last checkpoint:** Weights saved at the most recently completed epoch.
- **mAP:** Mean Average Precision, a class-averaged object-detection measure across confidence thresholds.
- **mAP@50-95:** mAP averaged across IoU thresholds 0.50 through 0.95.
- **BoT-SORT:** Tracking algorithm used by the current `detector.py` implementation to associate detections across frames.
- **Hysteresis:** A minimum improvement required before changing the selected green road, helping avoid rapid switching.
- **Domain shift:** Performance change when deployment-camera images differ from training/validation images.

---

**Maintainer note:** When metrics, dataset counts, or checkpoint paths change, update this guide and the PDF report together. Treat run-specific artifacts as authoritative for that run; do not copy numbers from generic `training/results/` files without confirming their model path and split.




