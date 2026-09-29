import numpy as np
import json
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.tree import DecisionTreeClassifier
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    confusion_matrix, roc_curve, auc
)
import warnings
warnings.filterwarnings("ignore")


def train_models(feature_df, labels: np.ndarray) -> dict:
    """
    Train Random Forest, Logistic Regression, and Decision Tree models.
    Returns full metrics including confusion matrix, ROC curve, and feature importance.
    """
    X = feature_df.fillna(0).values
    y = labels

    # Handle very small datasets gracefully
    test_size = 0.2 if len(X) >= 50 else 0.3
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=test_size, random_state=42, stratify=y
    )

    # Scale features for Logistic Regression
    scaler = StandardScaler()
    X_train_sc = scaler.fit_transform(X_train)
    X_test_sc  = scaler.transform(X_test)

    feature_names = list(feature_df.columns)

    # ── Define models ──
    models = {
        "Random Forest":     RandomForestClassifier(n_estimators=100, random_state=42, n_jobs=-1),
        "Logistic Regression": LogisticRegression(max_iter=500, random_state=42),
        "Decision Tree":     DecisionTreeClassifier(max_depth=10, random_state=42),
    }

    results = {}

    for model_name, clf in models.items():
        use_scaled = (model_name == "Logistic Regression")
        Xtr = X_train_sc if use_scaled else X_train
        Xte = X_test_sc  if use_scaled else X_test

        clf.fit(Xtr, y_train)
        y_pred = clf.predict(Xte)

        acc  = round(float(accuracy_score(y_test, y_pred))  * 100, 2)
        prec = round(float(precision_score(y_test, y_pred, zero_division=0)) * 100, 2)
        rec  = round(float(recall_score(y_test, y_pred, zero_division=0))    * 100, 2)
        f1   = round(float(f1_score(y_test, y_pred, zero_division=0))        * 100, 2)

        cm = confusion_matrix(y_test, y_pred).tolist()

        # ROC / AUC
        roc_data = None
        try:
            if hasattr(clf, "predict_proba"):
                y_proba = clf.predict_proba(Xte)[:, 1]
            else:
                y_proba = clf.decision_function(Xte)
            fpr, tpr, _ = roc_curve(y_test, y_proba)
            roc_auc = round(float(auc(fpr, tpr)), 4)
            # Downsample to ≤ 100 points so JSON stays small
            step = max(1, len(fpr) // 100)
            roc_data = {
                "fpr": [round(float(v), 4) for v in fpr[::step]],
                "tpr": [round(float(v), 4) for v in tpr[::step]],
                "auc": roc_auc,
            }
        except Exception:
            pass

        # Feature importance (only for tree-based models)
        feat_importance = []
        if hasattr(clf, "feature_importances_"):
            importances = clf.feature_importances_
            sorted_idx = np.argsort(importances)[::-1][:15]
            feat_importance = [
                {"feature": feature_names[i], "importance": round(float(importances[i]), 4)}
                for i in sorted_idx
            ]
        elif hasattr(clf, "coef_"):
            coefs = np.abs(clf.coef_[0])
            sorted_idx = np.argsort(coefs)[::-1][:15]
            feat_importance = [
                {"feature": feature_names[i], "importance": round(float(coefs[i]), 4)}
                for i in sorted_idx
            ]

        results[model_name] = {
            "accuracy":          acc,
            "precision":         prec,
            "recall":            rec,
            "f1_score":          f1,
            "confusion_matrix":  cm,
            "roc_curve":         roc_data,
            "feature_importance": feat_importance,
            "train_samples":     int(len(X_train)),
            "test_samples":      int(len(X_test)),
        }

    # Identify best model by F1 score
    best_model_name = max(results, key=lambda k: results[k]["f1_score"])

    return {
        "models":         results,
        "best_model":     best_model_name,
        "total_samples":  int(len(X)),
        "feature_names":  feature_names,
    }
