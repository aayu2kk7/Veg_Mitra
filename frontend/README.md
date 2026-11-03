# VegMitra Web Dashboard

This folder contains the browser dashboard for viewing traffic state, plus an interactive client-side demo mode. The application has a React/TypeScript source tree and a checked-in browser bundle. The Python HTTP server is in the project root.

## Run locally

From the project root, start the backend/dashboard server:

```powershell
python serve_dashboard.py
```

Then open [http://localhost:8080](http://localhost:8080). The server serves files from `frontend/` and exposes API routes for current traffic state and image analysis where implemented. For the interactive demo, use the dashboard's demo mode; demo values are generated in the browser and are not YOLO observations.

You can also use the frontend development scripts from this directory after dependencies are installed:

```powershell
npm install
npm run dev
```

`npm run build` runs TypeScript compilation and Vite's production build. `npm run serve` invokes the root Python server. Inspect `package.json` for the available scripts.

## How dashboard data is represented

In backend mode, the UI reads normalized traffic-state data derived from `output/traffic_state.json` / the server API. Relevant fields include:

| Field | Meaning |
| --- | --- |
| `selected_green_road` | Road selected by Python's density, minimum-hold, hysteresis, and tie logic. |
| `counts` | Current frame's approach counts from detector/tracking logic. |
| `smoothed_counts` | Rolling frame-window counts. |
| `density` | Smoothed counts expressed against configured road capacity. |
| `green_hold_remaining` | Remaining programmed minimum hold duration. |
| `frame_index`, `timestamp` | Video/frame state metadata. |
| `emergency_active`, `emergency_road`, `emergency_class` | Emergency status fields, if supplied by the backend. Current trained YOLO classes do not include emergency vehicles. |

The UI may also show calculated or simulated estimates such as congestion categories, wait-time estimates, fuel estimates, or demo scenarios. These are not direct measurements from YOLO and should be presented as estimates/demo values. The trained model detects vehicles; it does not itself select signal phases.

## Modes and limitations

- **Backend mode:** displays the latest state produced by the Python application/server. The backend detector requires an input image/video and the chosen model checkpoint.
- **Demo mode:** client-side simulated counts and scenarios for exploring the UI. Emergency examples in demo mode do not prove image-based emergency recognition.
- **Signal behavior:** the dashboard visualizes a simulated decision. There is no connection to physical traffic-light hardware.
- **Metrics:** vehicle counts may contain misses, duplicates, or track errors. Waiting-time and fuel figures are estimates, not instrumented outcomes.

## Current frontend structure

```text
frontend/
├── index.html
├── app.bundle.js
├── traffic_3d.js
├── sample_analysis.json
├── sample_raw_images.json
├── package.json
├── tsconfig.json
├── styles/
└── src/
    ├── components/
    ├── services/
    └── types/
```

The backend, detector, training scripts, current checkpoint, dataset, and MATLAB app are documented in the root [`README.md`](../README.md) and [`docs/PROJECT_CONTEXT.md`](../docs/PROJECT_CONTEXT.md).
