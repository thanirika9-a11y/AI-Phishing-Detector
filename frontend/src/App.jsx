import React, { useState, useEffect } from 'react';
import LandingPage from './components/LandingPage';
import AuthPage from './components/AuthPage';
import Dashboard from './components/Dashboard';
import Scanner from './components/Scanner';
import Reporter from './components/Reporter';
import Training from './components/Training';
import MLDashboard from './components/MLDashboard';

// Fallback simulated analytics metrics
const DEFAULT_MOCK_ANALYTICS = {
  total_scans: 1248,
  total_reports: 347,
  scans_breakdown: { safe: 856, suspicious: 247, dangerous: 145 },
  reports_by_type: { phishing: 186, smishing: 92, vishing: 41, other: 28 },
  recent_scans: [
    { 
      id: 1, input_type: "url", 
      input_content: "http://secure-login-netflix.club/billing", 
      risk_score: 85, risk_level: "DANGEROUS", 
      details_json: JSON.stringify({ 
        reasons: ["Uses suspicious TLD (.club)", "Contains brand keyword (netflix)", "Not using HTTPS"],
        geo_ip: { ip: "185.220.101.42", country: "Russia (RU)", isp: "Mevspace Servers SAS", domain_age: "5 days ago" },
        weights: { lexical_features: "40%", heuristic_scoring: "40%", protocol_security: "20%" }
      }),
      user_id: null,
      timestamp: new Date(Date.now() - 1000 * 60 * 15).toISOString() 
    },
    { 
      id: 2, input_type: "text", 
      input_content: "URGENT: Chase Bank detected a login breach. Confirm details within 24 hours to reactivate.", 
      risk_score: 70, risk_level: "DANGEROUS", 
      details_json: JSON.stringify({ 
        reasons: ["Panic urgency phrases matched", "Urgent request for account credentials"],
        weights: { urgency_lexicon: "50%", financial_hooks: "0%", credential_harvesting: "50%" }
      }),
      user_id: null,
      timestamp: new Date(Date.now() - 1000 * 60 * 45).toISOString() 
    },
    { 
      id: 3, input_type: "url", 
      input_content: "https://myaccount.google.com/security", 
      risk_score: 0, risk_level: "SAFE", 
      details_json: JSON.stringify({ 
        reasons: ["The domain belongs to a highly trusted public whitelist."],
        geo_ip: { ip: "142.250.195.46", country: "United States (US)", isp: "Google LLC", domain_age: "26 years" },
        weights: { lexical_features: "0%", heuristic_scoring: "0%", dns_reputation: "100%" }
      }),
      user_id: null,
      timestamp: new Date(Date.now() - 1000 * 60 * 120).toISOString() 
    }
  ],
  recent_reports: [
    { id: 1, scam_type: 'phishing', indicator: 'login-verify-chase-bank.xyz', description: 'Fake credit card login link sent via email.', timestamp: new Date(Date.now() - 1000 * 60 * 180).toISOString() },
    { id: 2, scam_type: 'smishing', indicator: '+1 (833) 244-9981', description: 'USPS package scam SMS.', timestamp: new Date(Date.now() - 1000 * 60 * 360).toISOString() }
  ]
};

