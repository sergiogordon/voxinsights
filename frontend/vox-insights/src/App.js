import React, { useState } from 'react';
import axios from 'axios';
import './App.css';

function App() {
  const [duration, setDuration] = useState(5);
  const [transcription, setTranscription] = useState('');
  const [isRecording, setIsRecording] = useState(false);

  const handleStartRecording = async () => {
    setIsRecording(true);
    try {
      const response = await axios.post(`${process.env.REACT_APP_BACKEND_URL}/start_recording_and_transcribing/`, { duration });
      setTranscription(response.data.transcriptions.join('\n'));
    } catch (error) {
      console.error("Error starting recording:", error);
    }
    setIsRecording(false);
  };

  return (
    <div className="app-container">
      <header className="app-header">
        <h1>VoxInsights</h1>
      </header>
      <main className="app-main">
        <div className="recording-controls">
          <label htmlFor="duration-input">Recording Duration (seconds):</label>
          <input
            id="duration-input"
            type="number"
            value={duration}
            onChange={(e) => setDuration(e.target.value)}
            min="1"
          />
          <button 
            onClick={handleStartRecording} 
            disabled={isRecording}
            className={isRecording ? 'recording' : ''}
          >
            {isRecording ? 'Recording...' : 'Start Recording'}
          </button>
        </div>
        <div className="transcription-section">
          <h2>Transcription:</h2>
          <pre className="transcription-text">{transcription || 'No transcription available yet.'}</pre>
        </div>
      </main>
    </div>
  );
}

export default App;