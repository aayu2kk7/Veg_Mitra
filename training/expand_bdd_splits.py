"""Add class-targeted BDD100K examples to the existing YOLO dataset.

Images are selected only from the matching original BDD split. Existing
validation and test images are never moved into training. All four classes in
the project are retained whenever an image is selected.
"""

import json
import os
import random
import shutil
from collections import Counter
from datetime import datetime
from pathlib import Path



PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATA_ROOT = PROJECT_ROOT / "data"
SOURCE_ROOT = Path(os.environ.get("BDD100K_ROOT", str(PROJECT_ROOT / "bdd100k")))
CLASS_IDS = {"car": 0, "motor": 1, "motorcycle": 1, "bus": 2, "truck": 3}
RARE_CLASSES = ("motorcycle", "bus", "truck")
SEED = 24017
IMAGE_WIDTH = 1280
IMAGE_HEIGHT = 720

# Desired minimum object counts after adding the recoverable and selected
# examples. Motorcycle cannot be increased from BDD100K's original train split.
TARGETS = {
    "train": {"bus": 7500, "truck": 10000},
    "val": {"motorcycle": 350, "bus": 500, "truck": 1000},
    "test": {"motorcycle": 800, "bus": 700, "truck": 1500},
}


def read_bdd_objects(label_path: Path):
    data = json.loads(label_path.read_text(encoding="utf-8"))
    return data.get("frames", [{}])[0].get("objects", [])


def object_counts(objects):
    counts = Counter()
    for obj in objects:
        category = obj.get("category")
        name = "motorcycle" if category in {"motor", "motorcycle"} else category
        if name in {"car", "motorcycle", "bus", "truck"} and obj.get("box2d"):
            counts[name] += 1
    return counts


def read_bdd_records(objects, image_path: Path):
    # BDD100K detection frames are consistently 1280x720.
    width, height = IMAGE_WIDTH, IMAGE_HEIGHT
    lines = []
    counts = Counter()
    for obj in objects:
        class_id = CLASS_IDS.get(obj.get("category"))
        box = obj.get("box2d")
        if class_id is None or not box:
            continue
        x1 = max(0.0, min(float(box["x1"]), width))
        y1 = max(0.0, min(float(box["y1"]), height))
        x2 = max(0.0, min(float(box["x2"]), width))
        y2 = max(0.0, min(float(box["y2"]), height))
        bw, bh = x2 - x1, y2 - y1
        if bw <= 0 or bh <= 0:
            continue
        lines.append(
            f"{class_id} {(x1 + x2) / (2 * width):.6f} "
            f"{(y1 + y2) / (2 * height):.6f} "
            f"{bw / width:.6f} {bh / height:.6f}"
        )
        name = "motorcycle" if class_id == 1 else {0: "car", 2: "bus", 3: "truck"}[class_id]
        counts[name] += 1
    return lines, counts


def write_label(path: Path, lines):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")


def count_existing(split: str):
    counts = Counter()
    images_dir = DATA_ROOT / split / "images"
    labels_dir = DATA_ROOT / split / "labels"
    for image_path in images_dir.iterdir():
        if not image_path.is_file():
            continue
        label_path = labels_dir / f"{image_path.stem}.txt"
        if not label_path.exists():
            continue
        for line in label_path.read_text(encoding="utf-8").splitlines():
            fields = line.split()
            if not fields:
                continue
            class_id = int(fields[0])
            name = {0: "car", 1: "motorcycle", 2: "bus", 3: "truck"}.get(class_id)
            if name:
                counts[name] += 1
    return counts


def main():
    rng = random.Random(SEED)
    summary = {"source": str(SOURCE_ROOT), "seed": SEED, "recovered_labels": [], "repaired_images": [], "added": {}, "counts": {}}

    # Recover annotations for images already present in the project but missing
    # YOLO text labels. This fixes the 1,680 train and 1 test orphan images.
    for split in ("train", "val", "test"):
        images_dir = DATA_ROOT / split / "images"
        labels_dir = DATA_ROOT / split / "labels"
        source_labels = SOURCE_ROOT / "labels" / split
        for image_path in images_dir.iterdir():
            if not image_path.is_file():
                continue
            label_path = labels_dir / f"{image_path.stem}.txt"
            if label_path.exists():
                continue
            json_path = source_labels / f"{image_path.stem}.json"
            if not json_path.exists():
                continue
            source_image = SOURCE_ROOT / "images" / "100k" / split / image_path.name
            annotation_image = source_image if source_image.exists() else image_path
            if source_image.exists():
                shutil.copy2(source_image, image_path)
                summary["repaired_images"].append({"split": split, "image": image_path.name})
            lines, _ = read_bdd_records(read_bdd_objects(json_path), annotation_image)
            write_label(label_path, lines)
            summary["recovered_labels"].append({"split": split, "image": image_path.name})

    for split in ("train", "val", "test"):
        before = count_existing(split)
        current_stems = {p.stem for p in (DATA_ROOT / split / "images").iterdir() if p.is_file()}
        source_images = SOURCE_ROOT / "images" / "100k" / split
        source_labels = SOURCE_ROOT / "labels" / split
        candidates = []
        for json_path in source_labels.glob("*.json"):
            stem = json_path.stem
            if stem in current_stems:
                continue
            image_path = source_images / f"{stem}.jpg"
            if not image_path.exists():
                continue
            objects = read_bdd_objects(json_path)
            counts = object_counts(objects)
            if any(counts.get(name, 0) for name in RARE_CLASSES):
                candidates.append({"stem": stem, "image": image_path, "json": json_path, "objects": objects, "counts": counts})

        selected = {}
        available = candidates[:]
        rng.shuffle(available)
        current = before.copy()
        for class_name, target in TARGETS[split].items():
            pool = [item for item in available if item["counts"].get(class_name, 0)]
            rng.shuffle(pool)
            for item in pool:
                if current[class_name] >= target:
                    break
                if item["stem"] in selected:
                    continue
                selected[item["stem"]] = item
                current.update(item["counts"])

        added = []
        for item in selected.values():
            dest_image = DATA_ROOT / split / "images" / item["image"].name
            dest_label = DATA_ROOT / split / "labels" / f"{item['stem']}.txt"
            lines, _ = read_bdd_records(item["objects"], item["image"])
            shutil.copy2(item["image"], dest_image)
            write_label(dest_label, lines)
            added.append({"image": item["image"].name, "boxes": dict(item["counts"])})

        after = count_existing(split)
        summary["added"][split] = added
        summary["counts"][split] = {
            "before": dict(before),
            "after": dict(after),
            "targets": TARGETS[split],
            "added_images": len(added),
        }

    # Preserve stale Ultralytics cache files while ensuring the next run scans
    # the expanded labels and images.
    for split in ("train", "val", "test"):
        cache = DATA_ROOT / split / "labels.cache"
        if cache.exists():
            backup = cache.with_name(f"labels.cache.pre_expansion_{datetime.now():%Y%m%d_%H%M%S}.bak")
            shutil.move(str(cache), str(backup))
            summary.setdefault("cache_backups", []).append(str(backup))

    manifest = DATA_ROOT / "expansion_manifest.json"
    manifest.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary["counts"], indent=2))
    print(f"Recovered missing labels: {len(summary['recovered_labels'])}")
    print(f"Manifest: {manifest}")


if __name__ == "__main__":
    main()
