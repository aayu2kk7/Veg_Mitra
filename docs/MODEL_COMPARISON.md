# VegMitra Model Comparison

**Status:** Updated 02 November 2026. The project state and full run history are documented in [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md). Metrics below are explicitly tied to their data split and checkpoint.

## What is being compared

| System/model | Input and task | Data / status | What can be concluded |
| --- | --- | --- | --- |
| COCO-pretrained YOLOv8n (`yolov8n.pt`) | Image/video pixels; general 80-class object detection | Pretrained checkpoint; historical small COCO-8 smoke evaluation exists | It loads and detects common COCO objects. The smoke result is not target-domain performance on VegMitra's BDD-derived split. |
| Fine-tuned YOLOv8n (current best) | Image pixels; four vehicle classes and boxes | Fine-tuned from earlier YOLOv8n weights; cumulative epoch 60; evaluated on current validation and test splits | Current validation and test measures are available below. |
| Decision Tree / Random Forest / AdaBoost / Gradient Boosting | Engineered numeric features; LOW/MEDIUM/HIGH congestion classification | 600 synthetic records, with congestion labels derived from density rules | Demonstrates algorithms and feature pipeline. Near-perfect scores do not show generalization to real traffic observations. Not integrated into the live controller. |
| Programmed signal selector | Per-approach counts/density over video frames; choose a green approach | Deterministic code and mock-based logic tests | This is rule-based control, not a learned traffic-signal policy. Tests validate code paths, not safety or field performance. |

## Current detector validation results

Checkpoint: `training/runs/traffic_finetune_from43_to60_20261101/weights/best.pt`  
Split: current validation, 2,037 images and 22,953 labeled objects.  
Classes: car, motorcycle, bus, truck.

| Class | Support | Precision | Recall | F1* | AP@50 | AP@50:95 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Car | 21,059 | 77.2% | 66.1% | 71.2% | 73.2% | 44.4% |
| Motorcycle | 358 | 65.2% | 40.5% | 50.0% | 42.4% | 20.1% |
| Bus | 532 | 63.6% | 55.6% | 59.3% | 60.3% | 45.3% |
| Truck | 1,004 | 64.8% | 48.9% | 55.7% | 54.9% | 38.1% |
| **Overall** | **22,953** | **67.7%** | **52.8%** | **59.3%*** | **57.7%** | **37.0%** |

`F1*` is calculated from the displayed precision and recall; Ultralytics' core validation output reports precision, recall, and AP. It is a convenient summary, not an independent model metric. The selected checkpoint maximizes validation fitness and need not maximize every listed metric separately.

## Current held-out test results

The selected checkpoint was evaluated on all 2,610 current test images (29,970 objects): precision 67.0%, recall 52.2%, F1 58.7%, mAP@50 57.3%, and mAP@50:95 35.6%. Per-class results are in [`MODEL_EVALUATION.md`](MODEL_EVALUATION.md) and `training/results/classification_report_test.csv`.

## Comparison limits

- The pretrained baseline's historic smoke test used COCO-8 (4 validation images / 17 instances), not the current BDD-derived validation set. Its previously recorded 88.75% mAP@50 must not be compared directly to the current 57.7% as a controlled before/after experiment.
- An older fine-tuned run and historical test JSON refer to older data/checkpoints. Do not attribute those numbers to the current model.
- Test results are now available for the epoch-60 checkpoint. Keep them separate from validation results, and do not use the test split to tune the model.
- Precision/recall depend on the evaluator's matching and confidence settings. mAP summarizes precision-recall behavior across confidence thresholds; it is not ordinary “accuracy.”
- Class support is imbalanced. Motorcycle currently has the weakest recall and AP, so aggregate mAP conceals a meaningful class-specific gap.

## Appropriate next comparison

1. If measuring the benefit of fine-tuning, evaluate both `yolov8n.pt` and the fine-tuned checkpoint on the **same current test images**, same image size, class mapping, and evaluation settings.
2. Preserve the existing current test report; tune thresholds and choose checkpoints using validation data only.
3. For the traffic-control goal, measure vehicle-count error per approach and decision stability on labeled intersection videos. Detection mAP alone does not establish reliable signal control.

## Presenter summary

> “We use YOLOv8n for image-based vehicle detection and a separate rule-based module for approach counting and signal selection. On validation, the current detector reaches 57.7% mAP@50 and 37.0% mAP@50:95. On the held-out test split it reaches 57.3% and 35.6%, respectively, with comparatively low motorcycle recall. Our tabular ensemble experiment uses synthetic density-derived labels, so it is a methodological demonstration rather than a real-world result.”
