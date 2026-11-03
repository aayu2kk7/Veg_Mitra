# VegMitra: Adaptive Traffic Management and Vehicle Detection

VegMitra is an academic traffic-management project that combines a computer-vision vehicle detector, video-based vehicle tracking and approach counting, a rule-based signal selector, and a MATLAB intersection simulation. It also contains a separate experiment comparing classic machine-learning classifiers on synthetic traffic-feature data.

> **Scope:** The YOLO model detects vehicles. It does not learn traffic-signal decisions. The Python signal selection is programmed logic, and the MATLAB app is a simulation. This repository is not connected to real traffic signals.

## Table of contents

- [System overview](#system-overview)
- [Repository layout](#repository-layout)
- [Computer-vision model](#computer-vision-model)
- [Dataset and labels](#dataset-and-labels)
- [How training works](#how-training-works)
- [Evaluation results](#evaluation-results)
- [From detections to a signal choice](#from-detections-to-a-signal-choice)
- [Separate tabular ML experiment](#separate-tabular-ml-experiment)
- [Basic machine-learning concepts](#basic-machine-learning-concepts)
- [Run the video pipeline](#run-the-video-pipeline)
- [Important paths and reproducibility notes](#important-paths-and-reproducibility-notes)
- [Limitations](#limitations)
- [Further documentation](#further-documentation)

## System overview

```text
Traffic video
    │
    ▼
OpenCV reads frames ──► YOLOv8n detects vehicle boxes and classes
                              │
                              ▼
                       BoT-SORT tracking
                              │
                              ▼
               Road and movement classification
                              │
                              ▼
              Incoming counts and smoothed density
                              │
                              ▼
      Rule-based green-road selection (Python simulation)
                   │                         │
                   ▼                         ▼
        Annotated output video       JSON traffic state ──► MATLAB GUI
```

The four approaches are North, South, East, and West. The computer-vision model returns bounding boxes, class labels, and confidence values. Tracking and geometry logic estimate the approach and whether a vehicle is moving toward or away from the intersection. The controller uses the resulting approach densities to select one simulated green road.

## Repository layout

| Path | Purpose |
| --- | --- |
| `main.py` | Reads the input video, calls the detector, writes an annotated video, and exports state JSON. |
| `detector.py` | YOLO inference/tracking, road geometry, incoming/outgoing movement classification, counts, density smoothing, and programmed signal selection. |
| `yolov8n.pt` | Original COCO-pretrained YOLOv8n weights; this is not the final VegMitra fine-tuned checkpoint. |
| `training/train.py` | Config-driven Ultralytics fine-tuning entry point for a new run. |
| `training/config.yaml` | Training hyperparameters and configured starting checkpoint for that entry point. |
| `training/dataset.yaml` | Dataset location and four-class mapping; defaults to the local `data/` folder. |
| `training/runs/traffic_finetune_from43_to60_20261101/weights/best.pt` | Current documented best checkpoint path in the working copy; model weights are not included in the public source repository. |
| `training/evaluate.py`, `training/predict.py` | Evaluation and prediction helpers. Supply the checkpoint explicitly to avoid stale defaults. |
| `training/results/` | Evaluation reports and diagnostic artifacts; check dates/checkpoint notes before attributing metrics. |
| `traffic_ml/` | Separate synthetic-data feature generation and classic classifier comparison. |
| `VegMitra_MATLAB/` | MATLAB intersection simulator, JSON bridge reader, scenario scripts, and screenshots. |
| `videos/` | Input location expected by `main.py`. |
| `output/` | Annotated video and exported traffic-state JSON. |
| `docs/` | Project context, ML concepts, evaluation, comparison, and presentation notes. |

## Computer-vision model

### Model used

The current detector is **Ultralytics YOLOv8n (Nano)**, a convolutional deep-learning object-detection model. The project fine-tunes pretrained YOLO weights for four vehicle classes:

| Class ID | Model class | Source label used in BDD100K |
| ---: | --- | --- |
| 0 | `car` | `car` |
| 1 | `motorcycle` | `motor` |
| 2 | `bus` | `bus` |
| 3 | `truck` | `truck` |

This is **object detection**, so one image can produce many predictions. Each prediction includes a class, confidence score, and bounding box `(x_min, y_min, x_max, y_max)`. It is not just image classification, and it is not trained to recognize pedestrians, traffic-light states, ambulances, or police vehicles as separate classes.

### Why a pretrained YOLO model?

The run starts from weights that have already learned general visual features from a large image dataset, then adapts those weights to the project's vehicle labels. This is called **transfer learning** or **fine-tuning**. It generally needs less task-specific data and compute than training a large vision model from random initialization.

YOLO is a one-stage detector: it predicts object locations and classes in a single model pass, which suits frame-by-frame video processing. The `n`/Nano variant prioritizes a compact, relatively fast model. Actual speed depends on the machine and video resolution.

## Dataset and labels

The documented detector dataset is derived from **BDD100K** annotations converted to YOLO bounding-box format. The current expanded split recorded in the project context contains:

| Split | Images | Labeled boxes |
| --- | ---: | ---: |
| Train | 18,862 | 214,400 |
| Validation | 2,037 | 22,953 |
| Test | 2,610 | 29,970 |
| **Total** | **23,509** | **267,323** |

The split is imbalanced: cars make up most labeled objects, while motorcycles have much lower support. Counts are annotations, not unique vehicles. Labels are one object per line in normalized YOLO form:

```text
class_id x_center y_center box_width box_height
```

The four classes are car, motorcycle, bus, and truck. Other BDD categories are excluded. In particular, BDD's `bike` category means bicycle and is not mapped to motorcycle.

`training/dataset.yaml` points to `data/` in a fresh clone. Dataset images and labels are not included in this source repository; prepare or obtain the BDD100K-derived YOLO data first, or change the YAML `path` to its location. Check BDD100K's terms before redistributing it.

## How training works

### Training procedure used for the current checkpoint

The current best checkpoint is documented as the result of **fine-tuning from an earlier VegMitra YOLOv8n checkpoint**, followed by a continuation run. The continuation resumed from the previous run's `last.pt` and finished at cumulative epoch 60 (43 epochs in the earlier run plus 17 continuation epochs). The final checkpoint selected was `best.pt`, based on validation fitness, not necessarily the last epoch. Checkpoint binaries are excluded from the public source repository; supply the checkpoint separately to run inference with this fine-tuned model.

The final continuation used the following recorded settings:

| Setting | Recorded value |
| --- | --- |
| Model family | YOLOv8n, continued from a VegMitra checkpoint |
| Task | Four-class bounding-box detection |
| Input size | 640 pixels |
| Batch size | 4 |
| Optimizer | AdamW |
| Initial learning rate | 0.0002 |
| Final learning-rate fraction | 0.1 |
| Weight decay | 0.0005 |
| Momentum | 0.937 |
| Random seed | 42 |
| Device | CUDA GPU, when available |
| Epochs in continuation | 17, resuming after epoch 43 |
| Augmentation | HSV color changes, translation, scale, horizontal flip, mosaic; no vertical flip or rotation |

The training run evaluates on the validation split during training and saves model checkpoints and plots under `training/runs/`. The run's `args.yaml` is the reference for its recorded arguments.

`training/train.py` is a **config-driven way to start a new run**; it is not a command to resume the current epoch-60 run. Its current `training/config.yaml` has different settings (for example, 50 epochs and learning rate 0.001) and points to an earlier checkpoint. Do not treat those config values as the exact settings of the final continuation checkpoint.

### Augmentation and optimization in plain language

- **Augmentation** makes altered training examples (color, scale, translation, mosaic, horizontal flip) so the detector sees more visual variation. It does not add new manually labeled scenes.
- **Mini-batch training** processes a small group of images at a time; the batch size here was 4.
- **Loss function** measures prediction errors during training. A detector's loss accounts for box localization and class/object predictions. YOLOv8 uses box, classification, and distribution focal loss components; their gradients update network weights.
- **AdamW** is the optimizer recorded for the continuation. It uses adaptive gradient updates and decoupled weight decay to adjust model parameters.
- **Learning rate** controls the size of weight updates. Fine-tuning typically uses a smaller rate than training from scratch to adapt existing features without changing them too aggressively.
- **Validation-based checkpoint selection** compares performance on examples withheld from weight updates. The best checkpoint is saved separately from the last checkpoint.

## Evaluation results

These are results for the documented current checkpoint on the current splits. Precision/recall are reported at the evaluator's operating point; mAP summarizes precision-recall performance across confidence thresholds.

### Validation

Checkpoint: `training/runs/traffic_finetune_from43_to60_20261101/weights/best.pt`  
Validation set: 2,037 images, 22,953 labeled objects.

| Class | Objects | Precision | Recall | AP@50 | AP@50:95 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Car | 21,059 | 77.2% | 66.1% | 73.2% | 44.4% |
| Motorcycle | 358 | 65.2% | 40.5% | 42.4% | 20.1% |
| Bus | 532 | 63.6% | 55.6% | 60.3% | 45.3% |
| Truck | 1,004 | 64.8% | 48.9% | 54.9% | 38.1% |
| **Overall / mAP** | **22,953** | **67.7%** | **52.8%** | **57.7%** | **37.0%** |

### Held-out test

The same checkpoint was evaluated on 2,610 test images containing 29,970 labeled objects. Overall precision was **67.0%**, recall **52.2%**, mAP@50 **57.3%**, and mAP@50:95 **35.6%**. Per-class details are in [`docs/MODEL_EVALUATION.md`](docs/MODEL_EVALUATION.md) and the current test CSV/JSON under `training/results/`.

### Metrics explained

- **Precision** = true positive detections / all predicted detections. Low precision means more false detections.
- **Recall** = true positive detections / all labeled objects. Low recall means more missed objects.
- **IoU (Intersection over Union)** measures overlap between a predicted box and its labeled box.
- **AP@50** is average precision when a matched box needs IoU of at least 0.50; **mAP@50** averages AP over classes.
- **mAP@50:95** averages AP at IoU thresholds 0.50 through 0.95, so it penalizes loose box placement more strongly.
- **F1** is the harmonic mean of precision and recall at one operating point. It is not ordinary accuracy.
- **Support** is the number of labeled object instances in that evaluation split, not the number of unique vehicles.

The lower motorcycle recall is a useful reminder that aggregate metrics can hide weaker performance on less common classes. Detection results alone do not measure traffic-count accuracy or quality of a signal plan.

## From detections to a signal choice

The Python controller in `detector.py` is **rule-based**, not a learned policy and not the tabular classifier. At a high level it:

1. Runs YOLO tracking on each frame using Ultralytics' persistent BoT-SORT tracking interface. If tracking fails, it tries ordinary detection as a fallback.
2. Keeps the four configured vehicle classes and uses track IDs to follow detections over time.
3. Assigns a detection to a road using configured region-of-interest polygons, or a nearest-side fallback when it lies outside those polygons.
4. Uses recent track positions and distance to the intersection center to estimate `INCOMING`, `OUTGOING`, or `UNKNOWN` movement. It counts incoming tracks by approach.
5. Applies a rolling average over recent per-frame counts. Density is `smoothed_count / road_capacity × 100`, capped at 100%; default capacity is 30 vehicles per approach.
6. Selects the approach with the greatest density, while applying a minimum green hold, a density hysteresis threshold, and round-robin tie handling to reduce rapid switching and handle zero-traffic ties.

In `main.py`, the detector is constructed with a 10-frame window, a **1.5-second** minimum green, and a **2 percentage-point** switch threshold. These values override the detector class defaults of 10 seconds and 10 percentage points. A video-timestamp is supplied when processing frames, so these configured durations are interpreted against the input video's timeline.

At a simplified level, the normal decision is:

```text
smoothed_count[road] = mean of recent incoming counts for that road
density[road] = min(100, smoothed_count[road] / capacity[road] × 100)
candidate = road with greatest density (round-robin among ties)
switch only after minimum-green hold and required hysteresis are satisfied
```

This project does **not** implement the old README's weighted-fair-queueing formula or dynamic 15–60 second green-time formula. It does not calculate a learned signal priority score. The actual documented Python choice is based on smoothed approach density plus timing and tie rules.

### Priority and emergency behavior

The Python module contains emergency-class/preemption hooks. However, the current detector model recognizes only car, motorcycle, bus, and truck; it does not include ambulance, fire truck, or police as trained classes. Emergency preemption therefore cannot be claimed as reliably triggered from the current model's video predictions.

The MATLAB simulator has its own simulated emergency-vehicle priority flow and pedestrian movement logic. These are simulation features and should not be confused with capabilities learned by the YOLO model or validated on live roads.

## Separate tabular ML experiment

The `traffic_ml/` folder is an educational classifier comparison separate from the YOLO video pipeline and signal selector. The current code generates **600 synthetic rows** with vehicle counts, total vehicles, average speed, lane occupancy, time slot, derived density, and a `LOW`/`MEDIUM`/`HIGH` traffic-level label. The label is generated from density thresholds:

- `LOW`: density below 30%
- `MEDIUM`: density from 30% through 65%
- `HIGH`: density above 65%

`train_classifiers.py` uses eight numeric features and a reproducible, stratified 80/20 train/test split (`random_state=42`). It compares:

| Classifier | Learning approach | Configured model |
| --- | --- | --- |
| Decision Tree | Single tree baseline | `max_depth=5` |
| Random Forest | Bagging: many trees trained on resampled data with feature subsampling | 100 trees, `max_depth=5` |
| AdaBoost | Boosting: sequentially reweights attention toward prior mistakes | 50 estimators |
| Gradient Boosting | Boosting: sequential trees reduce the previous ensemble's loss/residuals | 100 estimators, learning rate 0.1, depth 3 |

The script saves scikit-learn models as `.joblib`, weighted accuracy/precision/recall/F1 and confusion matrices as JSON, and a comparison chart. The near-perfect recorded scores are expected to be treated cautiously: the synthetic target is derived from density-related input features, and the dataset is not real independently collected traffic. This experiment demonstrates algorithms; it is not evidence of real-world congestion prediction and is not called by `main.py`.

## Basic machine-learning concepts

- **Feature:** An input value used for prediction. For the tabular experiment, examples include counts and average speed. For YOLO, the inputs are image pixels and learned image features.
- **Label / target:** The answer used during supervised training. YOLO labels include object class and box coordinates. The tabular experiment's target is a congestion category.
- **Supervised learning:** The model learns from examples paired with known labels.
- **Training set:** Data used to calculate loss and update weights.
- **Validation set:** Separate data checked during training for model selection and tuning; its labels do not directly update the weights.
- **Test set:** Held-out data used for a final estimate after model choices are made. Repeatedly tuning against it makes it less independent.
- **Epoch:** One pass through the training set. The YOLO continuation ran 17 more epochs after the earlier 43, reaching cumulative epoch 60.
- **Batch:** A small group of training examples processed before an optimizer update. Recorded batch size: 4 images.
- **Parameters / weights:** Values inside a neural network learned from training data.
- **Loss and optimization:** Loss quantifies prediction errors. Backpropagation computes gradients, and an optimizer such as AdamW uses those gradients to update weights.
- **Overfitting:** When a model fits its training examples well but performs poorly on new data. Validation monitoring, augmentation, weight decay, and early stopping/patience are common controls.
- **Transfer learning:** Reusing a pretrained model's learned features and fine-tuning it for the target classes.
- **Class imbalance:** Some labels appear much more often than others. The car-heavy detection data means overall metrics can look stronger than performance on rare motorcycles.
- **Bagging vs. boosting:** Bagging trains diverse learners and aggregates them, primarily reducing variance. Boosting builds learners sequentially so later learners focus on remaining errors, often reducing bias. In this repository, these describe the tabular model comparison; the YOLO detector is a deep neural network, not a Random Forest/AdaBoost ensemble.
- **Classification vs. detection:** Classification predicts a label for an input. Object detection predicts multiple labeled locations and therefore needs both class and box-localization metrics.

## Run the video pipeline

Use PowerShell from the project root. Install dependencies into a Python environment first; the project includes `requirements.txt` and `requirements-training.txt`. For GPU training, see `requirements-pytorch-cu132.txt` and the environment notes in `docs/PROJECT_CONTEXT.md`.

Place an input video at `videos/traffic.mp4` and obtain a model checkpoint separately. To run with the current fine-tuned model, pass the checkpoint path explicitly:

```powershell
python main.py <path-to-finetuned-checkpoint.pt>
```

The root `yolov8n.pt` is the original COCO checkpoint. If no checkpoint argument or `VEGMITRA_MODEL` environment variable is supplied, `main.py` prefers that root checkpoint when it exists. The output video is written to `output/detected_traffic.mp4`; JSON state is exported to `output/traffic_state.json` and `VegMitra_MATLAB/traffic_state.json`. A display window may open; press `q` to stop.

To evaluate the current checkpoint, use the project virtual environment and explicit checkpoint path. These commands are read/evaluate operations but write evaluation artifacts to `training/results/`:

```powershell
python training/evaluate.py --model training/runs/traffic_finetune_from43_to60_20261101/weights/best.pt --split val
python training/evaluate.py --model training/runs/traffic_finetune_from43_to60_20261101/weights/best.pt --split test
```

See `python training/evaluate.py --help` if options differ in your checkout. The test evaluation may overwrite files with generic test-result names; preserve those files first if you need historical versions.

## Important paths and reproducibility notes

- Dataset preparation scripts read `BDD100K_ROOT` when set, or expect a `bdd100k/` source folder beside the project. Pass `--source-root` to `training/prepare_dataset.py` when the archive is elsewhere. `training/dataset.yaml` expects prepared split folders under `data/` by default.
- The checked-in `training/config.yaml` is not the exact configuration of the final epoch-60 continuation. Consult the current run's `args.yaml` and project context.
- `main.py`, `training/evaluate.py`, and `training/predict.py` can default to other weights. Pass the intended checkpoint explicitly.
- `training/weights/best.pt` is an older shared artifact; it is not the current best checkpoint documented above.
- Different run directories and older reports describe earlier models or dataset versions. Always tie a metric to its checkpoint, split, and evaluation date.
- Git can track source/documentation, but large datasets, videos, virtual environments, and model checkpoints may be excluded or impractical to commit. Review `.gitignore` and repository size before adding them.

## Limitations

- The current detector misses a substantial share of labeled objects (test recall 52.2%); density and downstream signal decisions inherit detection/tracking errors.
- The dataset is class-imbalanced and drawn from BDD100K; performance on a specific local camera, weather, lighting, and road geometry is not established by these metrics.
- Tracking IDs can fragment or switch, and frame-based counts should not automatically be interpreted as unique vehicles across a whole video.
- Default road polygons and the center-distance movement heuristic need calibration for a real camera view.
- The minimum-green and hysteresis logic is a project simulation rule, not a validated traffic-control policy. No safety certification, real-time field trial, or hardware connection is established here.
- Emergency classes are not in the trained detector's four-class label set.
- The tabular congestion experiment uses generated data and rule-derived labels, not real traffic sensor observations.

## Further documentation

- [`docs/PROJECT_CONTEXT.md`](docs/PROJECT_CONTEXT.md): detailed current state, data, training history, signal logic, reproducibility, and limitations.
- [`docs/ML_CONCEPTS.md`](docs/ML_CONCEPTS.md): ensemble learning, bagging, and boosting concepts.
- [`docs/MODEL_EVALUATION.md`](docs/MODEL_EVALUATION.md): detection metrics and per-class evaluation.
- [`docs/MODEL_COMPARISON.md`](docs/MODEL_COMPARISON.md): detector, tabular classifiers, and rule-based controller comparison.
- [`output/pdf/vegmitra_yolov8n_classification_report_test_2026-11-03.pdf`](output/pdf/vegmitra_yolov8n_classification_report_test_2026-11-03.pdf): current held-out test classification/detection report with per-class metrics and training parameters.
- [`docs/VIVA_QUESTIONS.md`](docs/VIVA_QUESTIONS.md): project discussion and viva preparation.
