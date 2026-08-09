import React, { useState, useEffect } from 'react';

const LOADING_STEPS = [
  "Initializing lexical verification layer...",
  "Querying global blacklists & known host feeds...",
  "Parsing security protocols and SSL headers...",
  "Scanning lexical markers and urgency weightings...",
  "Applying AI heuristic assessment classifiers...",
  "Calculating threat vector probability coefficients..."
];

export default function Scanner({ onScanComplete }) {
  const [activeTab, setActiveTab] = useState('url'); // 'url' or 'text'
  const [inputContent, setInputContent] = useState('');
  const [loading, setLoading] = useState(false);
  const [loadingStep, setLoadingStep] = useState(0);
  const [result, setResult] = useState(null);

  // Cycle through loading steps to look hyper-professional
  useEffect(() => {
    let interval;
    if (loading) {
      interval = setInterval(() => {
        setLoadingStep((prev) => (prev < LOADING_STEPS.length - 1 ? prev + 1 : prev));
      }, 500);
    } else {
      setLoadingStep(0);
    }
    return () => clearInterval(interval);
  }, [loading]);

  const handleScan = async (e) => {
    e.preventDefault();
    if (!inputContent.trim()) return;

    setLoading(true);
    setResult(null);

    // Minimum delay of 1.8 seconds for professional feel
    const apiCallPromise = fetch('http://localhost:8000/api/scan', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        input_type: activeTab,
        input_content: inputContent
      })
    });

    const timerPromise = new Promise((resolve) => setTimeout(resolve, 1800));

    try {
      const [response] = await Promise.all([apiCallPromise, timerPromise]);
      if (response.ok) {
        const data = await response.json();
        setResult(data);
        onScanComplete(); // Refresh dashboard data
      } else {
        alert("Failed to analyze indicator. Make sure backend is running.");
      }
    } catch (err) {
      console.error(err);
      alert("Error reaching AI detection backend. Please check connection.");
    } finally {
      setLoading(false);
    }
  };

  const getGaugeStyles = (score, level) => {
    let color = 'var(--color-safe)';
    if (level === 'SUSPICIOUS') color = 'var(--color-suspicious)';
    if (level === 'DANGEROUS') color = 'var(--color-dangerous)';

    return {
      '--gauge-value': score,
      '--gauge-color': color,
      background: `conic-gradient(${color} calc(${score} * 1%), var(--border-glass) 0)`
    };
  };

  const getVerdictDetails = (level) => {
    switch (level) {
      case 'SAFE':
        return {
          title: 'Threat Vector Verified Safe',
          color: 'var(--color-safe)',
          desc: 'No suspicious artifacts or structural anomalies were identified. This indicator is safe to access, but continue practicing normal internet safety procedures.',
          tips: [
            "Always verify the email address matches the sender name.",
            "Verify spelling is correct in all parts of the link.",
            "Use multi-factor authentication (MFA) on all your profiles."
          ]
        };
      case 'SUSPICIOUS':
        return {
          title: 'Threat Warning: Suspicious Markers Detected',
          color: 'var(--color-suspicious)',
          desc: 'This item contains suspicious attributes commonly used in malicious layouts (e.g. unencrypted HTTP protocols, suspicious TLDs, or generic greetings). Use caution.',
          tips: [
            "Do not input usernames, bank routing numbers, or passwords on this web page.",
            "Contact the service directly through their official application support lines.",
            "Look for mismatched domains in sender headers."
          ]
        };
      case 'DANGEROUS':
        return {
          title: 'Critical Threat Alert: Phishing Pattern Identified',
          color: 'var(--color-dangerous)',
          desc: 'Highly malicious indicator matching signature credential-harvesting parameters, high-risk panic hooks, or domain masking tactics. Immediate containment advised.',
          tips: [
            "DO NOT click any links, download files, or respond to this sender.",
            "Delete this email or close the website immediately.",
            "Submit this indicator to our crowdsourced Report Center to alert other users."
          ]
        };
      default:
        return {};
    }
  };

  const parsedDetails = result ? JSON.parse(result.details_json) : null;
  const verdict = result ? getVerdictDetails(result.risk_level) : null;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '32px' }}>
      <div className="glass-card">
        <h2 style={{ marginBottom: '24px', display: 'flex', alignItems: 'center', gap: '10px' }}>
          <span>🛡️</span> AI Detection Console
        </h2>

        <div className="scanner-console">
          {/* Scanner Selection Tabs */}
          <div className="scanner-tabs">
            <button
              className={`scan-tab ${activeTab === 'url' ? 'active' : ''}`}
              onClick={() => { setActiveTab('url'); setInputContent(''); setResult(null); }}
              disabled={loading}
            >
              🌐 URL Threat Scan
            </button>
            <button
              className={`scan-tab ${activeTab === 'text' ? 'active' : ''}`}
              onClick={() => { setActiveTab('text'); setInputContent(''); setResult(null); }}
              disabled={loading}
            >
              ✉️ Email & SMS Message Analyzer
            </button>
          </div>

          {/* Scanner Form */}
          <form onSubmit={handleScan} className="scanner-input-area">
            <div className="scanner-input-wrapper">
              {activeTab === 'url' ? (
                <input
                  type="text"
                  className="scanner-text-input"
                  placeholder="Paste suspicious website URL here (e.g., http://login-verify-chase.net)..."
                  value={inputContent}
                  onChange={(e) => setInputContent(e.target.value)}
                  disabled={loading}
                  required
                />
              ) : (
                <textarea
                  className="scanner-text-input"
                  placeholder="Paste email headers, full text body, or suspicious SMS message here..."
                  value={inputContent}
                  onChange={(e) => setInputContent(e.target.value)}
                  disabled={loading}
                  required
                />
              )}
            </div>

            <button type="submit" className="scan-button" disabled={loading || !inputContent.trim()}>
              {loading ? (
                <>
                  <div className="spinner"></div>
                  <span>Analyzing Threat Vector...</span>
                </>
              ) : (
                <>
                  <span>⚡</span>
                  <span>Analyze Threat Vector</span>
                </>
              )}
            </button>
          </form>
        </div>
      </div>

      {/* Loading Overlay */}
      {loading && (
        <div className="glass-card scan-progress-container glow-cyan">
          <div className="scanning-radar"></div>
          <p style={{ fontFamily: 'var(--font-mono)', fontSize: '14px', color: '#00f2fe' }}>
            {LOADING_STEPS[loadingStep]}
          </p>
        </div>
      )}

      {/* Analysis Results View */}
      {result && verdict && (
        <div className="glass-card results-layout">
          {/* Circular Threat Gauge */}
          <div className="gauge-container">
            <div className="circular-progress" style={getGaugeStyles(result.risk_score, result.risk_level)}>
              <div className="gauge-text">
                <span className="gauge-percentage" style={{ color: verdict.color }}>
                  {result.risk_score}%
                </span>
                <div className="gauge-label">Risk Rating</div>
              </div>
            </div>
            <div style={{ textAlign: 'center' }}>
              <span className={`status-badge ${result.risk_level.toLowerCase()}`} style={{ fontSize: '14px' }}>
                {result.risk_level}
              </span>
            </div>
          </div>

          {/* Audit Checklist & Recommendations */}
          <div className="results-content">
            <div className="verdict-header">
              <h2 style={{ color: verdict.color, display: 'flex', alignItems: 'center', gap: '8px' }}>
                {result.risk_level === 'SAFE' ? '✔️' : result.risk_level === 'SUSPICIOUS' ? '⚠️' : '🚨'} {verdict.title}
              </h2>
              <p style={{ color: 'var(--text-sub)', marginTop: '8px', fontSize: '14px' }}>
                {verdict.desc}
              </p>
            </div>

            {/* Check results list */}
            <div>
              <h4 style={{ marginBottom: '12px', fontSize: '14px', textTransform: 'uppercase', color: 'var(--text-muted)' }}>
                System Audit Checks
              </h4>
              <div className="checks-list">
                {parsedDetails && parsedDetails.checks && Object.entries(parsedDetails.checks).map(([checkKey, isFlagged]) => {
                  // Format checks labels
                  const label = checkKey
                    .replace(/_/g, ' ')
                    .replace(/\b\w/g, (c) => c.toUpperCase());
                  
                  // The check passes if it is NOT flagged
                  const checkPassed = !isFlagged;

                  return (
                    <div key={checkKey} className={`check-item ${checkPassed ? 'passed' : 'flagged'}`}>
                      <span className="check-icon">{checkPassed ? '✅' : '❌'}</span>
                      <span className="check-text" style={{ color: checkPassed ? 'var(--text-main)' : 'var(--color-dangerous)' }}>
                        {label} - {checkPassed ? 'Passed' : 'Flagged Risk Factor'}
                      </span>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* AI Reasoning / Explanations */}
            {parsedDetails && parsedDetails.reasons && parsedDetails.reasons.length > 0 && (
              <div>
                <h4 style={{ marginBottom: '12px', fontSize: '14px', textTransform: 'uppercase', color: 'var(--text-muted)' }}>
                  Reasoning Breakdown
                </h4>
                <ul style={{ paddingLeft: '20px', color: 'var(--text-sub)', fontSize: '14px', display: 'flex', flexDirection: 'column', gap: '8px' }}>
                  {parsedDetails.reasons.map((reason, index) => (
                    <li key={index}>{reason}</li>
                  ))}
                </ul>
              </div>
            )}

            {/* Geo-IP Network Threat Origin Logs */}
            {parsedDetails && parsedDetails.geo_ip && (
              <div>
                <h4 style={{ marginBottom: '12px', fontSize: '14px', textTransform: 'uppercase', color: 'var(--text-muted)' }}>
                  Geo-IP Network Origin Logs
                </h4>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', background: 'rgba(255,255,255,0.015)', border: '1px solid var(--border-glass)', padding: '16px', borderRadius: '12px', fontSize: '13px' }}>
                  <div><span style={{color: 'var(--text-muted)'}}>IP Address:</span> <strong style={{fontFamily: 'var(--font-mono)'}}>{parsedDetails.geo_ip.ip}</strong></div>
                  <div><span style={{color: 'var(--text-muted)'}}>Hosting Provider (ISP):</span> <strong>{parsedDetails.geo_ip.isp}</strong></div>
                  <div><span style={{color: 'var(--text-muted)'}}>Geographic Country:</span> <strong>{parsedDetails.geo_ip.country}</strong></div>
                  <div><span style={{color: 'var(--text-muted)'}}>Domain Registration Age:</span> <strong>{parsedDetails.geo_ip.domain_age}</strong></div>
                </div>
              </div>
            )}

            {/* Classification Decision Weights */}
            {parsedDetails && parsedDetails.weights && (
              <div>
                <h4 style={{ marginBottom: '12px', fontSize: '14px', textTransform: 'uppercase', color: 'var(--text-muted)' }}>
                  Classification Feature Weights
                </h4>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', background: 'rgba(255,255,255,0.015)', border: '1px solid var(--border-glass)', padding: '16px', borderRadius: '12px' }}>
                  {Object.entries(parsedDetails.weights).map(([wKey, wVal]) => {
                    const label = wKey.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
                    return (
                      <div key={wKey}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', marginBottom: '4px' }}>
                          <span>{label}</span>
                          <span style={{color: '#00f2fe', fontWeight: '700'}}>{wVal}</span>
                        </div>
                        <div style={{ height: '4px', background: 'rgba(255,255,255,0.05)', borderRadius: '2px', overflow: 'hidden' }}>
                          <div style={{ width: wVal, height: '100%', background: 'var(--primary-glow)' }}></div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Mitigation Tips */}
            <div>
              <h4 style={{ marginBottom: '12px', fontSize: '14px', textTransform: 'uppercase', color: 'var(--text-muted)' }}>
                Safety Recommendations
              </h4>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                {verdict.tips.map((tip, index) => (
                  <div key={index} style={{ background: 'rgba(255,255,255,0.02)', padding: '12px 16px', borderRadius: '8px', border: '1px solid var(--border-glass)', fontSize: '14px', color: 'var(--text-sub)', display: 'flex', gap: '8px' }}>
                    <span>💡</span>
                    <span>{tip}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
