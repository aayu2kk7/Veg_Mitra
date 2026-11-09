# VegMitra demo deployment

The Render Blueprint in `render.yaml` deploys the dashboard and Python HTTP/API
server together at one URL. It starts in demo mode: the dashboard can show its
sample/simulated traffic view, while image-analysis endpoints return HTTP 503
until the trained checkpoint is configured. The demo build intentionally skips
PyTorch and Ultralytics so it does not download or silently use the generic COCO
model.

## Publish the demo

1. Commit and push this repository to GitHub.
2. Open [Render Blueprints](https://dashboard.render.com/blueprints) and choose
   **New Blueprint Instance**.
3. Connect `aayu2kk7/Veg_Mitra` and deploy the `render.yaml` Blueprint.
4. Render will provide one public URL for the dashboard and API. Its `/healthz`
   endpoint reports whether a model is connected.

## Connect the trained model later

When the epoch-60 `best.pt` checkpoint is available, add it to the deployment
at the documented path
`training/runs/traffic_finetune_from43_to60_20261101/weights/best.pt` (or use an
explicit model path in `model_analyzer.py`). In Render, change
`VEGMITRA_DEMO_MODE` to `false`, change the build command to
`pip install -r requirements.txt`, and redeploy. The server will then load the
fine-tuned checkpoint and the existing frontend will use its detection boxes,
counts, densities, and signal decision through the same URL.

The demo deployment does not contain the training dataset or model weights.
