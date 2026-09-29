import React, { useState, useRef, useCallback } from 'react';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer,
  LineChart, Line, PieChart, Pie, Cell, RadarChart, Radar, PolarGrid,
  PolarAngleAxis, PolarRadiusAxis
} from 'recharts';

const API = 'http://localhost:8000';

// ── Colour palette ────────────────────────────────────────────────────
const C = {
  purple:  '#8B5CF6',
  pink:    '#EC4899',
  cyan:    '#06B6D4',
  green:   '#10B981',
  orange:  '#F59E0B',
  red:     '#EF4444',
  bg:      '#0A0A1A',
  card:    'rgba(255,255,255,0.04)',
  border:  'rgba(139,92,246,0.25)',
  text:    '#E2E8F0',
  muted:   '#94A3B8',
};

const PIE_COLORS  = [C.red, C.green, C.purple, C.cyan, C.orange];
const MODEL_COLORS = { 'Random Forest': C.purple, 'Logistic Regression': C.cyan, 'Decision Tree': C.orange };

// ── Tiny helpers ─────────────────────────────────────────────────────
const Card = ({ children, style = {} }) => (
  <div style={{
    background: C.card, border: `1px solid ${C.border}`, borderRadius: 16,
    padding: '24px', backdropFilter: 'blur(12px)', ...style
  }}>
    {children}
  </div>
);

const SectionTitle = ({ icon, title, subtitle }) => (
  <div style={{ marginBottom: 24 }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 4 }}>
      <span style={{ fontSize: 22 }}>{icon}</span>
      <h2 style={{ margin: 0, fontSize: 22, fontWeight: 700, color: C.text }}>{title}</h2>
    </div>
    {subtitle && <p style={{ margin: 0, color: C.muted, fontSize: 14, paddingLeft: 32 }}>{subtitle}</p>}
  </div>
);

const MetricBadge = ({ label, value, color, unit = '%' }) => (
  <div style={{
    flex: 1, minWidth: 120, background: `${color}18`, border: `1px solid ${color}40`,
    borderRadius: 12, padding: '16px 20px', textAlign: 'center'
  }}>
    <div style={{ fontSize: 32, fontWeight: 800, color, letterSpacing: -1 }}>
      {value}{unit}
    </div>
    <div style={{ fontSize: 13, color: C.muted, marginTop: 4 }}>{label}</div>
  </div>
);

const StepBadge = ({ num, label, active, done }) => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
    <div style={{
      width: 32, height: 32, borderRadius: '50%', display: 'flex', alignItems: 'center',
      justifyContent: 'center', fontWeight: 700, fontSize: 14,
      background: done ? C.green : active ? C.purple : 'rgba(255,255,255,0.08)',
      color: done || active ? '#fff' : C.muted,
      border: `2px solid ${done ? C.green : active ? C.purple : 'rgba(255,255,255,0.12)'}`,
      transition: 'all 0.3s',
    }}>
      {done ? '✓' : num}
    </div>
    <span style={{ fontSize: 14, color: done ? C.green : active ? C.text : C.muted, fontWeight: active ? 600 : 400 }}>
      {label}
    </span>
  </div>
);

// ── Confusion Matrix Component ────────────────────────────────────────
const ConfusionMatrix = ({ cm }) => {
  if (!cm || cm.length < 2) return null;
  const [[tn, fp], [fn, tp]] = cm;
  const total = tn + fp + fn + tp;
  const cells = [
    { label: 'True Negative', value: tn, color: C.green,  desc: 'Legit → Legit ✓' },
    { label: 'False Positive', value: fp, color: C.orange, desc: 'Legit → Phishing ✗' },
    { label: 'False Negative', value: fn, color: C.red,    desc: 'Phishing → Legit ✗' },
    { label: 'True Positive',  value: tp, color: C.purple, desc: 'Phishing → Phishing ✓' },
  ];
  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 12 }}>
        {cells.map(cell => (
          <div key={cell.label} style={{
            background: `${cell.color}18`, border: `1px solid ${cell.color}40`,
            borderRadius: 10, padding: '14px 16px', textAlign: 'center'
          }}>
            <div style={{ fontSize: 28, fontWeight: 800, color: cell.color }}>{cell.value}</div>
            <div style={{ fontSize: 12, color: C.muted, marginTop: 2 }}>{cell.label}</div>
            <div style={{ fontSize: 11, color: cell.color, marginTop: 2 }}>{cell.desc}</div>
          </div>
        ))}
      </div>
      <div style={{ fontSize: 12, color: C.muted, textAlign: 'center' }}>
        Total test samples: {total}
      </div>
    </div>
  );
};

