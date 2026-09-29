"""
train_and_save_model.py
━━━━━━━━━━━━━━━━━━━━━━
Standalone ML training pipeline for the AI Phishing Detector project.

This script:
  1. Loads the phishing URL dataset from datasets/phishing_urls_dataset.csv
  2. Extracts 19 numeric features from each URL
  3. Trains 3 ML models: Random Forest, Logistic Regression, Decision Tree
  4. Evaluates each model (Accuracy, Precision, Recall, F1-Score, AUC)
  5. Picks the best model and saves it as trained_model_url.pkl
  6. The saved model is automatically used by the real-time scanner (/api/scan)

Usage:
    python train_and_save_model.py
"""

import os
import sys
import pickle
import numpy as np
import pandas as pd

from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.tree import DecisionTreeClassifier
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    confusion_matrix, classification_report, roc_auc_score
)

# Import our custom feature extractor
from eda_generator import extract_features_from_url, load_and_preprocess

DATASET_PATH = os.path.join(os.path.dirname(__file__), "datasets", "phishing_urls_dataset.csv")
MODEL_OUTPUT_PATH = os.path.join(os.path.dirname(__file__), "trained_model_url.pkl")


def print_banner():
    print("=" * 65)
    print("  AI PHISHING DETECTOR — ML MODEL TRAINING PIPELINE")
    print("=" * 65)
    print()


def load_dataset():
    """Load and preprocess the phishing URL dataset."""
    print("[1/5] Loading Dataset...")
    print(f"      Path: {DATASET_PATH}")

    if not os.path.exists(DATASET_PATH):
        print("      ❌ Dataset not found! Run generate_dataset.py first.")
        sys.exit(1)

    with open(DATASET_PATH, "rb") as f:
        file_bytes = f.read()

    feature_df, labels, raw_df, info = load_and_preprocess(file_bytes, filename="phishing_urls_dataset.csv")

    print(f"      ✅ Loaded {info['total_rows']} rows")
    print(f"      ✅ Extracted {info['feature_count']} features per URL")
    print(f"      ✅ Phishing: {info['phishing_count']} | Legitimate: {info['legit_count']}")
    print(f"      ✅ Class balance: {info['class_balance']}% phishing")
    print()

    return feature_df, labels, info


def train_and_evaluate(feature_df, labels):
    """Train all 3 models and print evaluation results."""
    print("[2/5] Splitting Dataset (80% Train / 20% Test)...")
    X = feature_df.fillna(0).values
    y = labels

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    print(f"      Training samples: {len(X_train)}")
    print(f"      Testing samples:  {len(X_test)}")
    print()

    # Scale features for Logistic Regression
    scaler = StandardScaler()
    X_train_sc = scaler.fit_transform(X_train)
    X_test_sc = scaler.transform(X_test)

    feature_names = list(feature_df.columns)

    models = {
        "Random Forest": {
            "clf": RandomForestClassifier(n_estimators=100, random_state=42, n_jobs=-1),
            "scaled": False,
        },
        "Logistic Regression": {
            "clf": LogisticRegression(max_iter=500, random_state=42),
            "scaled": True,
        },
        "Decision Tree": {
            "clf": DecisionTreeClassifier(max_depth=10, random_state=42),
            "scaled": False,
        },
    }

    results = {}

    print("[3/5] Training Models...")
    print()

    for name, config in models.items():
        clf = config["clf"]
        use_scaled = config["scaled"]

        Xtr = X_train_sc if use_scaled else X_train
        Xte = X_test_sc if use_scaled else X_test

        # Train
        clf.fit(Xtr, y_train)

        # Predict
        y_pred = clf.predict(Xte)

        # Metrics
        acc = accuracy_score(y_test, y_pred)
        prec = precision_score(y_test, y_pred, zero_division=0)
        rec = recall_score(y_test, y_pred, zero_division=0)
        f1 = f1_score(y_test, y_pred, zero_division=0)

        # AUC
        auc_score = 0.0
        try:
            if hasattr(clf, "predict_proba"):
                y_proba = clf.predict_proba(Xte)[:, 1]
            else:
                y_proba = clf.decision_function(Xte)
            auc_score = roc_auc_score(y_test, y_proba)
        except Exception:
            pass

        # Cross-validation
        cv_scores = cross_val_score(clf, Xtr, y_train, cv=5, scoring="accuracy")

        # Confusion Matrix
        cm = confusion_matrix(y_test, y_pred)

        results[name] = {
            "clf": clf,
            "accuracy": round(acc * 100, 2),
            "precision": round(prec * 100, 2),
            "recall": round(rec * 100, 2),
            "f1_score": round(f1 * 100, 2),
            "auc": round(auc_score, 4),
            "cv_mean": round(cv_scores.mean() * 100, 2),
            "cv_std": round(cv_scores.std() * 100, 2),
            "confusion_matrix": cm,
            "scaled": use_scaled,
        }

        print(f"  ┌─ {name}")
        print(f"  │  Accuracy:   {results[name]['accuracy']}%")
        print(f"  │  Precision:  {results[name]['precision']}%")
        print(f"  │  Recall:     {results[name]['recall']}%")
        print(f"  │  F1-Score:   {results[name]['f1_score']}%")
        print(f"  │  AUC:        {results[name]['auc']}")
        print(f"  │  CV (5-fold): {results[name]['cv_mean']}% ± {results[name]['cv_std']}%")
        print(f"  │  Confusion Matrix:")
        print(f"  │    TN={cm[0][0]}  FP={cm[0][1]}")
        print(f"  │    FN={cm[1][0]}  TP={cm[1][1]}")
        print(f"  └{'─' * 40}")
        print()

    return results, scaler, feature_names


