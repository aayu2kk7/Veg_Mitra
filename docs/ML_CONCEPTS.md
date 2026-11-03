# Machine-Learning Concepts Used in VegMitra

This guide connects common ML concepts to the actual components in this repository. The detector, controller, and tabular experiment are different parts of the system and use different methods.

## 1. Supervised learning and labels

In supervised learning, a model learns from examples paired with target answers. YOLO training images are paired with object class IDs and bounding boxes. The separate tabular experiment pairs numeric traffic features with a `LOW`, `MEDIUM`, or `HIGH` congestion label.

## 2. Object detection and transfer learning

Object detection predicts **what** objects are present and **where** they are located. The VegMitra detector is Ultralytics YOLOv8n, fine-tuned for car, motorcycle, bus, and truck boxes. It starts from pretrained YOLO weights and adapts them to the target dataset; this is transfer learning.

YOLO is a one-stage detector: one network pass predicts class and location candidates. At inference, confidence filtering and non-maximum suppression remove low-confidence and duplicate overlapping predictions. Training optimizes box-localization, class, and distribution-focal loss terms. These model internals differ from the hand-written traffic control rules.

## 3. Data splits

- **Training set:** contributes examples used to update model weights.
- **Validation set:** monitors generalization and supports model/checkpoint selection and tuning.
- **Test set:** held-out examples for final reporting. Repeatedly tuning choices against test results weakens the independence of the reported estimate.

The current detection data has 18,862 training, 2,037 validation, and 2,610 test images. Cars dominate the object labels, while motorcycles have relatively low support.

## 4. Training terms

- **Epoch:** one pass over the training examples. The selected detector run continued 17 epochs after an earlier 43, reaching cumulative epoch 60.
- **Batch size:** number of images processed per update; the recorded continuation used 4.
- **Loss:** numeric measure of prediction error. Gradients of loss are used to update the network.
- **Backpropagation:** computes how each model weight contributed to loss.
- **Optimizer:** applies gradient-based weight updates. The final continuation recorded AdamW.
- **Learning rate:** controls update size. The recorded continuation started at 0.0002 with a final learning-rate fraction of 0.1.
- **Weight decay:** regularization that discourages unnecessarily large weights; recorded value 0.0005.
- **Augmentation:** transforms examples during training (HSV changes, scale, translation, horizontal flips, mosaic) to expose the model to more variation without collecting new scenes.
- **Checkpoint:** saved model weights. `best.pt` is selected by validation fitness; `last.pt` is the final saved epoch state.

The checked-in `training/config.yaml` describes a separate new-run configuration and is not the exact configuration used for the final continuation. Consult the selected run's `args.yaml` and [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md).

## 5. Detection metrics

- **True positive:** a predicted box matched to a ground-truth object under the evaluator's class and IoU rules.
- **False positive:** an unmatched or incorrectly classified predicted box.
- **False negative:** a labeled object that was not detected.
- **Precision:** `TP / (TP + FP)`; higher precision generally means fewer false detections.
- **Recall:** `TP / (TP + FN)`; higher recall generally means fewer missed objects.
- **IoU:** intersection area divided by union area for predicted and labeled boxes.
- **AP:** area under a class's precision-recall curve at a specified IoU criterion.
- **mAP@50:** mean AP across classes at IoU 0.50.
- **mAP@50:95:** mean AP over IoU thresholds 0.50, 0.55, ..., 0.95; stricter localization thresholds lower the score when boxes are loose.
- **F1:** `2 × precision × recall / (precision + recall)` at a chosen operating point.

Ordinary image-classification accuracy is not a useful single summary for object detection: a detection must match in class and location, and the background does not provide a meaningful finite true-negative count. Current model metrics and supports are in [`MODEL_EVALUATION.md`](MODEL_EVALUATION.md).

## 6. Ensembles, bagging, and boosting

An ensemble combines multiple estimators. Different ensemble strategies can reduce variance or improve a sequence of learners, but they are **not the method used for the YOLO detector**.

| Method | How it learns | VegMitra tabular experiment |
| --- | --- | --- |
| Decision Tree | One sequence of feature splits | Baseline, maximum depth 5 |
| Bagging | Trains models on bootstrap samples and combines their predictions; often reduces variance | Random Forest, 100 trees, maximum depth 5 |
| AdaBoost | Sequential learners emphasize examples previous learners misclassified | 50 estimators |
| Gradient Boosting | Sequentially adds trees that reduce the ensemble's loss/fit residual gradients | 100 estimators, learning rate 0.1, depth 3 |

Random Forest adds random feature selection at split points, which reduces correlation among trees. AdaBoost changes example weights; Gradient Boosting fits successive learners to residual information. Both are sequential methods, but their exact update rules differ.

The experiment uses 600 generated rows, eight numeric features, and density-derived labels with an 80/20 stratified split. Since the label is constructed from density, high scores show that models can reproduce the synthetic rule; they are not a measure of performance on real traffic. These trained models are saved under `traffic_ml/models/` and are not called by the video controller.

## 7. Why YOLO for images?

Decision trees and classic tabular ensembles expect fixed numeric feature rows. Raw images contain spatial structure: nearby pixels, edges, shapes, and objects. Convolutional neural networks learn spatial feature maps and perform box localization and classification together. YOLO is suited to the detector task; classic ensembles are used here for a small structured-feature demonstration.

## 8. VegMitra's non-ML logic

After detections, the Python pipeline uses BoT-SORT tracking, road-region geometry, movement heuristics, rolling averages, density arithmetic, minimum-green hold, hysteresis, and round-robin tie handling. These steps are algorithms and programmed rules, not outputs learned by the neural network. Likewise, MATLAB emergency and pedestrian behavior is simulation logic.

## 9. Bias, variance, and generalization

**Bias** is error from a model that is too simple or makes restrictive assumptions. **Variance** is sensitivity to the particular training sample. Bagging often reduces variance; boosting can improve a weak learner's fit but may overfit noisy data. Neither guarantees better generalization. A representative dataset, separate validation/test data, per-class metrics, and evaluation on local intersection footage remain important for VegMitra.
