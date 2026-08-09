import React from 'react';

export default function LandingPage({ onLaunch }) {
  const STATS = [
    { value: '98.2%', label: 'Detection Accuracy', color: '#00f2fe' },
    { value: '<5ms', label: 'Analysis Speed', color: '#b34eff' },
    { value: '42K+', label: 'Threats Analyzed', color: '#10b981' },
    { value: '24/7', label: 'Real-time Protection', color: '#f59e0b' },
  ];

  const FEATURES = [
    { icon: '🌐', title: 'URL Threat Analysis', desc: 'Instantly detect phishing domains, typosquatting attacks, and malicious redirects with multi-layer URL inspection.', tag: 'CORE' },
    { icon: '✉️', title: 'Email & SMS Scanner', desc: 'AI-powered natural language analysis identifies urgency manipulation, credential harvesting, and social engineering attacks.', tag: 'AI' },
    { icon: '🚨', title: 'Community Reports', desc: 'Crowdsourced threat intelligence platform — report scams to protect others and access real-time threat feeds.', tag: 'SOCIAL' },
    { icon: '🧠', title: 'Training Simulator', desc: 'Interactive phishing awareness exercises with realistic email simulations to sharpen your detection instincts.', tag: 'LEARN' },
  ];

  return (
    <div className="landing-page">
      {/* Ambient background effects */}
      <div className="landing-orb orb-1"></div>
      <div className="landing-orb orb-2"></div>
      <div className="landing-orb orb-3"></div>

      {/* Top Navigation */}
      <nav className="landing-nav">
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <span style={{ fontSize: '24px' }}>🛡️</span>
          <span style={{ fontWeight: '800', fontSize: '18px', background: 'var(--primary-glow)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>AI Phishing</span>
        </div>
        <button onClick={onLaunch} className="landing-nav-btn">Get Started →</button>
      </nav>

      {/* Hero Section */}
      <section className="landing-hero">
        <div className="hero-badge">🔬 Powered by Hybrid AI + Gemini Intelligence</div>
        <h1 className="hero-title">
          Stop Phishing Attacks<br />
          <span className="hero-gradient-text">Before They Start</span>
        </h1>
        <p className="hero-subtitle">
          Real-time AI-powered detection engine that analyzes URLs, emails, and SMS messages 
          to identify phishing attempts, social engineering attacks, and online scams — instantly.
        </p>
        <div className="hero-cta-row">
          <button onClick={onLaunch} className="hero-btn-primary">
            Launch Security Console
            <span className="btn-arrow">→</span>
          </button>
          <button onClick={onLaunch} className="hero-btn-secondary">
            View Live Demo
          </button>
        </div>
      </section>

      {/* Stats Bar */}
      <section className="landing-stats-bar">
        {STATS.map((stat, i) => (
          <div key={i} className="stat-item">
            <div className="stat-value" style={{ color: stat.color }}>{stat.value}</div>
            <div className="stat-label">{stat.label}</div>
          </div>
        ))}
      </section>

      {/* Features Grid */}
      <section className="landing-features">
        <h2 className="section-title">What Makes It Powerful</h2>
        <p className="section-subtitle">A comprehensive security suite built with modern AI engineering</p>
        <div className="features-grid">
          {FEATURES.map((feat, i) => (
            <div key={i} className="feature-card glass-card">
              <div className="feature-tag">{feat.tag}</div>
              <div className="feature-icon">{feat.icon}</div>
              <h3>{feat.title}</h3>
              <p>{feat.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* CTA Footer */}
      <section className="landing-footer-cta">
        <h2>Ready to secure your digital footprint?</h2>
        <button onClick={onLaunch} className="hero-btn-primary" style={{ marginTop: '24px' }}>
          Create Free Account
          <span className="btn-arrow">→</span>
        </button>
        <p style={{ color: 'var(--text-muted)', fontSize: '13px', marginTop: '16px' }}>
          No credit card required • Instant access • Open source
        </p>
      </section>
    </div>
  );
}
