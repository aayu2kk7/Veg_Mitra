import json
import time
import argparse
import csv
from pathlib import Path
import cv2
import numpy as np
from ultralytics import YOLO

def evaluate(model_path='training/weights/best.pt', dataset_yaml='training/dataset.yaml', split='val'):
    if split not in {'val', 'test'}:
        raise ValueError("split must be 'val' or 'test'")
    print('==================================================')
    print('       VegMitra YOLOv8 Evaluation Suite           ')
    print('==================================================')
    
    model = YOLO(model_path)
    print(f'[Evaluation] Evaluating model weights: {model_path}')
    print(f'[Evaluation] Dataset specification: {dataset_yaml}')

    t0 = time.time()
    metrics = model.val(data=dataset_yaml, split=split, verbose=True)
    val_time = time.time() - t0

    # Extract official metrics
    p = float(metrics.box.mp) if hasattr(metrics.box, 'mp') else 0.0
    r = float(metrics.box.mr) if hasattr(metrics.box, 'mr') else 0.0
    map50 = float(metrics.box.map50) if hasattr(metrics.box, 'map50') else 0.0
    map50_95 = float(metrics.box.map) if hasattr(metrics.box, 'map') else 0.0
    f1 = (2 * p * r / (p + r)) if (p + r) > 0 else 0.0
    # Detection-style classification report: each class gets precision, recall,
    # F1, and AP. This is more meaningful for boxes than a single accuracy.
    per_class = []
    for row in metrics.summary():
        per_class.append({
            'class': str(row['Class']),
            'images': int(row['Images']),
            'instances': int(row['Instances']),
            'precision': float(row['Box-P']),
            'recall': float(row['Box-R']),
            'f1': float(row['Box-F1']),
            'mAP50': float(row['mAP50']),
            'mAP75': float(row['mAP75']),
            'mAP50_95': float(row['mAP50-95']),
        })

    print('\n---------------- EVALUATION SUMMARY ----------------')
    print(f'Precision (Box P):       {p:.4f}')
    print(f'Recall (Box R):          {r:.4f}')
    print(f'F1-Score:                {f1:.4f}')
    print(f'mAP@0.5:                 {map50:.4f}')
    print(f'mAP@0.5:0.95:            {map50_95:.4f}')
    print(f'Inference/Val Duration:  {val_time:.2f}s')
    print('\nPer-class detection report:')
    print(f"{'Class':<14} {'Images':>7} {'Objects':>8} {'P':>7} {'R':>7} {'F1':>7} {'AP50':>7} {'AP75':>7} {'AP50-95':>8}")
    for row in per_class:
        print(f"{row['class']:<14} {row['images']:>7} {row['instances']:>8} {row['precision']:>7.3f} {row['recall']:>7.3f} {row['f1']:>7.3f} {row['mAP50']:>7.3f} {row['mAP75']:>7.3f} {row['mAP50_95']:>8.3f}")
    print('----------------------------------------------------')

    # Save metrics JSON artifact
    results_dir = Path('training/results')
    results_dir.mkdir(parents=True, exist_ok=True)
    
    summary = {
        'model_evaluated': str(model_path),
        'split_evaluated': split,
        'precision': p,
        'recall': r,
        'f1_score': f1,
        'mAP50': map50,
        'mAP50_95': map50_95,
        'per_class': per_class,
        'val_duration_seconds': round(val_time, 2),
        'class_names': list(model.names.values()),
        'hardware_device': 'cuda' if __import__('torch').cuda.is_available() else 'cpu'
    }

    eval_json = results_dir / f'evaluation_metrics_{split}.json'
    with open(eval_json, 'w') as f:
        json.dump(summary, f, indent=2)

    print(f'[Artifact] Saved metrics to: {eval_json}')
    report_csv = results_dir / f'classification_report_{split}.csv'
    with open(report_csv, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=list(per_class[0].keys()) if per_class else [])
        if per_class:
            writer.writeheader()
            writer.writerows(per_class)
    print(f'[Artifact] Saved per-class report to: {report_csv}')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Evaluate VegMitra detection weights on validation or test data.')
    parser.add_argument('--model', default='training/weights/best.pt', help='Path to the YOLO checkpoint')
    parser.add_argument('--data', default='training/dataset.yaml', help='Path to the dataset YAML')
    parser.add_argument('--split', choices=['val', 'test'], default='val', help='Use test only for final evaluation')
    args = parser.parse_args()
    evaluate(model_path=args.model, dataset_yaml=args.data, split=args.split)