// ── ROC Curve Chart ──────────────────────────────────────────────────
const ROCChart = ({ rocData }) => {
  if (!rocData) return <div style={{ color: C.muted, textAlign: 'center', padding: 40 }}>No ROC data</div>;
  const points = rocData.fpr.map((fpr, i) => ({ fpr: Math.round(fpr * 100), tpr: Math.round(rocData.tpr[i] * 100) }));
  const baseline = [{ fpr: 0, tpr: 0 }, { fpr: 100, tpr: 100 }];
  return (
    <div>
      <div style={{ fontSize: 13, color: C.purple, fontWeight: 700, marginBottom: 8 }}>
        AUC = {rocData.auc} {rocData.auc > 0.9 ? '🏆 Excellent' : rocData.auc > 0.8 ? '✅ Good' : '⚠️ Fair'}
      </div>
      <ResponsiveContainer width="100%" height={220}>
        <LineChart margin={{ top: 5, right: 10, left: -20, bottom: 5 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
          <XAxis type="number" dataKey="fpr" domain={[0, 100]} tick={{ fill: C.muted, fontSize: 11 }} label={{ value: 'FPR %', position: 'insideBottom', fill: C.muted, fontSize: 11 }} />
          <YAxis type="number" dataKey="tpr" domain={[0, 100]} tick={{ fill: C.muted, fontSize: 11 }} />
          <Tooltip formatter={(v) => `${v}%`} contentStyle={{ background: '#1E1E3A', border: `1px solid ${C.border}`, borderRadius: 8 }} />
          <Line data={baseline} type="linear" dataKey="tpr" stroke="rgba(255,255,255,0.2)" strokeDasharray="4 4" dot={false} name="Random" />
          <Line data={points} type="monotone" dataKey="tpr" stroke={C.purple} strokeWidth={2.5} dot={false} name="Model ROC" />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
};

// ══════════════════════════════════════════════════════════════════════
// MAIN COMPONENT
// ══════════════════════════════════════════════════════════════════════

export default function MLDashboard({ embedded = false }) {
  const [step, setStep]             = useState(1);   // 1=upload 2=eda 3=train 4=results
  const [dragging, setDragging]     = useState(false);
  const [uploading, setUploading]   = useState(false);
  const [training, setTraining]     = useState(false);
  const [datasetInfo, setDatasetInfo] = useState(null);
  const [edaData, setEdaData]       = useState(null);
  const [trainResults, setTrainResults] = useState(null);
  const [selectedModel, setSelectedModel] = useState('Random Forest');
  const [error, setError]           = useState('');
  const fileRef = useRef();

  // ── Upload CSV ────────────────────────────────────────────────────
  const handleUpload = useCallback(async (file) => {
    if (!file) return;
    setError('');
    setUploading(true);
    try {
      const form = new FormData();
      form.append('file', file);
      const res = await fetch(`${API}/api/ml/upload-dataset`, { method: 'POST', body: form });
      const data = await res.json();
      if (!res.ok) throw new Error(data.detail || 'Upload failed');
      setDatasetInfo(data.dataset_info);
      setEdaData(data.eda);
      setTrainResults(null);
      setStep(2);
    } catch (e) {
      setError(e.message);
    } finally {
      setUploading(false);
    }
  }, []);

  const onDrop = useCallback((e) => {
    e.preventDefault(); setDragging(false);
    const file = e.dataTransfer.files[0];
    if (file) handleUpload(file);
  }, [handleUpload]);

  // ── Train models ──────────────────────────────────────────────────
  const handleTrain = useCallback(async () => {
    setError('');
    setTraining(true);
    setStep(3);
    try {
      const res = await fetch(`${API}/api/ml/train`, { method: 'POST' });
      const data = await res.json();
      if (!res.ok) throw new Error(data.detail || 'Training failed');
      setTrainResults(data);
      setSelectedModel(data.best_model);
      setStep(4);
    } catch (e) {
      setError(e.message);
      setStep(2);
    } finally {
      setTraining(false);
    }
  }, []);

  // ── Download sample CSV ──────────────────────────────────────────
  const downloadSample = () => {
    window.open(`${API}/api/ml/sample-dataset`, '_blank');
  };

  const model = trainResults?.models?.[selectedModel];

  // ════════════════════════════════════════════════════════════════
  // RENDER
  // ════════════════════════════════════════════════════════════════
  return (
    <div style={{ fontFamily: "'Inter', sans-serif", color: C.text, padding: embedded ? '0' : '32px 24px', maxWidth: 1200, margin: '0 auto' }}>

      {/* Page Header (hidden if embedded) */}
      {!embedded && (
        <div style={{ marginBottom: 36 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 8 }}>
            <div style={{
              width: 48, height: 48, borderRadius: 14, background: 'linear-gradient(135deg, #8B5CF6, #EC4899)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24
            }}>🧠</div>
            <div>
              <h1 style={{ margin: 0, fontSize: 28, fontWeight: 800, background: 'linear-gradient(90deg, #8B5CF6, #EC4899)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
                ML Dataset Analysis
              </h1>
              <p style={{ margin: 0, color: C.muted, fontSize: 14 }}>Upload phishing CSV → EDA Graphs → Train Models → Evaluate Performance</p>
            </div>
          </div>

          {/* Step indicator */}
          <div style={{ display: 'flex', gap: 24, marginTop: 20, flexWrap: 'wrap' }}>
            <StepBadge num={1} label="Upload Dataset" active={step === 1} done={step > 1} />
            <div style={{ width: 24, height: 2, background: step > 1 ? C.green : C.border, alignSelf: 'center', borderRadius: 2 }} />
            <StepBadge num={2} label="Explore Data (EDA)" active={step === 2} done={step > 2} />
            <div style={{ width: 24, height: 2, background: step > 2 ? C.green : C.border, alignSelf: 'center', borderRadius: 2 }} />
            <StepBadge num={3} label="Train Models" active={step === 3} done={step > 3} />
            <div style={{ width: 24, height: 2, background: step > 3 ? C.green : C.border, alignSelf: 'center', borderRadius: 2 }} />
            <StepBadge num={4} label="View Results" active={step === 4} done={false} />
          </div>
        </div>
      )}

      {/* Error banner */}
      {error && (
        <div style={{ background: `${C.red}18`, border: `1px solid ${C.red}50`, borderRadius: 10, padding: '12px 16px', marginBottom: 20, color: C.red, fontSize: 14 }}>
          ⚠️ {error}
        </div>
      )}

      {/* ── STEP 1: Upload ─────────────────────────────────────────── */}
      <Card style={{ marginBottom: 28 }}>
        <SectionTitle icon="📂" title="Step 1 — Upload Dataset" subtitle="Upload any open-source phishing CSV dataset (PhiUSIIL, UCI, Kaggle, etc.)" />

        {/* Drop zone */}
        <div
          onDragOver={(e) => { e.preventDefault(); setDragging(true); }}
          onDragLeave={() => setDragging(false)}
          onDrop={onDrop}
          onClick={() => fileRef.current?.click()}
          style={{
            border: `2px dashed ${dragging ? C.purple : C.border}`,
            borderRadius: 14, padding: '48px 24px', textAlign: 'center', cursor: 'pointer',
            background: dragging ? `${C.purple}10` : 'rgba(255,255,255,0.02)',
            transition: 'all 0.25s',
          }}
        >
          <div style={{ fontSize: 48, marginBottom: 12 }}>{uploading ? '⏳' : '📥'}</div>
          <div style={{ fontSize: 18, fontWeight: 600, color: C.text, marginBottom: 6 }}>
            {uploading ? 'Uploading & Parsing…' : 'Drag & drop your CSV file here'}
          </div>
          <div style={{ color: C.muted, fontSize: 14, marginBottom: 20 }}>
            Supports: PhiUSIIL · UCI Phishing Websites · Kaggle Phishing Dataset · Any URL+label CSV
          </div>
          {!uploading && (
            <button
              style={{
                background: 'linear-gradient(135deg, #8B5CF6, #EC4899)', border: 'none',
                borderRadius: 10, padding: '12px 28px', color: '#fff', fontWeight: 700,
                fontSize: 15, cursor: 'pointer',
              }}
            >
              Browse File
            </button>
          )}
          <input ref={fileRef} type="file" accept=".csv,.arff" style={{ display: 'none' }} onChange={e => handleUpload(e.target.files[0])} />
        </div>

        {/* Sample download */}
        <div style={{ marginTop: 16, display: 'flex', alignItems: 'center', gap: 12 }}>
          <span style={{ color: C.muted, fontSize: 13 }}>Don't have a dataset?</span>
          <button onClick={downloadSample} style={{
            background: 'transparent', border: `1px solid ${C.cyan}50`, borderRadius: 8,
            padding: '7px 16px', color: C.cyan, fontSize: 13, cursor: 'pointer', fontWeight: 600
          }}>
            ⬇️ Download Sample CSV (100 rows)
          </button>
        </div>

        {/* Supported formats info */}
        <div style={{ marginTop: 16, display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          {['url + label (0/1)', 'URL + result (phishing/legitimate)', 'UCI format (numeric features)', 'Any label column name'].map(fmt => (
            <span key={fmt} style={{
              background: `${C.purple}15`, border: `1px solid ${C.purple}30`,
              borderRadius: 20, padding: '4px 12px', fontSize: 12, color: C.purple
            }}>{fmt}</span>
          ))}
        </div>
      </Card>

      {/* ── STEP 2: EDA Results ────────────────────────────────────── */}
      {edaData && step >= 2 && (
        <>
          {/* Dataset info strip */}
          <Card style={{ marginBottom: 28, background: `${C.purple}12` }}>
            <SectionTitle icon="📊" title="Step 2 — Exploratory Data Analysis" subtitle={`Dataset loaded: ${datasetInfo?.total_rows?.toLocaleString()} rows · ${datasetInfo?.feature_count} features`} />

            {/* Info cards row */}
            <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', marginBottom: 28 }}>
              {[
                { label: 'Total Rows',    value: datasetInfo?.total_rows?.toLocaleString(), color: C.purple, unit: '' },
                { label: 'Phishing',      value: datasetInfo?.phishing_count?.toLocaleString(), color: C.red,    unit: '' },
                { label: 'Legitimate',    value: datasetInfo?.legit_count?.toLocaleString(),    color: C.green,  unit: '' },
                { label: 'Class Balance', value: datasetInfo?.class_balance, color: C.orange, unit: '% phishing' },
                { label: 'Features',      value: datasetInfo?.feature_count, color: C.cyan,   unit: '' },
              ].map(m => (
                <div key={m.label} style={{
                  flex: '1 1 120px', minWidth: 110,
                  background: `${m.color}15`, border: `1px solid ${m.color}40`,
                  borderRadius: 12, padding: '14px 18px', textAlign: 'center'
                }}>
                  <div style={{ fontSize: 24, fontWeight: 800, color: m.color }}>{m.value}{m.unit}</div>
                  <div style={{ fontSize: 12, color: C.muted, marginTop: 3 }}>{m.label}</div>
                </div>
              ))}
            </div>

            {/* Charts grid */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: 20 }}>

              {/* 1. Label distribution */}
              <Card>
                <h3 style={{ margin: '0 0 16px', fontSize: 15, color: C.text }}>🏷️ Label Distribution</h3>
                <ResponsiveContainer width="100%" height={200}>
                  <PieChart>
                    <Pie
                      data={[
                        { name: 'Phishing',   value: edaData.label_distribution.phishing },
                        { name: 'Legitimate', value: edaData.label_distribution.legitimate },
                      ]}
                      cx="50%" cy="50%" outerRadius={70} dataKey="value" label={({ name, percent }) => `${name} ${(percent * 100).toFixed(1)}%`}
                      labelLine={false}
                    >
                      <Cell fill={C.red} />
                      <Cell fill={C.green} />
                    </Pie>
                    <Tooltip contentStyle={{ background: '#1E1E3A', border: `1px solid ${C.border}`, borderRadius: 8 }} />
                  </PieChart>
                </ResponsiveContainer>
              </Card>

              {/* 2. URL length histogram */}
              {edaData.url_length_histogram?.length > 0 && (
                <Card>
                  <h3 style={{ margin: '0 0 16px', fontSize: 15, color: C.text }}>📏 URL Length Distribution</h3>
                  <ResponsiveContainer width="100%" height={200}>
                    <BarChart data={edaData.url_length_histogram} margin={{ top: 5, right: 10, left: -25, bottom: 15 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                      <XAxis dataKey="range" tick={{ fill: C.muted, fontSize: 10 }} angle={-30} textAnchor="end" />
                      <YAxis tick={{ fill: C.muted, fontSize: 10 }} />
                      <Tooltip contentStyle={{ background: '#1E1E3A', border: `1px solid ${C.border}`, borderRadius: 8 }} />
                      <Bar dataKey="count" fill={C.purple} radius={[4, 4, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </Card>
              )}

              {/* 3. TLD distribution */}
              {edaData.tld_distribution?.length > 0 && (
                <Card>
                  <h3 style={{ margin: '0 0 16px', fontSize: 15, color: C.text }}>🌐 TLD Distribution (Phishing vs Legit)</h3>
                  <ResponsiveContainer width="100%" height={200}>
                    <BarChart data={edaData.tld_distribution} margin={{ top: 5, right: 10, left: -25, bottom: 15 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                      <XAxis dataKey="tld" tick={{ fill: C.muted, fontSize: 11 }} />
                      <YAxis tick={{ fill: C.muted, fontSize: 10 }} />
                      <Tooltip contentStyle={{ background: '#1E1E3A', border: `1px solid ${C.border}`, borderRadius: 8 }} />
                      <Legend />
                      <Bar dataKey="phishing"   fill={C.red}   radius={[4, 4, 0, 0]} name="Phishing" />
                      <Bar dataKey="legitimate" fill={C.green} radius={[4, 4, 0, 0]} name="Legitimate" />
                    </BarChart>
                  </ResponsiveContainer>
                </Card>
              )}

              {/* 4. Feature comparison */}
              {edaData.feature_stats?.length > 0 && (
                <Card style={{ gridColumn: edaData.tld_distribution?.length > 0 ? 'auto' : 'span 2' }}>
                  <h3 style={{ margin: '0 0 16px', fontSize: 15, color: C.text }}>📐 Feature Mean (Phishing vs Legitimate)</h3>
                  <ResponsiveContainer width="100%" height={220}>
                    <BarChart data={edaData.feature_stats.slice(0, 10)} layout="vertical" margin={{ top: 5, right: 20, left: 80, bottom: 5 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                      <XAxis type="number" tick={{ fill: C.muted, fontSize: 10 }} />
                      <YAxis type="category" dataKey="feature" tick={{ fill: C.muted, fontSize: 10 }} width={80} />
                      <Tooltip contentStyle={{ background: '#1E1E3A', border: `1px solid ${C.border}`, borderRadius: 8 }} />
                      <Legend />
                      <Bar dataKey="phishing_mean" fill={C.red}   name="Phishing Avg" />
                      <Bar dataKey="legit_mean"    fill={C.green} name="Legit Avg" />
                    </BarChart>
                  </ResponsiveContainer>
                </Card>
              )}
            </div>

            {/* Train button */}
            <div style={{ marginTop: 28, textAlign: 'center' }}>
              <button
                onClick={handleTrain}
                disabled={training}
                style={{
                  background: training ? 'rgba(139,92,246,0.3)' : 'linear-gradient(135deg, #8B5CF6, #EC4899)',
                  border: 'none', borderRadius: 12, padding: '16px 48px',
                  color: '#fff', fontWeight: 800, fontSize: 17, cursor: training ? 'not-allowed' : 'pointer',
                  transition: 'all 0.3s', letterSpacing: 0.5,
                  boxShadow: training ? 'none' : '0 8px 32px rgba(139,92,246,0.4)',
                }}
              >
                {training ? '⏳ Training Models…' : '🚀 Train ML Models'}
              </button>
              {training && (
                <p style={{ color: C.muted, fontSize: 13, marginTop: 10 }}>
                  Training Random Forest · Logistic Regression · Decision Tree…
                </p>
              )}
            </div>
          </Card>
        </>
      )}

      {/* ── STEP 4: Training Results ──────────────────────────────── */}
      {trainResults && step >= 4 && (
        <Card>
          <SectionTitle icon="🏆" title="Step 3 — Model Performance Results" subtitle={`Best model: ${trainResults.best_model} · ${trainResults.total_samples?.toLocaleString()} samples trained`} />

          {/* Model selector tabs */}
          <div style={{ display: 'flex', gap: 8, marginBottom: 24 }}>
            {Object.keys(trainResults.models).map(name => (
              <button
                key={name}
                onClick={() => setSelectedModel(name)}
                style={{
                  background: selectedModel === name ? MODEL_COLORS[name] : 'rgba(255,255,255,0.05)',
                  border: `1px solid ${selectedModel === name ? MODEL_COLORS[name] : C.border}`,
                  borderRadius: 10, padding: '8px 18px', color: selectedModel === name ? '#fff' : C.muted,
                  fontWeight: selectedModel === name ? 700 : 400, fontSize: 14, cursor: 'pointer',
                  transition: 'all 0.2s',
                }}
              >
                {name === trainResults.best_model ? `🏆 ${name}` : name}
              </button>
            ))}
          </div>

          {model && (
            <>
              {/* Metric badges */}
              <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', marginBottom: 28 }}>
                <MetricBadge label="Accuracy"  value={model.accuracy}  color={C.purple} />
                <MetricBadge label="Precision" value={model.precision} color={C.cyan} />
                <MetricBadge label="Recall"    value={model.recall}    color={C.orange} />
                <MetricBadge label="F1-Score"  value={model.f1_score}  color={C.green} />
              </div>

              {/* Charts row */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: 20 }}>

                {/* Confusion Matrix */}
                <Card>
                  <h3 style={{ margin: '0 0 16px', fontSize: 15, color: C.text }}>🎯 Confusion Matrix</h3>
                  <ConfusionMatrix cm={model.confusion_matrix} />
                </Card>

                {/* ROC Curve */}
                <Card>
                  <h3 style={{ margin: '0 0 16px', fontSize: 15, color: C.text }}>📈 ROC Curve</h3>
                  <ROCChart rocData={model.roc_curve} />
                </Card>

                {/* Feature Importance */}
                {model.feature_importance?.length > 0 && (
                  <Card style={{ gridColumn: 'span 2' }}>
                    <h3 style={{ margin: '0 0 16px', fontSize: 15, color: C.text }}>🔑 Feature Importance (Top 15)</h3>
                    <ResponsiveContainer width="100%" height={280}>
                      <BarChart data={model.feature_importance} layout="vertical" margin={{ top: 5, right: 30, left: 120, bottom: 5 }}>
                        <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                        <XAxis type="number" tick={{ fill: C.muted, fontSize: 10 }} />
                        <YAxis type="category" dataKey="feature" tick={{ fill: C.muted, fontSize: 11 }} width={120} />
                        <Tooltip
                          formatter={(v) => [`${(v * 100).toFixed(2)}%`, 'Importance']}
                          contentStyle={{ background: '#1E1E3A', border: `1px solid ${C.border}`, borderRadius: 8 }}
                        />
                        <Bar dataKey="importance" radius={[0, 4, 4, 0]}>
                          {model.feature_importance.map((_, i) => (
                            <Cell key={i} fill={`hsl(${260 - i * 10}, 70%, 65%)`} />
                          ))}
                        </Bar>
                      </BarChart>
                    </ResponsiveContainer>
                  </Card>
                )}
              </div>

              {/* All models comparison table */}
              <div style={{ marginTop: 24 }}>
                <h3 style={{ margin: '0 0 14px', fontSize: 15, color: C.text }}>📋 Models Comparison</h3>
                <div style={{ overflowX: 'auto' }}>
                  <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 14 }}>
                    <thead>
                      <tr>
                        {['Model', 'Accuracy', 'Precision', 'Recall', 'F1-Score', 'Train Samples', 'Test Samples'].map(h => (
                          <th key={h} style={{ padding: '10px 14px', textAlign: 'left', color: C.muted, fontWeight: 600, borderBottom: `1px solid ${C.border}`, whiteSpace: 'nowrap' }}>{h}</th>
                        ))}
                      </tr>
                    </thead>
                    <tbody>
                      {Object.entries(trainResults.models).map(([name, m]) => (
                        <tr key={name} style={{ background: name === trainResults.best_model ? `${C.purple}10` : 'transparent' }}>
                          <td style={{ padding: '10px 14px', color: C.text, fontWeight: name === trainResults.best_model ? 700 : 400, borderBottom: `1px solid rgba(255,255,255,0.05)` }}>
                            {name === trainResults.best_model ? '🏆 ' : ''}{name}
                          </td>
                          {[m.accuracy, m.precision, m.recall, m.f1_score].map((v, i) => (
                            <td key={i} style={{ padding: '10px 14px', borderBottom: `1px solid rgba(255,255,255,0.05)` }}>
                              <span style={{ color: v > 90 ? C.green : v > 75 ? C.orange : C.red, fontWeight: 600 }}>{v}%</span>
                            </td>
                          ))}
                          <td style={{ padding: '10px 14px', color: C.muted, borderBottom: `1px solid rgba(255,255,255,0.05)` }}>{m.train_samples}</td>
                          <td style={{ padding: '10px 14px', color: C.muted, borderBottom: `1px solid rgba(255,255,255,0.05)` }}>{m.test_samples}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </>
          )}
        </Card>
      )}

      {/* Empty state */}
      {step === 1 && !uploading && (
        <div style={{ textAlign: 'center', padding: '60px 24px', color: C.muted }}>
          <div style={{ fontSize: 64, marginBottom: 16 }}>🗂️</div>
          <div style={{ fontSize: 18, fontWeight: 600, color: C.text, marginBottom: 8 }}>No dataset loaded yet</div>
          <div style={{ fontSize: 14 }}>Upload a CSV above to begin exploratory analysis and model training</div>
        </div>
      )}
    </div>
  );
}
