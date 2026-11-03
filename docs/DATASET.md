# VegMitra Vehicle Detection Dataset

## Purpose and source

The YOLO detector is trained and evaluated on a BDD100K-derived vehicle-detection dataset. BDD100K object annotations are converted from JSON pixel-coordinate boxes into Ultralytics YOLO text labels. Source images and generated split folders are local data and are not included in the public source repository.

## Classes

| YOLO ID | Model class | BDD100K source category |
| ---: | --- | --- |
| 0 | car | `car` |
| 1 | motorcycle | `motor` |
| 2 | bus | `bus` |
| 3 | truck | `truck` |

BDD100K `bike` means bicycle and is not mapped to motorcycle. Pedestrians, traffic lights, and other categories are excluded. The detector has no dedicated ambulance, fire-truck, or police class.

## Annotation format

One text file accompanies each image. Each non-empty line represents one labeled object:

```text
class_id x_center y_center width height
```

The box coordinates are normalized to image width and height. These are object-instance labels, not unique vehicle identities.

## Current expanded split

| Split | Images | Cars | Motorcycles | Buses | Trucks | Total boxes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Train | 18,862 | 193,754 | 3,002 | 7,642 | 10,002 | 214,400 |
| Validation | 2,037 | 21,059 | 358 | 532 | 1,004 | 22,953 |
| Test | 2,610 | 26,903 | 803 | 764 | 1,500 | 29,970 |
| **Total** | **23,509** | **241,716** | **4,163** | **8,938** | **12,506** | **267,323** |

Cars dominate the data. Motorcycle examples are much less common, which is reflected in the current per-class recall and AP. Counts are labeled boxes, not image counts or unique vehicles. The splits derive from their corresponding BDD100K source splits; keep test data held out for final evaluation.

## Where data lives and how it is configured

The expected prepared layout is `data/{train,val,test}/{images,labels}`. `training/dataset.yaml` uses `path: data`, with `train/images`, `val/images`, and `test/images` under that directory. Populate those folders before training/evaluation, or edit the YAML path to your local dataset.

`training/prepare_dataset.py` is an older preparation workflow for the original 15,000-image target. It clears/rebuilds split directories and must not be run casually against the current project data. Inspect the script and back up data before using it. The older numbered examples and historical splits are not the source of the current epoch-60 metrics.

The repository also contains `datasets/coco8`, a small Ultralytics smoke-test sample. It is separate from the BDD100K-derived training set.

## Evaluation and interpretation

The current checkpoint's validation/test results are summarized in [`MODEL_EVALUATION.md`](MODEL_EVALUATION.md). On the held-out current test split, overall precision is 67.0%, recall is 52.2%, mAP@50 is 57.3%, and mAP@50:95 is 35.6%. These are object-detection metrics, not ordinary image classification accuracy. See [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md) for training history and artifact paths.

Check BDD100K's distribution terms before redistributing source images or annotations. Local camera data is still needed to estimate performance under the project's intended camera, geography, weather, and lighting conditions.
