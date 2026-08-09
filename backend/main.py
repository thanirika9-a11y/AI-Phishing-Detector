from fastapi import FastAPI, Depends, HTTPException, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List
import json
import secrets

import models
import schemas
import crud
from database import engine, get_db
from analyzer import PhishingAnalyzer
from auth import hash_password, verify_password

# Initialize Database tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="AI Phishing & Scam Detection API",
    description="Backend API running lexical heuristic detection algorithms and security analytical logs",
    version="1.0.0"
)

# CORS configurations for frontend communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Vite dev server
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Auth Endpoints
@app.post("/api/auth/signup", response_model=schemas.AuthResponse)
def signup(payload: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = crud.get_user_by_username(db, username=payload.username)
    if db_user:
        raise HTTPException(status_code=400, detail="Username is already registered.")
    
    hashed = hash_password(payload.password)
    new_user = crud.create_user(db=db, username=payload.username, password_hash=hashed)
    
    mock_token = f"aegis_token_{secrets.token_hex(16)}"
    return {
        "username": new_user.username,
        "userId": new_user.id,
        "token": mock_token
    }

@app.post("/api/auth/login", response_model=schemas.AuthResponse)
def login(payload: schemas.UserLogin, db: Session = Depends(get_db)):
    db_user = crud.get_user_by_username(db, username=payload.username)
    if not db_user:
        raise HTTPException(status_code=400, detail="Invalid username or password.")
    
    if not verify_password(payload.password, db_user.hashed_password):
        raise HTTPException(status_code=400, detail="Invalid username or password.")
        
    mock_token = f"aegis_token_{secrets.token_hex(16)}"
    return {
        "username": db_user.username,
        "userId": db_user.id,
        "token": mock_token
    }

# Scanner Endpoints
@app.post("/api/scan", response_model=schemas.ScanResponse)
def scan_endpoint(payload: schemas.ScanCreate, db: Session = Depends(get_db)):
    if payload.input_type not in ["url", "text"]:
        raise HTTPException(status_code=400, detail="Invalid input_type. Must be 'url' or 'text'.")
    
    # Process scan
    if payload.input_type == "url":
        analysis_result = PhishingAnalyzer.analyze_url(payload.input_content)
    else:
        analysis_result = PhishingAnalyzer.analyze_text(payload.input_content)
        
    details_str = json.dumps(analysis_result)
    
    # Write to database
    db_scan = crud.create_scan(
        db=db,
        input_type=payload.input_type,
        input_content=payload.input_content,
        risk_score=analysis_result["score"],
        risk_level=analysis_result["level"],
        details_json=details_str,
        user_id=payload.user_id
    )
    return db_scan

@app.post("/api/reports", response_model=schemas.ReportResponse)
def report_scam(payload: schemas.ReportCreate, request: Request, db: Session = Depends(get_db)):
    client_ip = request.client.host if request.client else "127.0.0.1"
    db_report = crud.create_report(
        db=db,
        scam_type=payload.scam_type,
        indicator=payload.indicator,
        description=payload.description or "",
        reporter_ip=client_ip
    )
    return db_report

@app.get("/api/reports", response_model=List[schemas.ReportResponse])
def read_reports(limit: int = 50, db: Session = Depends(get_db)):
    return crud.get_reports(db=db, limit=limit)

@app.get("/api/analytics", response_model=schemas.AnalyticsResponse)
def get_analytics(db: Session = Depends(get_db)):
    total_scans = crud.get_scan_count(db)
    total_reports = crud.get_report_count(db)
    scans_breakdown = crud.get_scans_breakdown(db)
    reports_by_type = crud.get_reports_by_type(db)
    
    recent_scans = crud.get_scans(db, limit=10)
    recent_reports = crud.get_reports(db, limit=10)
    
    return {
        "total_scans": total_scans,
        "total_reports": total_reports,
        "scans_breakdown": scans_breakdown,
        "reports_by_type": reports_by_type,
        "recent_scans": recent_scans,
        "recent_reports": recent_reports
    }

# Developer Sandbox Endpoints
@app.post("/api/developer/keys")
def generate_dev_key(payload: dict):
    username = payload.get("username", "developer")
    mock_key = f"aegis_live_key_{secrets.token_hex(20)}"
    return {
        "username": username,
        "apiKey": mock_key,
        "status": "active",
        "limits": "1000 requests/day"
    }

# Database Export Endpoint
@app.get("/api/export")
def export_database_logs(db: Session = Depends(get_db)):
    scans = db.query(models.ScanHistory).all()
    reports = db.query(models.ReportedScam).all()
    
    exported_data = {
        "export_metadata": {
            "project": "AI Phishing & Scam Detection Hub",
            "generator": "Aegis AI Analytics Engine",
            "records_count": len(scans) + len(reports)
        },
        "scans": [
            {
                "id": s.id,
                "type": s.input_type,
                "content": s.input_content,
                "risk_score": s.risk_score,
                "risk_level": s.risk_level,
                "timestamp": s.timestamp.isoformat()
            } for s in scans
        ],
        "reports": [
            {
                "id": r.id,
                "type": r.scam_type,
                "indicator": r.indicator,
                "description": r.description,
                "timestamp": r.timestamp.isoformat()
            } for r in reports
        ]
    }
    
    return Response(
        content=json.dumps(exported_data, indent=2),
        media_type="application/json",
        headers={"Content-Disposition": "attachment; filename=aegis_threat_logs.json"}
    )

# Mock Quiz Database
QUIZ_QUESTIONS = [
    {
        "id": 1,
        "title": "Chase Bank Account Suspension Alert",
        "sender": "Chase Alerts <alerts@secure-verify-chase.net>",
        "content": "Dear Customer, We detected unauthorized attempts to access your Chase Bank account. To avoid permanent suspension, please verify your details here: http://secure-verify-chase.net/login. Please act within 24 hours.",
        "type": "phish",
        "category": "Email",
        "explanation": "This is a Phishing scam. The sender email and login link use 'secure-verify-chase.net' instead of the official 'chase.com' domain. It also uses generic greetings ('Dear Customer') and artificial urgency ('within 24 hours')."
    },
    {
        "id": 2,
        "title": "Google Security Login Warning",
        "sender": "Google Security <no-reply@accounts.google.com>",
        "content": "Google: Someone just tried to log in to your account from Chrome on Linux (IP 198.51.100.42). If this was you, you can ignore this alert. If not, secure your account at https://myaccount.google.com/security-checkup.",
        "type": "legit",
        "category": "Email",
        "explanation": "This is a legitimate security alert. The sender email belongs to 'accounts.google.com' and the verification URL points directly to the HTTPS secure Google domain 'myaccount.google.com'."
    },
    {
        "id": 3,
        "title": "USPS Package Delivery Incomplete Address SMS",
        "sender": "+1 (833) 244-9981",
        "content": "USPS Alert: Your package could not be delivered due to an incomplete address. Update your delivery details immediately at https://usps-parcel-tracking.xyz/shipment to avoid returning to sender.",
        "type": "phish",
        "category": "SMS",
        "explanation": "This is a Smishing (SMS Phishing) scam. The link domain uses a cheap TLD '.xyz' ('usps-parcel-tracking.xyz') rather than 'usps.com'. Scammers often target users expecting package deliveries."
    },
    {
        "id": 4,
        "title": "Netflix Payment Failure Notification",
        "sender": "Netflix <info@netflix.com>",
        "content": "Netflix: Your payment failed. Please update your billing details at https://netflix.com/youraccount to resume streaming. Contact support if you need help.",
        "type": "legit",
        "category": "Email",
        "explanation": "This is legitimate. The notification originates from 'netflix.com' and directs the user to log in safely via 'netflix.com/youraccount' (standard official domain) rather than a third-party clone site."
    },
    {
        "id": 5,
        "title": "Global Promo giveaway cash award claims",
        "sender": "Giveaway Center <promotions@reward-claims.net>",
        "content": "Congratulations! Your mobile number has won $5,000,000 in our global promo giveaway. To claim your cash prize, email your full name, phone number, and bank routing details to promotions@reward-claims.net.",
        "type": "phish",
        "category": "Email",
        "explanation": "This is a lottery Phishing scam. It requests bank routing numbers and private data via email, promises an unrealistic award, and uses 'reward-claims.net' which is a typical throwaway domain."
    }
]

@app.get("/api/quizzes")
def get_quizzes():
    return QUIZ_QUESTIONS

@app.post("/api/quizzes/submit", response_model=schemas.QuizScoreResponse)
def submit_quiz(payload: schemas.QuizScoreCreate, db: Session = Depends(get_db)):
    db_score = crud.create_quiz_score(
        db=db,
        username=payload.username,
        score=payload.score,
        total=payload.total
    )
    return db_score

@app.get("/api/quizzes/leaderboard", response_model=List[schemas.QuizScoreResponse])
def get_leaderboard(limit: int = 10, db: Session = Depends(get_db)):
    return crud.get_quiz_scores(db=db, limit=limit)
