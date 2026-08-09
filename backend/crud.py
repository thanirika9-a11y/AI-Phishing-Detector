from sqlalchemy.orm import Session
from sqlalchemy import func
import models
import json

# User Operations
def create_user(db: Session, username: str, password_hash: str):
    db_user = models.User(username=username, hashed_password=password_hash)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def get_user_by_username(db: Session, username: str):
    return db.query(models.User).filter(models.User.username == username).first()

# Scan Operations
def create_scan(db: Session, input_type: str, input_content: str, risk_score: int, risk_level: str, details_json: str, user_id: int = None):
    db_scan = models.ScanHistory(
        input_type=input_type,
        input_content=input_content,
        risk_score=risk_score,
        risk_level=risk_level,
        details_json=details_json,
        user_id=user_id
    )
    db.add(db_scan)
    db.commit()
    db.refresh(db_scan)
    return db_scan

def get_scans(db: Session, limit: int = 50):
    return db.query(models.ScanHistory).order_by(models.ScanHistory.timestamp.desc()).limit(limit).all()

def get_scan_count(db: Session) -> int:
    return db.query(func.count(models.ScanHistory.id)).scalar() or 0

def get_scans_breakdown(db: Session):
    results = db.query(
        models.ScanHistory.risk_level, 
        func.count(models.ScanHistory.id)
    ).group_by(models.ScanHistory.risk_level).all()
    
    breakdown = {"safe": 0, "suspicious": 0, "dangerous": 0}
    for risk_level, count in results:
        level_key = risk_level.lower()
        if level_key in breakdown:
            breakdown[level_key] = count
            
    return breakdown

# Report Operations
def create_report(db: Session, scam_type: str, indicator: str, description: str, reporter_ip: str):
    db_report = models.ReportedScam(
        scam_type=scam_type,
        indicator=indicator,
        description=description,
        reporter_ip=reporter_ip
    )
    db.add(db_report)
    db.commit()
    db.refresh(db_report)
    return db_report

def get_reports(db: Session, limit: int = 50):
    return db.query(models.ReportedScam).order_by(models.ReportedScam.timestamp.desc()).limit(limit).all()

def get_report_count(db: Session) -> int:
    return db.query(func.count(models.ReportedScam.id)).scalar() or 0

def get_reports_by_type(db: Session):
    results = db.query(
        models.ReportedScam.scam_type, 
        func.count(models.ReportedScam.id)
    ).group_by(models.ReportedScam.scam_type).all()
    
    breakdown = {"phishing": 0, "smishing": 0, "vishing": 0, "other": 0}
    for scam_type, count in results:
        type_key = scam_type.lower()
        if type_key in breakdown:
            breakdown[type_key] = count
        else:
            breakdown["other"] = breakdown.get("other", 0) + count
            
    return breakdown

# Quiz Operations
def create_quiz_score(db: Session, username: str, score: int, total: int):
    db_score = models.UserQuizScore(
        username=username,
        score=score,
        total=total
    )
    db.add(db_score)
    db.commit()
    db.refresh(db_score)
    return db_score

def get_quiz_scores(db: Session, limit: int = 10):
    return db.query(models.UserQuizScore).order_by(models.UserQuizScore.timestamp.desc()).limit(limit).all()
