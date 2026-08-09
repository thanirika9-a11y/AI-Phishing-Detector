import React, { useState, useEffect } from 'react';

export default function Training() {
  const [quizzes, setQuizzes] = useState([]);
  const [currentIdx, setCurrentIdx] = useState(0);
  const [score, setScore] = useState(0);
  const [userAnswer, setUserAnswer] = useState(null); // 'phish' or 'legit'
  const [showExplanation, setShowExplanation] = useState(false);
  const [quizFinished, setQuizFinished] = useState(false);
  const [username, setUsername] = useState('');
  const [submittingScore, setSubmittingScore] = useState(false);
  const [leaderboard, setLeaderboard] = useState([]);
  const [loading, setLoading] = useState(true);

  // Load quizzes and leaderboard on mount
  useEffect(() => {
    fetchQuizzes();
    fetchLeaderboard();
  }, []);

  const fetchQuizzes = async () => {
    try {
      const res = await fetch('http://localhost:8000/api/quizzes');
      if (res.ok) {
        const data = await res.json();
        setQuizzes(data);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const fetchLeaderboard = async () => {
    try {
      const res = await fetch('http://localhost:8000/api/quizzes/leaderboard');
      if (res.ok) {
        const data = await res.json();
        setLeaderboard(data);
      }
    } catch (err) {
      console.error(err);
    }
  };

  const handleAnswer = (choice) => {
    if (showExplanation) return;
    
    setUserAnswer(choice);
    setShowExplanation(true);
    
    if (choice === quizzes[currentIdx].type) {
      setScore((prev) => prev + 1);
    }
  };

  const handleNext = () => {
    setUserAnswer(null);
    setShowExplanation(false);
    
    if (currentIdx < quizzes.length - 1) {
      setCurrentIdx((prev) => prev + 1);
    } else {
      setQuizFinished(true);
    }
  };

  const submitScore = async (e) => {
    e.preventDefault();
    if (!username.trim()) return;

    setSubmittingScore(true);
    try {
      const res = await fetch('http://localhost:8000/api/quizzes/submit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          username: username,
          score: score,
          total: quizzes.length
        })
      });

      if (res.ok) {
        setUsername('');
        fetchLeaderboard();
        alert("Score submitted successfully!");
      }
    } catch (err) {
      console.error(err);
    } finally {
      setSubmittingScore(false);
    }
  };

  const resetQuiz = () => {
    setCurrentIdx(0);
    setScore(0);
    setUserAnswer(null);
    setShowExplanation(false);
    setQuizFinished(false);
  };

  if (loading || quizzes.length === 0) {
    return (
      <div className="glass-card" style={{ textAlign: 'center', padding: '40px' }}>
        <div className="spinner" style={{ margin: '0 auto 16px' }}></div>
        <p style={{ color: 'var(--text-sub)' }}>Preparing simulation environments...</p>
      </div>
    );
  }

  const currentQuiz = quizzes[currentIdx];
  const isCorrectAnswer = userAnswer === currentQuiz.type;

  return (
    <div className="training-layout">
      {/* Left Column: Interactive Simulator */}
      <div className="quiz-card glass-card">
        {!quizFinished ? (
          <div>
            <div className="quiz-header">
              <span className="quiz-category">🌐 {currentQuiz.category} Threat Scenario</span>
              <span className="quiz-badge">Question {currentIdx + 1} of {quizzes.length}</span>
            </div>

            <h3 style={{ marginBottom: '16px', fontSize: '18px' }}>{currentQuiz.title}</h3>
            
            {/* Email / SMS Simulator Wrapper */}
            <div className="email-simulator">
              <div className="email-header-sim">
                {currentQuiz.category === 'Email' ? (
                  <>
                    <div className="email-header-line">
                      <span>From:</span> {currentQuiz.sender}
                    </div>
                    <div className="email-header-line">
                      <span>To:</span> security-trainee@domain.com
                    </div>
                  </>
                ) : (
                  <div className="email-header-line">
                    <span>Sender ID:</span> {currentQuiz.sender} (SMS Alert)
                  </div>
                )}
                <div className="email-header-line">
                  <span>Subject:</span> {currentQuiz.title}
                </div>
              </div>
              <div className="email-body-sim">{currentQuiz.content}</div>
            </div>

            {/* Selection Buttons */}
            {!showExplanation ? (
              <div className="quiz-actions">
                <button className="action-btn phish" onClick={() => handleAnswer('phish')}>
                  🚩 Flag as Phish / Scam
                </button>
                <button className="action-btn legit" onClick={() => handleAnswer('legit')}>
                  ✅ Legit / Trustworthy
                </button>
              </div>
            ) : (
              <div className={`quiz-feedback ${isCorrectAnswer ? 'correct' : 'incorrect'}`}>
                <div className="feedback-headline" style={{ color: isCorrectAnswer ? 'var(--color-safe)' : 'var(--color-dangerous)' }}>
                  {isCorrectAnswer ? '🎉 Correct Choice!' : '❌ Oops! Incorrect Assessment'}
                </div>
                <div className="feedback-desc">{currentQuiz.explanation}</div>
                <button className="next-btn" onClick={handleNext}>
                  {currentIdx < quizzes.length - 1 ? 'Proceed to Next Scenario' : 'View Final Score'}
                </button>
              </div>
            )}
          </div>
        ) : (
          <div style={{ textAlign: 'center', padding: '32px 0' }}>
            <h2 style={{ fontSize: '28px', color: '#00f2fe', marginBottom: '12px' }}>Training Lab Completed!</h2>
            <p style={{ color: 'var(--text-sub)', marginBottom: '24px' }}>
              You correctly analyzed {score} out of {quizzes.length} simulated scam configurations.
            </p>
            
            <div style={{ margin: '0 auto 24px', width: '120px', height: '120px', borderRadius: '50%', background: 'rgba(0, 242, 254, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '2px solid #00f2fe' }}>
              <span style={{ fontSize: '32px', fontWeight: '800', fontFamily: 'var(--font-mono)' }}>
                {Math.round((score / quizzes.length) * 100)}%
              </span>
            </div>

            {/* Score Submission Form */}
            <form onSubmit={submitScore} style={{ maxWidth: '360px', margin: '0 auto 24px', display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <input
                type="text"
                className="form-input"
                placeholder="Enter nickname to save score..."
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                required
              />
              <button type="submit" className="submit-button" disabled={submittingScore || !username.trim()}>
                {submittingScore ? 'Submitting...' : 'Save to Leaderboard'}
              </button>
            </form>

            <button className="next-btn" onClick={resetQuiz} style={{ background: 'none', border: '1px solid var(--border-glass-hover)', color: 'var(--text-main)' }}>
              🔄 Retake Training
            </button>
          </div>
        )}
      </div>

      {/* Right Column: Score Leaderboard */}
      <div className="glass-card">
        <h2 style={{ marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '10px' }}>
          <span>🏆</span> Trainee Leaderboard
        </h2>
        <p style={{ color: 'var(--text-muted)', fontSize: '13px', marginBottom: '16px' }}>
          Recent safety scoring of users who finished training.
        </p>

        {leaderboard.length === 0 ? (
          <p style={{ color: 'var(--text-muted)', fontSize: '13px', textAlign: 'center', padding: '16px' }}>
            No scores submitted yet. Be the first!
          </p>
        ) : (
          <div className="leaderboard-list">
            {leaderboard.map((entry, index) => (
              <div key={entry.id} className="leaderboard-row">
                <span className="leaderboard-user">
                  {index + 1}. {entry.username}
                </span>
                <span className="leaderboard-score">
                  {entry.score}/{entry.total} ({Math.round((entry.score / entry.total) * 100)}%)
                </span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
