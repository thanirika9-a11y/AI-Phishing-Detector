import React from 'react';

export default function Dashboard({ analytics, loading }) {
  if (loading || !analytics) {
    return (
      <div className="glass-card" style={{ textAlign: 'center', padding: '40px' }}>
        <div className="spinner" style={{ margin: '0 auto 16px' }}></div>
        <p style={{ color: 'var(--text-sub)' }}>Analyzing threat intelligence databases...</p>
      </div>
    );
  }

  const {
    total_scans,
    total_reports,
    scans_breakdown,
    reports_by_type,
    recent_scans,
    recent_reports
  } = analytics;

  // Safe percentage helper
  const dangerousCount = scans_breakdown.dangerous || 0;
  const suspiciousCount = scans_breakdown.suspicious || 0;
  const safeCount = scans_breakdown.safe || 0;

  const totalBreakdown = dangerousCount + suspiciousCount + safeCount;
  const safePercent = totalBreakdown > 0 ? Math.round((safeCount / totalBreakdown) * 100) : 100;

  return (
    <div>
      {/* Metrics Row */}
      <div className="metrics-grid">
        <div className="glass-card metric-card">
          <div className="metric-icon-wrapper" style={{ background: 'rgba(0, 242, 254, 0.12)', color: '#00f2fe', border: '1px solid rgba(0, 242, 254, 0.3)' }}>
            🔍
          </div>
          <div className="metric-info">
            <h3>Total Analyzed</h3>
            <p>{total_scans}</p>
          </div>
        </div>

        <div className="glass-card metric-card">
          <div className="metric-icon-wrapper" style={{ background: 'rgba(179, 78, 255, 0.12)', color: '#b34eff', border: '1px solid rgba(179, 78, 255, 0.3)' }}>
            📢
          </div>
          <div className="metric-info">
            <h3>Crowdsourced Reports</h3>
            <p>{total_reports}</p>
          </div>
        </div>

        <div className="glass-card metric-card">
          <div className="metric-icon-wrapper" style={{ background: 'rgba(16, 185, 129, 0.12)', color: 'var(--color-safe)', border: '1px solid rgba(16, 185, 129, 0.3)' }}>
            🛡️
          </div>
          <div className="metric-info">
            <h3>Safe Queries</h3>
            <p>{safePercent}%</p>
          </div>
        </div>

        <div className="glass-card metric-card">
          <div className="metric-icon-wrapper" style={{ background: 'rgba(239, 68, 68, 0.12)', color: 'var(--color-dangerous)', border: '1px solid rgba(239, 68, 68, 0.3)' }}>
            ⚠️
          </div>
          <div className="metric-info">
            <h3>Malicious Threat Logs</h3>
            <p>{dangerousCount}</p>
          </div>
        </div>
      </div>

      {/* Main Dashboard Panel */}
      <div className="dashboard-layout">
        {/* Left Side: Recent scans & reports feed */}
        <div className="recent-activity-panel">
          <div className="glass-card">
            <h3 style={{ marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span>🛡️</span> Real-time Phishing Scanner Logs
            </h3>
            
            {recent_scans.length === 0 ? (
              <p style={{ color: 'var(--text-muted)', fontSize: '14px', textAlign: 'center', padding: '24px' }}>
                No URLs or text analyzed yet. Try scanning in the "Detector Console"!
              </p>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                {recent_scans.map((scan) => {
                  let details = {};
                  try {
                    details = JSON.parse(scan.details_json);
                  } catch (e) {}

                  return (
                    <div key={scan.id} className="threat-feed-item">
                      <div className="feed-details">
                        <div className="feed-indicator">
                          {scan.input_type.toUpperCase()}: {scan.input_content.length > 50 ? scan.input_content.substring(0, 50) + '...' : scan.input_content}
                        </div>
                        <div className="feed-desc">
                          {details.reasons && details.reasons[0] ? details.reasons[0] : "No risk markers identified."}
                        </div>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                        <span className={`status-badge ${scan.risk_level.toLowerCase()}`}>
                          {scan.risk_level} ({scan.risk_score}%)
                        </span>
                        <span className="feed-time">
                          {new Date(scan.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                        </span>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          <div className="glass-card">
            <h3 style={{ marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span>📢</span> Community Reported Threats
            </h3>
            
            {recent_reports.length === 0 ? (
              <p style={{ color: 'var(--text-muted)', fontSize: '14px', textAlign: 'center', padding: '24px' }}>
                No active threats reported by the community yet.
              </p>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                {recent_reports.map((report) => (
                  <div key={report.id} className="threat-feed-item">
                    <div className="feed-details">
                      <div className="feed-indicator" style={{ color: 'var(--color-dangerous)' }}>
                        {report.scam_type.toUpperCase()}: {report.indicator}
                      </div>
                      <div className="feed-desc">{report.description || "No description provided."}</div>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                      <span className="status-badge dangerous">REPORTED</span>
                      <span className="feed-time">
                        {new Date(report.timestamp).toLocaleDateString()}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Right Side: Threat intelligence charts */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          <div className="glass-card">
            <h3 style={{ marginBottom: '20px' }}>Threat Level Share</h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              {/* Safe */}
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '14px', marginBottom: '4px' }}>
                  <span>Safe Queries</span>
                  <span style={{ color: 'var(--color-safe)', fontWeight: '600' }}>{safeCount}</span>
                </div>
                <div style={{ height: '8px', background: 'rgba(255,255,255,0.05)', borderRadius: '4px', overflow: 'hidden' }}>
                  <div style={{ width: `${totalBreakdown > 0 ? (safeCount / totalBreakdown) * 100 : 0}%`, height: '100%', background: 'var(--color-safe)' }}></div>
                </div>
              </div>

              {/* Suspicious */}
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '14px', marginBottom: '4px' }}>
                  <span>Suspicious Alerts</span>
                  <span style={{ color: 'var(--color-suspicious)', fontWeight: '600' }}>{suspiciousCount}</span>
                </div>
                <div style={{ height: '8px', background: 'rgba(255,255,255,0.05)', borderRadius: '4px', overflow: 'hidden' }}>
                  <div style={{ width: `${totalBreakdown > 0 ? (suspiciousCount / totalBreakdown) * 100 : 0}%`, height: '100%', background: 'var(--color-suspicious)' }}></div>
                </div>
              </div>

              {/* Dangerous */}
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '14px', marginBottom: '4px' }}>
                  <span>Confirmed Phish</span>
                  <span style={{ color: 'var(--color-dangerous)', fontWeight: '600' }}>{dangerousCount}</span>
                </div>
                <div style={{ height: '8px', background: 'rgba(255,255,255,0.05)', borderRadius: '4px', overflow: 'hidden' }}>
                  <div style={{ width: `${totalBreakdown > 0 ? (dangerousCount / totalBreakdown) * 100 : 0}%`, height: '100%', background: 'var(--color-dangerous)' }}></div>
                </div>
              </div>
            </div>
          </div>

          <div className="glass-card">
            <h3 style={{ marginBottom: '20px' }}>Scam Typology breakdown</h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              {Object.entries(reports_by_type).map(([key, count]) => {
                const totalRep = Object.values(reports_by_type).reduce((a, b) => a + b, 0);
                const percent = totalRep > 0 ? (count / totalRep) * 100 : 0;
                
                let color = '#b34eff';
                if (key === 'phishing') color = '#00f2fe';
                if (key === 'smishing') color = '#10b981';
                if (key === 'vishing') color = '#f59e0b';

                return (
                  <div key={key}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '14px', marginBottom: '4px', textTransform: 'capitalize' }}>
                      <span>{key}</span>
                      <span style={{ color: color, fontWeight: '600' }}>{count}</span>
                    </div>
                    <div style={{ height: '6px', background: 'rgba(255,255,255,0.05)', borderRadius: '3px', overflow: 'hidden' }}>
                      <div style={{ width: `${percent}%`, height: '100%', background: color }}></div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
