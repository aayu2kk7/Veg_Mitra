"""Create the VegMitra YOLO dataset from BDD100K detection JSON annotations."""

import json
import os
import random
import shutil
import argparse
from collections import Counter
from pathlib import Path

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parent.parent
SOURCE_ROOT = Path(os.environ.get("BDD100K_ROOT", str(PROJECT_ROOT / "bdd100k")))
DEST_ROOT = PROJECT_ROOT / "data"
SEED = 42
SPLITS = {"train": ("train", 12_000), "val": ("val", 1_500), "test": ("test", 1_500)}
CLASS_IDS = {"car": 0, "motor": 1, "bus": 2, "truck": 3}


def read_objects(label_path):
    data = json.loads(label_path.read_text(encoding="utf-8"))
    frames = data.get("frames") or []
    if not frames:
        return []
    objects = []
    for obj in frames[0].get("objects") or []:
        class_id = CLASS_IDS.get(obj.get("category"))
        box = obj.get("box2d")
        if class_id is None or not box:
            continue
        try:
            x1, y1, x2, y2 = (float(box[k]) for k in ("x1", "y1", "x2", "y2"))
        except (KeyError, TypeError, ValueError):
            continue
        if x2 > x1 and y2 > y1:
            objects.append((class_id, x1, y1, x2, y2))
    return objects


def yolo_line(obj, width, height):
    class_id, x1, y1, x2, y2 = obj
    x1, x2 = max(0.0, min(width, x1)), max(0.0, min(width, x2))
    y1, y2 = max(0.0, min(height, y1)), max(0.0, min(height, y2))
    if x2 <= x1 or y2 <= y1:
        return None
    cx, cy = (x1 + x2) / (2 * width), (y1 + y2) / (2 * height)
    bw, bh = (x2 - x1) / width, (y2 - y1) / height
    return f"{class_id} {cx:.6f} {cy:.6f} {bw:.6f} {bh:.6f}"


def main(source_root=SOURCE_ROOT):
    if not source_root.is_dir():
        raise FileNotFoundError(f"BDD100K source not found: {source_root}")
    rng = random.Random(SEED)
    selected = {}
    for dest_split, (source_split, count) in SPLITS.items():
        image_dir = source_root / "images" / "100k" / source_split
        label_dir = source_root / "labels" / source_split
        candidates = []
        for label_path in sorted(label_dir.glob("*.json")):
            image_path = image_dir / f"{label_path.stem}.jpg"
            if not image_path.is_file():
                continue
            objects = read_objects(label_path)
            if objects:
                candidates.append((image_path, objects))
        if len(candidates) < count:
            raise RuntimeError(f"{source_split} has only {len(candidates)} labeled target images; need {count}")
        if dest_split == "train":
            motorcycle = [entry for entry in candidates if any(obj[0] == 1 for obj in entry[1])]
            other = [entry for entry in candidates if not any(obj[0] == 1 for obj in entry[1])]
            rng.shuffle(motorcycle)
            rng.shuffle(other)
            selected[dest_split] = (motorcycle + other)[:count]
            rng.shuffle(selected[dest_split])
            print(f"Selected {count:,} train images from {len(candidates):,} eligible, including all {min(len(motorcycle), count):,} motorcycle-containing images")
        else:
            rng.shuffle(candidates)
            selected[dest_split] = candidates[:count]
            print(f"Selected {count:,} annotated images from BDD100K {source_split} ({len(candidates):,} eligible)")

    totals = Counter()
    for split, entries in selected.items():
        image_out = DEST_ROOT / split / "images"
        label_out = DEST_ROOT / split / "labels"
        image_out.mkdir(parents=True, exist_ok=True)
        label_out.mkdir(parents=True, exist_ok=True)
        # Remove prior split files so reruns always produce exact split sizes.
        for old_file in image_out.iterdir():
            if old_file.is_file():
                old_file.unlink()
        for old_file in label_out.iterdir():
            if old_file.is_file():
                old_file.unlink()
        for image_path, objects in entries:
            with Image.open(image_path) as image:
                width, height = image.size
            lines = [line for obj in objects if (line := yolo_line(obj, width, height))]
            if not lines:
                raise RuntimeError(f"No valid boxes after clipping: {image_path}")
            shutil.copy2(image_path, image_out / image_path.name)
            (label_out / f"{image_path.stem}.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
            totals.update(int(line.split()[0]) for line in lines)
        print(f"Wrote {len(entries):,} images and YOLO labels to data/{split}")

    print("Class instances across all splits:")
    for class_name, class_id in (("car", 0), ("motorcycle", 1), ("bus", 2), ("truck", 3)):
        print(f"  {class_name}: {totals[class_id]:,}")
    print("Done. Split selection is deterministic (seed 42); source official splits remain disjoint.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Prepare the VegMitra YOLO dataset from BDD100K JSON labels.")
    parser.add_argument("--source-root", type=Path, default=SOURCE_ROOT, help="BDD100K root containing images/ and labels/")
    args = parser.parse_args()
    main(args.source_root)
