import os
import sys
import yaml
import shutil
from datetime import datetime
from pathlib import Path
import torch
from ultralytics import YOLO

def train():
    print('==================================================')
    print('       VegMitra YOLOv8 Fine-Tuning Pipeline        ')
    print('==================================================')

    # Detect hardware
    cuda_available = torch.cuda.is_available()
    device = '0' if cuda_available else 'cpu'
    gpu_name = torch.cuda.get_device_name(0) if cuda_available else 'None (Running on CPU)'
    
    print(f'[Hardware] CUDA Available: {cuda_available}')
    print(f'[Hardware] Compute Device: {device} ({gpu_name})')
    if not cuda_available:
        print('[Hardware] CPU training on 12,000 images for up to 100 epochs may take a long time.')

    # Load configuration
    config_path = Path(__file__).parent / 'config.yaml'
    with open(config_path, 'r') as f:
        cfg = yaml.safe_load(f)

    epochs = cfg['training'].get('epochs', 100)
    batch = cfg['training'].get('batch_size', 4)
    imgsz = cfg['training'].get('imgsz', 640)
    lr0 = cfg['training'].get('learning_rate0', 0.01)
    patience = cfg['training'].get('patience', 10)
    seed = cfg['training'].get('seed', 42)
    lrf = cfg['training'].get('lrf', 0.01)
    momentum = cfg['training'].get('momentum', 0.937)
    weight_decay = cfg['training'].get('weight_decay', 0.0005)
    optimizer = cfg['training'].get('optimizer', 'auto')
    workers = cfg['training'].get('workers', 0)
    augmentations = cfg.get('augmentation', {})

    # Dataset yaml
    dataset_yaml = Path(__file__).parent / 'dataset.yaml'
    dataset_yaml_str = str(dataset_yaml.resolve())

    # Pretrained weights for transfer learning
    configured_weights = cfg.get('model', {}).get('pretrained_weights', 'yolov8n.pt')
    base_model_path = Path(configured_weights)
    if not base_model_path.is_absolute():
        base_model_path = Path(__file__).resolve().parent.parent / base_model_path
    if not base_model_path.exists():
        base_model_path = configured_weights
    else:
        base_model_path = str(base_model_path)

    print(f'[Transfer Learning] Base Model: {base_model_path}')
    print(f'[Hyperparameters] Epochs: {epochs} | Batch: {batch} | ImgSz: {imgsz} | LR0: {lr0} | Seed: {seed}')
    print(f'[Dataset] Config YAML: {dataset_yaml_str}')

    model = YOLO(base_model_path)
    run_name = f"traffic_finetune_{datetime.now().strftime('%Y%m%d_%H%M%S_%f')}"
    project_dir = Path(__file__).parent / 'runs'

    # Train model
    results = model.train(
        data=dataset_yaml_str,
        epochs=epochs,
        batch=batch,
        imgsz=imgsz,
        lr0=lr0,
        lrf=lrf,
        momentum=momentum,
        weight_decay=weight_decay,
        optimizer=optimizer,
        patience=patience,
        device=device,
        seed=seed,
        workers=workers,
        project=str(project_dir),
        name=run_name,
        exist_ok=False,
        plots=True,
        verbose=True,
        **augmentations
    )

    print('\n[Training Complete] Processing weights and results artifacts...')
    
    # Copy best/last weights to training/weights/
    run_dir = project_dir / run_name
    weights_src = run_dir / 'weights'
    weights_dst = Path(__file__).parent / 'weights'
    weights_dst.mkdir(parents=True, exist_ok=True)

    best_file = weights_dst / 'best.pt'
    last_file = weights_dst / 'last.pt'

    if (weights_src / 'best.pt').exists():
        shutil.copy(weights_src / 'best.pt', best_file)
        print(f'[Artifact] Saved best model to: {best_file}')
    if (weights_src / 'last.pt').exists():
        shutil.copy(weights_src / 'last.pt', last_file)
        print(f'[Artifact] Saved last model to: {last_file}')

    # Copy plots & metrics to training/results/
    results_dst = Path(__file__).parent / 'results'
    results_dst.mkdir(parents=True, exist_ok=True)
    
    for plot_file in run_dir.glob('*.png'):
        shutil.copy(plot_file, results_dst / plot_file.name)
    for csv_file in run_dir.glob('*.csv'):
        shutil.copy(csv_file, results_dst / csv_file.name)

    print(f'[Artifact] Evaluated plots and metrics copied to: {results_dst}')
    print('==================================================\n')

if __name__ == '__main__':
    train()