def select_and_save_best(results, scaler, feature_names, feature_df, labels):
    """Select the best model by F1-score and save it as a pickle file."""
    print("[4/5] Selecting Best Model...")

    best_name = max(results, key=lambda k: results[k]["f1_score"])
    best = results[best_name]

    print(f"      🏆 Best Model: {best_name}")
    print(f"      🏆 F1-Score:   {best['f1_score']}%")
    print(f"      🏆 Accuracy:   {best['accuracy']}%")
    print()

    # Refit the best model on the FULL dataset for production use
    print("[5/5] Refitting on Full Dataset & Saving...")

    X_full = feature_df.fillna(0).values
    y_full = labels

    best_scaler = None
    if best["scaled"]:
        best_scaler = StandardScaler()
        X_full = best_scaler.fit_transform(X_full)

    # Create a fresh instance of the best model
    if best_name == "Random Forest":
        production_clf = RandomForestClassifier(n_estimators=100, random_state=42, n_jobs=-1)
    elif best_name == "Logistic Regression":
        production_clf = LogisticRegression(max_iter=500, random_state=42)
    else:
        production_clf = DecisionTreeClassifier(max_depth=10, random_state=42)

    production_clf.fit(X_full, y_full)

    model_data = {
        "model": production_clf,
        "scaler": best_scaler,
        "feature_names": feature_names,
        "model_name": best_name,
        "accuracy": best["accuracy"],
        "f1_score": best["f1_score"],
        "precision": best["precision"],
        "recall": best["recall"],
    }

    with open(MODEL_OUTPUT_PATH, "wb") as f:
        pickle.dump(model_data, f)

    file_size = os.path.getsize(MODEL_OUTPUT_PATH)
    print(f"      ✅ Model saved to: {MODEL_OUTPUT_PATH}")
    print(f"      ✅ File size: {file_size / 1024:.1f} KB")
    print()

    return best_name, best


def print_summary(best_name, best):
    print("=" * 65)
    print("  TRAINING COMPLETE — SUMMARY")
    print("=" * 65)
    print(f"  Best Model:    {best_name}")
    print(f"  Accuracy:      {best['accuracy']}%")
    print(f"  Precision:     {best['precision']}%")
    print(f"  Recall:        {best['recall']}%")
    print(f"  F1-Score:      {best['f1_score']}%")
    print(f"  AUC:           {best['auc']}")
    print()
    print("  The trained model is now integrated into the real-time scanner.")
    print("  When you scan a URL via /api/scan, the custom model is used")
    print("  automatically for predictions.")
    print("=" * 65)


if __name__ == "__main__":
    print_banner()
    feature_df, labels, info = load_dataset()
    results, scaler, feature_names = train_and_evaluate(feature_df, labels)
    best_name, best = select_and_save_best(results, scaler, feature_names, feature_df, labels)
    print_summary(best_name, best)
