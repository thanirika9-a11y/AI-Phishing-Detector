import datetime
from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(100), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class ScanHistory(Base):
    __tablename__ = "scan_history"

    id = Column(Integer, primary_key=True, index=True)
    input_type = Column(String(50), nullable=False)  # "url" or "text"
    input_content = Column(Text, nullable=False)
    risk_score = Column(Integer, nullable=False)     # 0 to 100
    risk_level = Column(String(50), nullable=False)  # "SAFE", "SUSPICIOUS", "DANGEROUS"
    details_json = Column(Text, nullable=False)       # JSON string with metrics
    user_id = Column(Integer, nullable=True)         # Optional linked user ID
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)

class ReportedScam(Base):
    __tablename__ = "reported_scams"

    id = Column(Integer, primary_key=True, index=True)
    scam_type = Column(String(50), nullable=False)   # "phishing", "smishing", "vishing", "other"
    indicator = Column(String(255), nullable=False)  # url, email, phone, etc.
    description = Column(Text, nullable=True)
    reporter_ip = Column(String(50), default="127.0.0.1")
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)

class UserQuizScore(Base):
    __tablename__ = "user_quiz_scores"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(100), nullable=False)
    score = Column(Integer, nullable=False)
    total = Column(Integer, nullable=False)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
