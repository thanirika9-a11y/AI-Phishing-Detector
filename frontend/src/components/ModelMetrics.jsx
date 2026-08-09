import React from 'react';

export default function ModelMetrics() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr', gap: '32px' }}>
      
      {/* Left: Model Metrics & Confusion Matrix */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
        <div className="glass-card">
          <h2 style={{ marginBottom: '20px' }}>Evaluation Performance Scores</h2>
          
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            {/* Accuracy */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '14px', marginBottom: '4px' }}>
                <span>Classification Accuracy</span>
                <span style={{ color: '#00f2fe', fontWeight: '700' }}>98.2%</span>
              </div>
              <div style={{ height: '8px', background: 'rgba(255,255,255,0.05)', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ width: '98.2%', height: '100%', background: 'var(--primary-glow)' }}></div>
              </div>
            </div>

            {/* Precision */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '14px', marginBottom: '4px' }}>
                <span>Model Precision (Low False Alarms)</span>
                <span style={{ color: '#b34eff', fontWeight: '700' }}>98.5%</span>
              </div>
              <div style={{ height: '8px', background: 'rgba(255,255,255,0.05)', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ width: '98.5%', height: '100%', background: 'var(--purple-glow)' }}></div>
              </div>
            </div>

            {/* Recall */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '14px', marginBottom: '4px' }}>
                <span>Model Recall (Detection Rate)</span>
                <span style={{ color: 'var(--color-safe)', fontWeight: '700' }}>97.9%</span>
              </div>
              <div style={{ height: '8px', background: 'rgba(255,255,255,0.05)', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ width: '97.9%', height: '100%', background: 'linear-gradient(to right, #10b981, #059669)' }}></div>
              </div>
            </div>

            {/* F1 Score */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '14px', marginBottom: '4px' }}>
                <span>Balanced F1-Score</span>
                <span style={{ color: 'var(--color-suspicious)', fontWeight: '700' }}>98.2%</span>
              </div>
              <div style={{ height: '8px', background: 'rgba(255,255,255,0.05)', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ width: '98.2%', height: '100%', background: 'linear-gradient(to right, #f59e0b, #d97706)' }}></div>
              </div>
            </div>
          </div>
        </div>

        {/* Confusion Matrix */}
        <div className="glass-card glow-cyan">
          <h2 style={{ marginBottom: '16px' }}>Interactive Confusion Matrix</h2>
          <p style={{ color: 'var(--text-sub)', fontSize: '13px', marginBottom: '20px' }}>
            Confusion Matrix results evaluating model classifications on 2,000 independent test domains.
          </p>

          <div style={{ display: 'grid', gridTemplateColumns: '80px 1fr 1fr', gap: '8px', textAlign: 'center', fontFamily: 'var(--font-sans)', fontSize: '14px' }}>
            {/* Row 0 Header */}
            <div></div>
            <div style={{ fontWeight: '700', padding: '6px', color: 'var(--text-muted)' }}>Classified Legit</div>
            <div style={{ fontWeight: '700', padding: '6px', color: 'var(--text-muted)' }}>Classified Phish</div>

            {/* Row 1 Actual Legit */}
            <div style={{ fontWeight: '700', alignSelf: 'center', textAlign: 'right', paddingRight: '8px', color: 'var(--text-muted)' }}>Actual Legit</div>
            <div style={{ background: 'rgba(16, 185, 129, 0.08)', border: '1px solid rgba(16, 185, 129, 0.3)', padding: '16px', borderRadius: '8px' }}>
              <div style={{ fontSize: '20px', fontWeight: '800', color: 'var(--color-safe)' }}>940</div>
              <div style={{ fontSize: '10px', color: 'var(--text-muted)', marginTop: '4px' }}>TRUE NEGATIVES (TN)</div>
            </div>
            <div style={{ background: 'rgba(239, 68, 68, 0.08)', border: '1px solid rgba(239, 68, 68, 0.3)', padding: '16px', borderRadius: '8px' }}>
              <div style={{ fontSize: '20px', fontWeight: '800', color: 'var(--color-dangerous)' }}>15</div>
              <div style={{ fontSize: '10px', color: 'var(--text-muted)', marginTop: '4px' }}>FALSE POSITIVES (FP)</div>
            </div>

            {/* Row 2 Actual Phish */}
            <div style={{ fontWeight: '700', alignSelf: 'center', textAlign: 'right', paddingRight: '8px', color: 'var(--text-muted)' }}>Actual Phish</div>
            <div style={{ background: 'rgba(239, 68, 68, 0.08)', border: '1px solid rgba(239, 68, 68, 0.3)', padding: '16px', borderRadius: '8px' }}>
              <div style={{ fontSize: '20px', fontWeight: '800', color: 'var(--color-dangerous)' }}>21</div>
              <div style={{ fontSize: '10px', color: 'var(--text-muted)', marginTop: '4px' }}>FALSE NEGATIVES (FN)</div>
            </div>
            <div style={{ background: 'rgba(16, 185, 129, 0.08)', border: '1px solid rgba(16, 185, 129, 0.3)', padding: '16px', borderRadius: '8px' }}>
              <div style={{ fontSize: '20px', fontWeight: '800', color: 'var(--color-safe)' }}>1024</div>
              <div style={{ fontSize: '10px', color: 'var(--text-muted)', marginTop: '4px' }}>TRUE POSITIVES (TP)</div>
            </div>
          </div>
        </div>
      </div>

      {/* Right: Technical Hyperparameters & Loss Curves */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
        <div className="glass-card">
          <h2 style={{ marginBottom: '16px' }}>Training Hyperparameters</h2>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', fontSize: '14px' }}>
            <div style={{ background: 'rgba(255,255,255,0.015)', border: '1px solid var(--border-glass)', padding: '12px', borderRadius: '8px' }}>
              <div style={{ color: 'var(--text-muted)', fontSize: '12px' }}>DATASET SIZE</div>
              <div style={{ fontWeight: '700', fontSize: '16px', marginTop: '2px', color: '#00f2fe' }}>42,000 domains</div>
            </div>
            <div style={{ background: 'rgba(255,255,255,0.015)', border: '1px solid var(--border-glass)', padding: '12px', borderRadius: '8px' }}>
              <div style={{ color: 'var(--text-muted)', fontSize: '12px' }}>TRAIN / TEST RATIO</div>
              <div style={{ fontWeight: '700', fontSize: '16px', marginTop: '2px' }}>80% / 20%</div>
            </div>
            <div style={{ background: 'rgba(255,255,255,0.015)', border: '1px solid var(--border-glass)', padding: '12px', borderRadius: '8px' }}>
              <div style={{ color: 'var(--text-muted)', fontSize: '12px' }}>EPOCHS</div>
              <div style={{ fontWeight: '700', fontSize: '16px', marginTop: '2px' }}>20</div>
            </div>
            <div style={{ background: 'rgba(255,255,255,0.015)', border: '1px solid var(--border-glass)', padding: '12px', borderRadius: '8px' }}>
              <div style={{ color: 'var(--text-muted)', fontSize: '12px' }}>LEARNING RATE</div>
              <div style={{ fontWeight: '700', fontSize: '16px', marginTop: '2px', fontFamily: 'var(--font-mono)' }}>0.001</div>
            </div>
          </div>
        </div>

        <div className="glass-card">
          <h2 style={{ marginBottom: '16px' }}>Training Epoch Loss Curve</h2>
          <p style={{ color: 'var(--text-sub)', fontSize: '13px', marginBottom: '20px' }}>
            Comparative representation of Epoch Loss metrics displaying model convergence.
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            {/* Epoch 1 */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', color: 'var(--text-muted)', marginBottom: '4px' }}>
                <span>Epoch 1 (Start)</span>
                <span>Loss: 0.68</span>
              </div>
              <div style={{ height: '6px', background: 'rgba(255,255,255,0.05)', borderRadius: '3px', overflow: 'hidden' }}>
                <div style={{ width: '68%', height: '100%', background: 'var(--color-dangerous)' }}></div>
              </div>
            </div>

            {/* Epoch 5 */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', color: 'var(--text-muted)', marginBottom: '4px' }}>
                <span>Epoch 5</span>
                <span>Loss: 0.32</span>
              </div>
              <div style={{ height: '6px', background: 'rgba(255,255,255,0.05)', borderRadius: '3px', overflow: 'hidden' }}>
                <div style={{ width: '32%', height: '100%', background: 'var(--color-suspicious)' }}></div>
              </div>
            </div>

            {/* Epoch 10 */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', color: 'var(--text-muted)', marginBottom: '4px' }}>
                <span>Epoch 10</span>
                <span>Loss: 0.12</span>
              </div>
              <div style={{ height: '6px', background: 'rgba(255,255,255,0.05)', borderRadius: '3px', overflow: 'hidden' }}>
                <div style={{ width: '12%', height: '100%', background: 'var(--color-safe)' }}></div>
              </div>
            </div>

            {/* Epoch 20 */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', color: 'var(--text-muted)', marginBottom: '4px' }}>
                <span>Epoch 20 (Optimal)</span>
                <span>Loss: 0.04</span>
              </div>
              <div style={{ height: '6px', background: 'rgba(255,255,255,0.05)', borderRadius: '3px', overflow: 'hidden' }}>
                <div style={{ width: '4%', height: '100%', background: 'var(--color-safe)' }}></div>
              </div>
            </div>
          </div>
        </div>
      </div>

    </div>
  );
}
