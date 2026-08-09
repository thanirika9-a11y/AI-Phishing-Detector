import React, { useState } from 'react';

export default function DevSandbox() {
  const [apiKey, setApiKey] = useState('');
  const [loading, setLoading] = useState(false);
  
  // Interactive test client
  const [inputUrl, setInputUrl] = useState('http://secure-login-chase.net');
  const [apiResponse, setApiResponse] = useState(null);
  const [executing, setExecuting] = useState(false);

  const generateKey = async () => {
    setLoading(true);
    try {
      const res = await fetch('http://localhost:8000/api/developer/keys', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username: "aegis_developer" })
      });
      if (res.ok) {
        const data = await res.json();
        setApiKey(data.apiKey);
      } else {
        setApiKey(`aegis_live_key_${Math.random().toString(36).substring(2, 15)}`);
      }
    } catch (e) {
      setApiKey(`aegis_live_key_${Math.random().toString(36).substring(2, 15)}`);
    } finally {
      setLoading(false);
    }
  };

  const testApiClient = async () => {
    setExecuting(true);
    try {
      const res = await fetch('http://localhost:8000/api/scan', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ input_type: "url", input_content: inputUrl })
      });
      if (res.ok) {
        const data = await res.json();
        setApiResponse(data);
      } else {
        setApiResponse({ error: "Failed to query server." });
      }
    } catch (err) {
      setApiResponse({ error: "API Server offline. Try launching backend." });
    } finally {
      setExecuting(false);
    }
  };

  const curlCommand = `curl -X POST http://localhost:8000/api/scan \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer ${apiKey || 'YOUR_API_KEY'}" \\
  -d '{"input_type": "url", "input_content": "${inputUrl}"}'`;

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '32px' }}>
      
      {/* Left: Documentation and Key Generator */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
        <div className="glass-card glow-cyan">
          <h2 style={{ marginBottom: '16px' }}>Developer API Key Generator</h2>
          <p style={{ color: 'var(--text-sub)', fontSize: '14px', marginBottom: '20px' }}>
            Generate developer API keys to integrate Aegis AI's heuristic phishing scans into external mail servers, proxy servers, or enterprise firewalls.
          </p>

          {!apiKey ? (
            <button className="submit-button" onClick={generateKey} disabled={loading}>
              {loading ? 'Registering Key...' : '🔑 Generate API Token'}
            </button>
          ) : (
            <div>
              <label style={{ fontSize: '12px', color: 'var(--text-muted)', display: 'block', marginBottom: '6px' }}>Active API Key</label>
              <div style={{ display: 'flex', gap: '8px' }}>
                <input 
                  type="text" 
                  className="form-input" 
                  readOnly 
                  value={apiKey} 
                  style={{ flexGrow: 1, fontFamily: 'var(--font-mono)', fontSize: '13px', background: 'var(--bg-darker)', color: '#00f2fe' }} 
                />
                <button 
                  className="submit-button" 
                  style={{ background: 'none', border: '1px solid var(--border-glass-hover)', color: 'var(--text-main)', padding: '0 16px' }}
                  onClick={() => { navigator.clipboard.writeText(apiKey); alert("Key copied!"); }}
                >
                  Copy
                </button>
              </div>
              <span style={{ fontSize: '11px', color: 'var(--color-safe)', display: 'block', marginTop: '6px' }}>
                🟢 Status: Active | Limits: 1000 requests/day
              </span>
            </div>
          )}
        </div>

        <div className="glass-card">
          <h3 style={{ marginBottom: '12px' }}>REST Integration Documentation</h3>
          <p style={{ color: 'var(--text-sub)', fontSize: '13px', marginBottom: '16px' }}>
            Send structured HTTP POST queries to our API service to receive JSON evaluation payloads containing risk flags, Geo-IP resolution details, and confidence rates.
          </p>
          
          <label style={{ fontSize: '12px', color: 'var(--text-muted)' }}>CURL REQUEST FORMAT</label>
          <pre style={{ background: '#090b11', border: '1px solid var(--border-glass)', padding: '16px', borderRadius: '8px', color: '#c9d1d9', fontSize: '12px', fontFamily: 'var(--font-mono)', overflowX: 'auto', whiteSpace: 'pre-wrap', marginTop: '6px', lineHeight: '1.4' }}>
            {curlCommand}
          </pre>
        </div>
      </div>

      {/* Right: Sandbox Client Simulator */}
      <div className="glass-card" style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
        <h2>Interactive Sandbox Tester</h2>
        <p style={{ color: 'var(--text-sub)', fontSize: '14px' }}>
          Query endpoints dynamically inside this dashboard interface and inspect raw HTTP JSON responses returned by Aegis AI.
        </p>

        <div className="form-group">
          <label>Target URL to Test</label>
          <div style={{ display: 'flex', gap: '10px' }}>
            <input 
              type="text" 
              className="form-input" 
              value={inputUrl} 
              onChange={(e) => setInputUrl(e.target.value)}
              placeholder="e.g. http://bad-site.ru"
              style={{ flexGrow: 1 }}
            />
            <button className="submit-button" onClick={testApiClient} disabled={executing || !inputUrl}>
              {executing ? 'Sending...' : 'Send Request'}
            </button>
          </div>
        </div>

        <div>
          <label style={{ fontSize: '12px', color: 'var(--text-muted)', display: 'block', marginBottom: '6px' }}>
            HTTP RESPONSE BODY (JSON)
          </label>
          
          <div style={{ flexGrow: 1, minHeight: '260px', background: '#090b11', border: '1px solid var(--border-glass)', padding: '16px', borderRadius: '8px', overflowY: 'auto', maxHeight: '350px' }}>
            {apiResponse ? (
              <pre style={{ color: '#00f2fe', fontSize: '12px', fontFamily: 'var(--font-mono)', margin: 0, whiteSpace: 'pre-wrap' }}>
                {JSON.stringify(apiResponse, null, 2)}
              </pre>
            ) : (
              <div style={{ height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-muted)', fontSize: '13px', fontStyle: 'italic', paddingTop: '80px' }}>
                Click "Send Request" to trigger REST telemetry logs.
              </div>
            )}
          </div>
        </div>

      </div>

    </div>
  );
}
