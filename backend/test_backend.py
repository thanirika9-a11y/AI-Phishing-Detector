import unittest
import json
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database import Base
import models
import crud
from analyzer import PhishingAnalyzer

class TestPhishingDetector(unittest.TestCase):
    def setUp(self):
        # Set up an in-memory SQLite database for testing
        self.engine = create_engine("sqlite:///:memory:")
        Base.metadata.create_all(bind=self.engine)
        self.SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
        self.db = self.SessionLocal()

    def tearDown(self):
        self.db.close()
        Base.metadata.drop_all(bind=self.engine)

    def test_url_analyzer_safe(self):
        # Google should be categorized as SAFE and have 0 risk score
        res = PhishingAnalyzer.analyze_url("https://www.google.com")
        self.assertEqual(res["level"], "SAFE")
        self.assertEqual(res["score"], 0)
        self.assertTrue(res["checks"]["is_whitelisted"])

    def test_url_analyzer_phish(self):
        # A mock suspicious URL with http and bad TLD
        res = PhishingAnalyzer.analyze_url("http://secure-login-chase-update.xyz/login")
        self.assertEqual(res["level"], "DANGEROUS")
        self.assertGreater(res["score"], 50)
        self.assertTrue(res["checks"]["http_protocol"])
        self.assertTrue(res["checks"]["suspicious_tld"])
        self.assertTrue(res["checks"]["sensitive_keyword_in_domain"])

    def test_text_analyzer_scam(self):
        # High urgency scam text requesting credentials
        text = "URGENT ACTION REQUIRED: Chase Bank detected a breach. Reactivate account immediately. Enter OTP: 1241."
        res = PhishingAnalyzer.analyze_text(text)
        self.assertEqual(res["level"], "DANGEROUS")
        self.assertGreater(res["score"], 40)
        self.assertTrue(res["checks"]["urgency_detected"])
        self.assertTrue(res["checks"]["credential_request"])

    def test_crud_scan_creation(self):
        # Test creating a scan history record
        details = {"reasons": ["Test"]}
        db_scan = crud.create_scan(
            db=self.db,
            input_type="url",
            input_content="test-url.com",
            risk_score=40,
            risk_level="SUSPICIOUS",
            details_json=json.dumps(details)
        )
        self.assertIsNotNone(db_scan.id)
        self.assertEqual(db_scan.input_content, "test-url.com")
        
        # Test analytics
        breakdown = crud.get_scans_breakdown(self.db)
        self.assertEqual(breakdown["suspicious"], 1)
        self.assertEqual(breakdown["safe"], 0)

    def test_crud_report_creation(self):
        # Test creating reported scam indicator
        db_report = crud.create_report(
            db=self.db,
            scam_type="smishing",
            indicator="1-800-FAKE",
            description="Fake SMS parcel alert",
            reporter_ip="127.0.0.1"
        )
        self.assertIsNotNone(db_report.id)
        self.assertEqual(db_report.indicator, "1-800-FAKE")
        
        reports_by_type = crud.get_reports_by_type(self.db)
        self.assertEqual(reports_by_type["smishing"], 1)

if __name__ == "__main__":
    unittest.main()
