import json
import joblib
import pandas as pd
import numpy as np
from sklearn.metrics import classification_report, confusion_matrix

def evaluate_saved_classifiers(
    csv_path='traffic_ml/traffic_features.csv',
    models_dir='traffic_ml/models'
):
    print('==================================================')
    print('   VegMitra: Evaluating Saved Ensemble Models    ')
    print('==================================================')

    df = pd.read_csv(csv_path)
    feature_cols = ['car_count', 'motorcycle_count', 'bus_count', 'truck_count', 'total_vehicles', 'avg_speed_kmh', 'lane_occupancy_pct', 'time_slot']
    X = df[feature_cols]
    y = df['traffic_level']

    # Sample unseen scenario
    test_scenario = pd.DataFrame([{
        'car_count': 32,
        'motorcycle_count': 14,
        'bus_count': 4,
        'truck_count': 3,
        'total_vehicles': 53,
        'avg_speed_kmh': 16.5,
        'lane_occupancy_pct': 88.3,
        'time_slot': 1  # Morning peak
    }])

    print('\n[Inference Test] Sample Road Traffic Features:')
    print(test_scenario.to_dict(orient='records')[0])

    for model_file in sorted(os.listdir(models_dir)):
        if model_file.endswith('.joblib'):
            clf = joblib.load(os.path.join(models_dir, model_file))
            pred = clf.predict(test_scenario)[0]
            probs = clf.predict_proba(test_scenario)[0] if hasattr(clf, 'predict_proba') else None
            print(f'Model [{model_file:25s}] Predicted Congestion Level: {pred:6s} | Confidence: {max(probs):.3f}' if probs is not None else f'Model [{model_file}] Predicted: {pred}')

if __name__ == '__main__':
    import os
    evaluate_saved_classifiers()
