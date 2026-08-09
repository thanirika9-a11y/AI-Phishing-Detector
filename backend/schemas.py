from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List, Dict, Any

# User Schemas
class UserCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=4)

class UserLogin(BaseModel):
    username: str
    password: str

class AuthResponse(BaseModel):
    username: str
    userId: int
    token: str

# Scan Schemas
class ScanCreate(BaseModel):
    input_type: str = Field(..., description="Type of input: 'url' or 'text'")
    input_content: str = Field(..., description="The URL or text message to analyze")
    user_id: Optional[int] = Field(None, description="Optional ID of logged-in user")

class ScanResponse(BaseModel):
    id: int
    input_type: str
    input_content: str
    risk_score: int
    risk_level: str
    details_json: str
    user_id: Optional[int]
    timestamp: datetime

    class Config:
        from_attributes = True

# Report Schemas
class ReportCreate(BaseModel):
    scam_type: str = Field(..., description="Type of scam: 'phishing', 'smishing', 'vishing', 'other'")
    indicator: str = Field(..., description="The suspicious URL, email address, phone number, etc.")
    description: Optional[str] = Field(None, description="Additional context or description")

class ReportResponse(BaseModel):
    id: int
    scam_type: str
    indicator: str
    description: Optional[str]
    reporter_ip: str
    timestamp: datetime

    class Config:
        from_attributes = True

# Quiz Score Schemas
class QuizScoreCreate(BaseModel):
    username: str = Field(..., description="Name of the user")
    score: int = Field(..., description="Number of correct answers")
    total: int = Field(..., description="Total questions in quiz")

class QuizScoreResponse(BaseModel):
    id: int
    username: str
    score: int
    total: int
    timestamp: datetime

    class Config:
        from_attributes = True

# Analytics Schema
class SeverityBreakdown(BaseModel):
    safe: int
    suspicious: int
    dangerous: int

class AnalyticsResponse(BaseModel):
    total_scans: int
    total_reports: int
    scans_breakdown: SeverityBreakdown
    reports_by_type: Dict[str, int]
    recent_scans: List[ScanResponse]
    recent_reports: List[ReportResponse]
