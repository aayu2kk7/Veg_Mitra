# Model Evaluation Report: VegMitra YOLOv8

**Status:** Current as of 02 November 2026. For project history, data provenance, and run details, see [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md).

## 1. Evaluation scope

The detector predicts bounding boxes for four vehicle classes: car, motorcycle, bus, and truck. Its validation metrics measure object detection and localization. They do not directly measure traffic counts, signal decisions, or safety at a real intersection.

Current best checkpoint:

```text
training/runs/traffic_finetune_from43_to60_20261101/weights/best.pt
```

It is a YOLOv8n model fine-tuned from COCO-pretrained weights. The expanded BDD100K-derived dataset has 18,862 train, 2,037 validation, and 2,610 test images. The epoch-60 checkpoint has been evaluated on both validation and the held-out test split.

## 2. Metric definitions

- **IoU (Intersection over Union):** area shared by the predicted and labeled boxes divided by the area covered by either box. It scores localization overlap.
- **True positive:** a predicted box with the correct class and sufficient IoU match to an unused ground-truth box.
- **False positive:** an unmatched or duplicate prediction, including a wrong-class prediction.
- **False negative:** a labeled object with no qualifying prediction.
- **Precision:** TP / (TP + FP), the fraction of kept detections that are correct.
- **Recall:** TP / (TP + FN), the fraction of labeled objects that were detected.
- **AP:** area under the precision-recall curve for one class at a specified IoU criterion.
- **mAP@50:** mean AP across classes at IoU 0.50.
- **mAP@50:95:** mean AP across classes and IoU thresholds 0.50, 0.55, …, 0.95. It is stricter about box placement.
- **F1:** harmonic mean of precision and recall at a particular operating point, `2PR/(P+R)`. It is useful as a summary but does not replace AP/mAP.

Ordinary image-classification accuracy is not meaningful for object detection because there is no well-defined finite set of background true negatives. Report precision, recall, AP/mAP, and class support instead.

## 3. Current validation results

The selected best checkpoint was evaluated on 2,037 validation images containing 22,953 labeled objects.

| Class | Images with class | Objects | Precision | Recall | F1* | AP@50 | AP@50:95 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Car | 2,027 | 21,059 | 77.2% | 66.1% | 71.2% | 73.2% | 44.4% |
| Motorcycle | 276 | 358 | 65.2% | 40.5% | 50.0% | 42.4% | 20.1% |
| Bus | 427 | 532 | 63.6% | 55.6% | 59.3% | 60.3% | 45.3% |
| Truck | 633 | 1,004 | 64.8% | 48.9% | 55.7% | 54.9% | 38.1% |
| **Overall** | **2,037** | **22,953** | **67.7%** | **52.8%** | **59.3%*** | **57.7%** | **37.0%** |

`F1*` is derived from the displayed precision/recall values and rounded. AP values are per class; the overall row is mAP. The best checkpoint is selected by validation fitness, so it need not have the highest precision, recall, or AP individually.

### Interpretation

- The detector returns correct boxes for a useful share of its predictions, but its 52.8% overall recall means many labeled objects are still missed at the reported operating point.
- Cars have the strongest AP. Motorcycles have the weakest recall and localization AP, consistent with their low validation support (358 objects).
- mAP@50:95 (37.0%) is lower than mAP@50 (57.7%) because it also rewards tighter localization at stricter IoU thresholds.
- These figures are validation results, not a claim of “65–75% accuracy” and not a measure of final traffic-control performance.

## 4. Current held-out test results

The current best checkpoint was evaluated on all 2,610 test images (29,970 labeled objects) on CUDA. Overall precision is 67.0%, recall 52.2%, F1 58.7%, mAP@50 57.3%, and mAP@50:95 35.6%.

| Class | Images with class | Objects | Precision | Recall | F1 | AP@50 | AP@75 | AP@50:95 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Car | 2,588 | 26,903 | 76.2% | 67.7% | 71.7% | 73.5% | 44.7% | 44.6% |
| Motorcycle | 607 | 803 | 69.9% | 42.7% | 53.0% | 50.3% | 18.0% | 23.2% |
| Bus | 574 | 764 | 56.4% | 51.0% | 53.6% | 51.0% | 40.3% | 36.9% |
| Truck | 974 | 1,500 | 65.3% | 47.5% | 55.0% | 54.3% | 41.5% | 37.5% |

Artifacts: [`classification_report_test.csv`](../training/results/classification_report_test.csv) and [`evaluation_metrics_test.json`](../training/results/evaluation_metrics_test.json). Previous generic files were preserved as `*_pre_current_epoch60_20261102.*` before this evaluation. Keep test results separate from validation and do not tune against them.

The explicit evaluation command was:

```powershell
python training/evaluate.py --model training/runs/traffic_finetune_from43_to60_20261101/weights/best.pt --split test
```

Check `python training/evaluate.py --help` if CLI options differ in the local revision. Record checkpoint path, split, image count, class support, confidence/IoU settings, metrics, and output filenames in the report.

## 5. Visual diagnostics and artifacts

The current run directory contains training curves, PR/P/R/F1 curves, raw and normalized confusion matrices, label distribution plots, and validation prediction examples. These help locate class confusions and missed/poorly localized objects. A confusion matrix is a useful diagnostic but does not include every aspect of localization quality captured by mAP.

The current classification and detection report is [`../output/pdf/vegmitra_yolov8n_classification_report_test_2026-11-03.pdf`](../output/pdf/vegmitra_yolov8n_classification_report_test_2026-11-03.pdf). The older `vegmitra_yolo_training_report_2026-11-01.pdf` predates the current held-out test evaluation.

## 6. Further evaluation needed for the traffic application

Detection scores alone do not answer whether the system estimates queues or picks a useful green phase. Add an intersection-video evaluation with manually reviewed ground truth and report:

- per-class and per-approach count error (MAE/RMSE), including missed and duplicate tracks;
- count stability over time and performance under occlusion, night, rain, and camera angle changes;
- decision agreement or delay against a defined traffic-control baseline;
- inference latency/FPS on the deployment hardware;
- independent validation of signal timing and fail-safe behavior.

The current controller is rule-based. Emergency-priority code exists, but the four-class detector cannot identify emergency vehicles without additional classes/data or a trusted external signal. The synthetic tabular classifier is separate and is not integrated with the controller.
