import React, { useState, useEffect } from 'react';
import MLDashboard from './MLDashboard';

const LOADING_STEPS = [
  "Initializing lexical verification layer...",
  "Querying global blacklists & known host feeds...",
  "Parsing security protocols and SSL headers...",
  "Scanning lexical markers and urgency weightings...",
  "Applying AI heuristic assessment classifiers...",
  "Calculating threat vector probability coefficients..."
];

export default function Scanner({ onScanComplete }) {
  const [activeTab, setActiveTab] = useState('url'); // 'url', 'text', 'screenshot', 'email', 'spam'
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
              onClick={() => setActiveTab('url')}
            >
              URL Scan
            </button>
            <button
              className={`scan-tab ${activeTab === 'text' ? 'active' : ''}`}
              onClick={() => setActiveTab('text')}
            >
              Text Scan
            </button>
            <button
              className={`scan-tab ${activeTab === 'screenshot' ? 'active' : ''}`}
              onClick={() => setActiveTab('screenshot')}
            >
              Screenshot
            </button>
            <button
              className={`scan-tab ${activeTab === 'email' ? 'active' : ''}`}
              onClick={() => setActiveTab('email')}
            >
              Email Header
            </button>
            <button
              className={`scan-tab ${activeTab === 'spam' ? 'active' : ''}`}
              onClick={() => setActiveTab('spam')}
            >
              Spam Lookup
            </button>
          </div>

          <div style={{ marginTop: '20px' }}>
            <MLDashboard key={activeTab} embedded={true} />
          </div>
        </div>
      </div>
    </div>
  );
}
