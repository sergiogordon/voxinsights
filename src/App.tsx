import React, { useState, useEffect, useRef } from "react";
import { Mic, MicOff } from 'lucide-react';

interface Transcription {
  speaker: string;
  text: string;
}

export default function App() {
  const [isRecording, setIsRecording] = useState(false);
  const [transcriptions, setTranscriptions] = useState<Transcription[]>([
    { speaker: "Me", text: "Hello, this is a sample transcription." },
    { speaker: "Speaker 2", text: "Great! Let's test this app." },
  ]);
  const socketRef = useRef<WebSocket | null>(null);

  useEffect(() => {
    return () => {
      if (socketRef.current) {
        socketRef.current.close();
      }
    };
  }, []);

  const toggleRecording = () => {
    if (isRecording) {
      if (socketRef.current) {
        socketRef.current.close();
        socketRef.current = null;
      }
    } else {
      socketRef.current = new WebSocket('wss://voxinsights-env.eba-mzv2eb6p.us-west-2.elasticbeanstalk.com/ws');
      socketRef.current.onmessage = (event) => {
        const [speaker, text] = event.data.split(': ', 2);
        setTranscriptions(prev => [...prev, { speaker, text }]);
      };
    }
    setIsRecording(!isRecording);
  };

  return (
    <div className="flex flex-col min-h-screen bg-background">
      <header className="sticky top-0 z-10 bg-background border-b">
        <div className="container mx-auto px-4 py-4">
          <h1 className="text-2xl font-bold text-primary">VoxInsights</h1>
        </div>
      </header>
      <main className="flex-grow container mx-auto px-4 py-8 flex flex-col items-center">
        <button
          className={`mb-8 px-4 py-2 rounded-md flex items-center ${
            isRecording ? "bg-red-500 hover:bg-red-600" : "bg-blue-500 hover:bg-blue-600"
          } text-white`}
          onClick={toggleRecording}
        >
          {isRecording ? (
            <>
              <MicOff className="mr-2 h-5 w-5" /> Stop Recording
            </>
          ) : (
            <>
              <Mic className="mr-2 h-5 w-5" /> Start Recording
            </>
          )}
        </button>
        <div className="w-full max-w-2xl h-[60vh] border rounded-lg p-4 bg-white dark:bg-gray-800 overflow-y-auto">
          {transcriptions.map((transcription, index) => (
            <div key={index} className="mb-4">
              <span className="font-semibold text-primary">{transcription.speaker}: </span>
              <span>{transcription.text}</span>
            </div>
          ))}
          {isRecording && (
            <div className="flex items-center space-x-2 text-gray-500">
              <div className="w-2 h-2 bg-red-500 rounded-full animate-pulse"></div>
              <span>Transcribing...</span>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}