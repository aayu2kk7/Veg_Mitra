# Vega Mitra

Vega Mitra is a four-approach traffic assessment project. It combines a YOLOv8n vehicle detector for uploaded images, per-approach vehicle and density assessment, demand-based signal selection, and an interactive traffic dashboard.

## Project links

- **Live demo:** https://vegmitra-demo.onrender.com/
- **GitHub repository:** https://github.com/aayu2kk7/Veg_Mitra

The dashboard visualizes North, South, East, and West approaches. It presents vehicle counts, estimated density, signal states, and phase timing. The project also includes a sample-traffic simulation for exploring the dashboard.

## Image-based vehicle detection

The trained YOLOv8n model detects four vehicle classes in still images: car, motorcycle, bus, and truck. Image analysis returns class-labeled bounding boxes and vehicle counts. Uploaded images for the four approaches are assessed to estimate each approach's density and choose a signal phase using the measured traffic demand.

The traffic assessment and signal selection are software logic; the signal controller is not a learned model and is not connected to physical traffic lights.

## Dataset and evaluation

The BDD100K-derived dataset contains 23,509 images and 267,323 labeled object instances across the four vehicle classes.

| Split | Images | Labeled objects |
| --- | ---: | ---: |
| Train | 18,862 | 214,400 |
| Validation | 2,037 | 22,953 |
| Held-out test | 2,610 | 29,970 |

The current YOLOv8n checkpoint's held-out test evaluation:

| Metric | Result |
| --- | ---: |
| Precision | 67.0% |
| Recall | 52.2% |
| mAP@50 | 57.3% |
| mAP@50:95 | 35.6% |

These are object-detection metrics for the held-out image test split. They do not measure video tracking, traffic-count error across video, or real-world signal-control performance. Per-class results and metric definitions are in [`docs/MODEL_EVALUATION.md`](docs/MODEL_EVALUATION.md); raw metrics are in [`training/results/evaluation_metrics_test.json`](training/results/evaluation_metrics_test.json).

## Processing scope

The model workflow analyzes uploaded still images. End-to-end video-frame processing, OpenCV video integration, and BoT-SORT tracking are not implemented features of this project. The dashboard's sample-traffic simulation is separate from model detection results.

## Run locally

To launch the sample dashboard from the project root in PowerShell:

```powershell
$env:VEGMITRA_DEMO_MODE = "true"
python serve_dashboard.py
```

Open http://localhost:8080. To run image analysis locally, provide the trained checkpoint and the project's inference dependencies. The `.pt` checkpoint is not included in this public repository.

## Main components

| Path | Purpose |
| --- | --- |
| `frontend/index.html` | Interactive four-approach dashboard and sample simulation. |
| `frontend/src/` | React and TypeScript dashboard source. |
| `serve_dashboard.py` | Python HTTP server, dashboard/API routes, and model-status health endpoint. |
| `model_analyzer.py` | Still-image detection, bounding-box rendering, and per-approach analysis. |
| `detector.py`, `main.py` | Experimental video-processing code; video-frame and tracking workflow is not implemented. |
| `training/` | Model training configuration, scripts, and evaluation artifacts. |
| `VegMitra_MATLAB/` | Intersection traffic simulation files. |

## Deployment

The Render Blueprint is defined in [`render.yaml`](render.yaml). The live demo link above serves the dashboard. Model and image-inference deployment settings may be configured separately when publishing the checkpoint and inference dependencies.

This project is intended for demonstration and evaluation, not operation of municipal traffic equipment.