export default function App() {
  const [currentPage, setCurrentPage] = useState('landing');
  const [activeTab, setActiveTab] = useState('dashboard');
  const [user, setUser] = useState(null);
  const [analytics, setAnalytics] = useState(DEFAULT_MOCK_ANALYTICS);
  const [loading, setLoading] = useState(true);
  const [usingMockData, setUsingMockData] = useState(false);
  const [currentTime, setCurrentTime] = useState(new Date());

  // Live clock
  useEffect(() => {
    const timer = setInterval(() => setCurrentTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  const fetchAnalytics = async () => {
    setLoading(true);
    try {
      const response = await fetch('http://localhost:8000/api/analytics');
      if (response.ok) {
        const data = await response.json();
        setAnalytics(data);
        setUsingMockData(false);
      } else { throw new Error("Failed"); }
    } catch (err) {
      setAnalytics(DEFAULT_MOCK_ANALYTICS);
      setUsingMockData(true);
    } finally { setLoading(false); }
  };

  useEffect(() => { fetchAnalytics(); }, []);

  const handleAuthSuccess = (userData) => {
    setUser(userData);
    setCurrentPage('console');
    fetchAnalytics();
  };

  const handleLogout = () => {
    setUser(null);
    setCurrentPage('landing');
    setActiveTab('dashboard');
  };

  const triggerExport = () => {
    if (!usingMockData) {
      window.open('http://localhost:8000/api/export', '_blank');
    }
  };

  const renderConsoleTab = () => {
    switch (activeTab) {
      case 'dashboard': return <Dashboard analytics={analytics} loading={loading} />;
      case 'scanner': return <Scanner onScanComplete={fetchAnalytics} />;
      case 'mllab': return <Dashboard analytics={analytics} loading={loading} />; // Placeholder
      case 'reports': return <Reporter reports={analytics ? analytics.recent_reports : []} onReportSubmitted={fetchAnalytics} />;
      case 'academy': return <Training />;
      default: return <Dashboard analytics={analytics} loading={loading} />;
    }
  };

  if (currentPage === 'landing') {
    return <LandingPage onLaunch={() => setCurrentPage('auth')} />;
  }
  if (currentPage === 'auth') {
    return <AuthPage onAuthSuccess={handleAuthSuccess} />;
  }

  const NAV_ITEMS = [
    { key: 'dashboard', icon: '📊', label: 'Dashboard', desc: 'Overview & Analytics' },
    { key: 'scanner', icon: '⚡', label: 'Scanner', desc: 'Threat Analysis' },
    { key: 'mllab', icon: '🤖', label: 'ML Lab', desc: 'Custom Models' },
    { key: 'reports', icon: '🚨', label: 'Reporter', desc: 'Community Intel' },
    { key: 'academy', icon: '🎓', label: 'Academy', desc: 'Training Labs' },
  ];

  const PAGE_TITLES = {
    dashboard: { title: 'Threat Intelligence Dashboard', sub: 'Real-time security analytics, scan metrics, and community threat activity logs.' },
    scanner: { title: 'Threat Scanner Lab', sub: 'Upload CSV datasets across various categories for ML analysis and graph generation.' },
    mllab: { title: 'Machine Learning Lab', sub: 'Advanced model configuration and historical training runs.' },
    reports: { title: 'Community Threat Reports', sub: 'Crowdsourced threat intelligence — report and track active phishing campaigns.' },
    academy: { title: 'Academy', sub: 'Interactive simulation exercises to sharpen your threat recognition skills.' },
  };

  return (
    <div className="app-container">
      {/* Floating Background Orbs */}
      <div className="orb orb-1" />
      <div className="orb orb-2" />
      <div className="orb orb-3" />

      {/* Premium Sidebar */}
      <aside className="sidebar">
        <div>
          {/* Brand Logo */}
          <div className="logo-section">
            <div className="logo-icon">🛡️</div>
            <div>
              <div className="logo-text">Aegis AI</div>
              <div style={{ fontSize: '10px', color: 'var(--text-muted)', letterSpacing: '1.5px', textTransform: 'uppercase', marginTop: '2px' }}>Phishing Detector</div>
            </div>
          </div>

          {/* Navigation */}
          <ul className="nav-links">
            {NAV_ITEMS.map((item) => (
              <li key={item.key}
                className={`nav-item ${activeTab === item.key ? 'active' : ''}`}
                onClick={() => setActiveTab(item.key)}
              >
                <span className="nav-icon">{item.icon}</span>
                <div>
                  <div style={{ fontWeight: '600', fontSize: '14px' }}>{item.label}</div>
                  <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '1px' }}>{item.desc}</div>
                </div>
              </li>
            ))}
          </ul>
        </div>

        {/* Sidebar Footer */}
        <div className="sidebar-footer">
          {user && (
            <div style={{
              display: 'flex', alignItems: 'center', gap: '10px',
              padding: '12px', borderRadius: '12px',
              background: 'rgba(139,92,246,0.1)', border: '1px solid rgba(139,92,246,0.25)',
              marginBottom: '12px'
            }}>
              <div style={{
                width: '34px', height: '34px', borderRadius: '10px',
                background: 'linear-gradient(135deg,#8b5cf6,#6366f1)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontWeight: '800', fontSize: '15px', color: '#fff',
                flexShrink: 0
              }}>
                {user.username.charAt(0).toUpperCase()}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: '13px', fontWeight: '700', color: 'var(--text-main)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{user.username}</div>
                <div style={{ fontSize: '11px', color: 'var(--color-safe)', display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <span style={{ width: '6px', height: '6px', borderRadius: '50%', background: 'var(--color-safe)', display: 'inline-block', boxShadow: '0 0 6px var(--color-safe)' }} />
                  Active Session
                </div>
              </div>
              <button
                onClick={handleLogout}
                style={{
                  background: 'rgba(248,113,113,0.12)', border: '1px solid rgba(248,113,113,0.3)',
                  borderRadius: '8px', color: 'var(--color-dangerous)', cursor: 'pointer',
                  padding: '6px 8px', fontSize: '12px', fontWeight: '700', transition: 'all 0.2s'
                }}
                title="Sign Out"
              >
                ↗
              </button>
            </div>
          )}

          {usingMockData && (
            <div style={{
              padding: '8px 12px', borderRadius: '10px',
              background: 'rgba(251,191,36,0.08)', border: '1px solid rgba(251,191,36,0.2)',
              color: 'var(--color-suspicious)', fontSize: '12px', marginBottom: '12px',
              display: 'flex', alignItems: 'center', gap: '6px'
            }}>
              ⚠️ Demo Mode — Start backend for live data
            </div>
          )}

          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>v2.0 • Aegis Console</span>
            <span style={{ fontSize: '11px', fontFamily: 'var(--font-mono)', color: '#8b5cf6' }}>
              {currentTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
            </span>
          </div>
        </div>
      </aside>

      {/* Main Content */}
      <main className="main-content" style={{ position: 'relative', zIndex: 1 }}>
        <header className="content-header">
          <div>
            <div style={{
              fontSize: '11px', fontWeight: '700', textTransform: 'uppercase',
              letterSpacing: '2px', color: '#8b5cf6', marginBottom: '4px'
            }}>
              Aegis Console
            </div>
            <h1>{PAGE_TITLES[activeTab]?.title}</h1>
            <p style={{ fontSize: '13px', marginTop: '5px', color: 'var(--text-muted)' }}>
              {PAGE_TITLES[activeTab]?.sub}
            </p>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <button
              onClick={triggerExport}
              disabled={usingMockData}
              style={{
                background: 'rgba(139,92,246,0.1)', border: '1px solid rgba(139,92,246,0.3)',
                borderRadius: '10px', color: usingMockData ? 'var(--text-muted)' : '#c4b5fd',
                cursor: usingMockData ? 'not-allowed' : 'pointer', padding: '9px 16px',
                fontSize: '13px', fontWeight: '600', fontFamily: 'var(--font-sans)',
                transition: 'all 0.2s', display: 'flex', alignItems: 'center', gap: '6px'
              }}
              title="Download threat database as JSON"
            >
              📥 Export
            </button>
            <button
              onClick={fetchAnalytics}
              style={{
                background: 'rgba(139,92,246,0.1)', border: '1px solid rgba(139,92,246,0.3)',
                borderRadius: '10px', color: '#c4b5fd', cursor: 'pointer', padding: '9px 16px',
                fontSize: '13px', fontWeight: '600', fontFamily: 'var(--font-sans)',
                transition: 'all 0.2s', display: 'flex', alignItems: 'center', gap: '6px'
              }}
            >
              🔄 Refresh
            </button>
            <div style={{
              display: 'flex', alignItems: 'center', gap: '7px', padding: '9px 14px',
              borderRadius: '10px',
              background: usingMockData ? 'rgba(251,191,36,0.08)' : 'rgba(52,211,153,0.08)',
              border: `1px solid ${usingMockData ? 'rgba(251,191,36,0.3)' : 'rgba(52,211,153,0.3)'}`,
              fontSize: '12px', fontWeight: '700',
              color: usingMockData ? 'var(--color-suspicious)' : 'var(--color-safe)'
            }}>
              <span style={{
                width: '7px', height: '7px', borderRadius: '50%',
                background: usingMockData ? 'var(--color-suspicious)' : 'var(--color-safe)',
                boxShadow: `0 0 8px ${usingMockData ? 'var(--color-suspicious)' : 'var(--color-safe)'}`,
                animation: 'pulse-dot 2s ease-in-out infinite'
              }} />
              {usingMockData ? 'Demo Mode' : 'System Online'}
            </div>
          </div>
        </header>

        {renderConsoleTab()}
      </main>
    </div>
  );
}
