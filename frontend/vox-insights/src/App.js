import React, { useState } from 'react';
import axios from 'axios';

function App() {
  const [duration, setDuration] = useState(5); // Default duration
  const [transcription, setTranscription] = useState('');

  const handleStartRecording = async () => {
    try {
      const response = await axios.post('http://localhost:8000/start_recording_and_transcribing/', { duration });
      setTranscription(response.data.transcriptions.join('\n')); // Assuming the response returns an array of transcriptions
    } catch (error) {
      console.error("Error starting recording:", error);
    }
  };

  return (
    <div>
      <h1>VoxInsights</h1>
      <label>
        Duration (seconds):
        <input
          type="number"
          value={duration}
          onChange={(e) => setDuration(e.target.value)}
        />
      </label>
      <button onClick={handleStartRecording}>Start Recording</button>
      <h2>Transcription:</h2>
      <pre>{transcription}</pre>
    </div>
  );
}

export default App;