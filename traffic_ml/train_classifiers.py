import os
import json
import joblib
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import RandomForestClassifier, AdaBoostClassifier, GradientBoostingClassifier
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix, classification_report

def train_and_evaluate_classifiers(
    csv_path='traffic_ml/traffic_features.csv',
    models_dir='traffic_ml/models',
    results_dir='traffic_ml/results'
):
    print('==================================================')
    print('  VegMitra Tabular ML: Bagging vs Boosting Study  ')
    print('==================================================')
    
    os.makedirs(models_dir, exist_ok=True)
    os.makedirs(results_dir, exist_ok=True)

    df = pd.read_csv(csv_path)
    feature_cols = ['car_count', 'motorcycle_count', 'bus_count', 'truck_count', 'total_vehicles', 'avg_speed_kmh', 'lane_occupancy_pct', 'time_slot']
    target_col = 'traffic_level'

    X = df[feature_cols]
    y = df[target_col]

    # Preprocessing / Splitting: 80% Train, 20% Unseen Test with stratification
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, random_state=42, stratify=y
    )
    print(f'[Dataset] Training set size: {len(X_train)} samples')
    print(f'[Dataset] Test set size:     {len(X_test)} samples')

    # Models to compare
    models = {
        'Decision Tree (Single Baseline)': DecisionTreeClassifier(max_depth=5, random_state=42),
        'Random Forest (Bagging)': RandomForestClassifier(n_estimators=100, max_depth=5, random_state=42),
        'AdaBoost (Boosting)': AdaBoostClassifier(n_estimators=50, random_state=42),
        'Gradient Boosting (Boosting)': GradientBoostingClassifier(n_estimators=100, learning_rate=0.1, max_depth=3, random_state=42)
    }

    comparison_results = []
    classes = sorted(list(y.unique()))

    for name, clf in models.items():
        print(f'\n[Training] Fitting {name}...')
        clf.fit(X_train, y_train)

        # Save model checkpoint
        slug = name.split()[0].lower()
        model_save_path = os.path.join(models_dir, f'{slug}_model.joblib')
        joblib.dump(clf, model_save_path)

        # Predictions on unseen test set
        y_pred = clf.predict(X_test)

        acc = accuracy_score(y_test, y_pred)
        prec = precision_score(y_test, y_pred, average='weighted', zero_division=0)
        rec = recall_score(y_test, y_pred, average='weighted', zero_division=0)
        f1 = f1_score(y_test, y_pred, average='weighted', zero_division=0)
        cm = confusion_matrix(y_test, y_pred, labels=classes)

        print(f'Accuracy:  {acc:.4f}')
        print(f'Precision: {prec:.4f}')
        print(f'Recall:    {rec:.4f}')
        print(f'F1-Score:  {f1:.4f}')

        comparison_results.append({
            'Model': name,
            'Accuracy': round(acc, 4),
            'Precision': round(prec, 4),
            'Recall': round(rec, 4),
            'F1_Score': round(f1, 4),
            'Confusion_Matrix': cm.tolist()
        })

    # Save summary table JSON
    summary_path = os.path.join(results_dir, 'classifier_comparison.json')
    with open(summary_path, 'w') as f:
        json.dump(comparison_results, f, indent=2)

    # Plot comparison bar chart
    res_df = pd.DataFrame(comparison_results)
    plt.figure(figsize=(10, 5))
    x_indices = np.arange(len(res_df))
    bar_width = 0.2

    plt.bar(x_indices - bar_width*1.5, res_df['Accuracy'], width=bar_width, label='Accuracy', color='#3498db')
    plt.bar(x_indices - bar_width*0.5, res_df['Precision'], width=bar_width, label='Precision', color='#2ecc71')
    plt.bar(x_indices + bar_width*0.5, res_df['Recall'], width=bar_width, label='Recall', color='#e67e22')
    plt.bar(x_indices + bar_width*1.5, res_df['F1_Score'], width=bar_width, label='F1-Score', color='#9b59b6')

    plt.xticks(x_indices, [m.split('(')[0].strip() for m in res_df['Model']], rotation=15)
    plt.ylim(0.8, 1.05)
    plt.ylabel('Score')
    plt.title('Ensemble Learning Performance: Bagging vs. Boosting on Traffic Features')
    plt.legend(loc='lower right')
    plt.tight_layout()
    chart_path = os.path.join(results_dir, 'ensemble_comparison.png')
    plt.savefig(chart_path, dpi=200)
    plt.close()

    print(f'\n[Artifacts] Saved comparison metrics to: {summary_path}')
    print(f'[Artifacts] Saved comparison chart to:   {chart_path}')
    print('==================================================\n')

if __name__ == '__main__':
    train_and_evaluate_classifiers()
