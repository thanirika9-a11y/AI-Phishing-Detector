import React, { useState, useEffect } from 'react';

export default function Reporter({ reports, onReportSubmitted }) {
  const [scamType, setScamType] = useState('phishing');
  const [indicator, setIndicator] = useState('');
  const [description, setDescription] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!indicator.trim()) return;

    setSubmitting(true);
    try {
      const response = await fetch('http://localhost:8000/api/reports', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          scam_type: scamType,
          indicator: indicator,
          description: description
        })
      });

      if (response.ok) {
        setIndicator('');
        setDescription('');
        onReportSubmitted(); // Trigger parent reload of recent lists & analytics
        alert("Thank you! Scam threat indicator reported successfully.");
      } else {
        alert("Failed to submit scam report.");
      }
    } catch (err) {
      console.error(err);
      alert("Error contacting backend database. Please try again.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '32px' }}>
      {/* Report Form */}
      <div className="glass-card glow-purple">
        <h2 style={{ marginBottom: '24px', display: 'flex', alignItems: 'center', gap: '10px' }}>
          <span>📢</span> Report Active Threat
        </h2>
        <p style={{ color: 'var(--text-sub)', fontSize: '14px', marginBottom: '24px' }}>
          Help secure others by reporting malicious URLs, emails, SMS links, or fraudulent phone numbers. Your crowdsourced report is added directly to our local detection database.
        </p>

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Scam Category</label>
            <select
              className="form-input"
              value={scamType}
              onChange={(e) => setScamType(e.target.value)}
              disabled={submitting}
              style={{ background: 'var(--bg-darker)' }}
            >
              <option value="phishing">🌐 Phishing Domain / Link</option>
              <option value="smishing">💬 Smishing (SMS Fraud Text)</option>
              <option value="vishing">📞 Vishing (Voice Call / Fraud Phone)</option>
              <option value="other">❓ Other / Fake Identity Fraud</option>
            </select>
          </div>

          <div className="form-group">
            <label>Threat Indicator</label>
            <input
              type="text"
              className="form-input"
              placeholder="e.g. login-verify-netflix.xyz, promotions@reward-claims.net, or phone number"
              value={indicator}
              onChange={(e) => setIndicator(e.target.value)}
              disabled={submitting}
              required
            />
          </div>

          <div className="form-group">
            <label>Context / Description</label>
            <textarea
              className="form-input"
              style={{ minHeight: '120px', resize: 'vertical' }}
              placeholder="Provide details about the attack vector (e.g., received via SMS claiming package delivery failure)..."
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              disabled={submitting}
            />
          </div>

          <button type="submit" className="submit-button" disabled={submitting || !indicator.trim()}>
            {submitting ? 'Broadcasting Threat Alert...' : '🚀 Broadcast Threat Report'}
          </button>
        </form>
      </div>

      {/* Database Bulletin list */}
      <div className="glass-card" style={{ display: 'flex', flexDirection: 'column' }}>
        <h2 style={{ marginBottom: '24px', display: 'flex', alignItems: 'center', gap: '10px' }}>
          <span>📋</span> Recent Crowdsourced Bulletins
        </h2>

        {reports.length === 0 ? (
          <div style={{ flexGrow: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <p style={{ color: 'var(--text-muted)', fontSize: '14px', textAlign: 'center' }}>
              No threat alerts reported. Submit above to seed the feed.
            </p>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', overflowY: 'auto', maxHeight: '420px', paddingRight: '4px' }}>
            {reports.map((report) => (
              <div key={report.id} className="threat-feed-item" style={{ borderLeft: '4px solid var(--color-dangerous)' }}>
                <div className="feed-details" style={{ maxWidth: '70%' }}>
                  <div className="feed-indicator" style={{ fontWeight: '700' }}>
                    {report.indicator}
                  </div>
                  <div style={{ display: 'flex', gap: '8px', alignItems: 'center', marginTop: '4px' }}>
                    <span className="status-badge dangerous" style={{ fontSize: '10px', padding: '2px 8px' }}>
                      {report.scam_type.toUpperCase()}
                    </span>
                    <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>
                      IP: {report.reporter_ip}
                    </span>
                  </div>
                  {report.description && (
                    <div style={{ marginTop: '8px', fontSize: '13px', color: 'var(--text-sub)', fontStyle: 'italic' }}>
                      "{report.description}"
                    </div>
                  )}
                </div>
                <div className="feed-time">
                  {new Date(report.timestamp).toLocaleDateString()}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
