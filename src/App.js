import React, { useState, useEffect, useRef } from "react";
import * as ScrollArea from '@radix-ui/react-scroll-area';
import { Mic, MicOff } from 'lucide-react';
import "./App.css";

function Button({ children, onClick, className }) {
  return (
    <button className={`button ${className}`} onClick={onClick}>
      {children}
    </button>
  );
}

function App() {
  const [isRecording, setIsRecording] = useState(false);
  const [transcriptions, setTranscriptions] = useState([
    { speaker: "Me", text: "Hello, this is a sample transcription." },
    { speaker: "Speaker 2", text: "Great! Let's test this app." },
  ]);
  const socketRef = useRef(null);

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
      socketRef.current = new WebSocket('ws://localhost:8000/ws');
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
        <Button
          className={`mb-8 ${
            isRecording ? "bg-red-500 hover:bg-red-600" : "bg-primary hover:bg-primary/90"
          }`}
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
        </Button>
        <ScrollArea.Root className="w-full max-w-2xl h-[60vh] border rounded-lg p-4 bg-white dark:bg-gray-800">
          <ScrollArea.Viewport className="w-full h-full">
            {transcriptions.map((transcription, index) => (
              <div key={index} className="mb-4">
                <span className="font-semibold text-primary">{transcription.speaker}: </span>
                <span>{transcription.text}</span>
              </div>
            ))}
            {isRecording && (
              <div className="flex items-center space-x-2 text-muted-foreground">
                <div className="w-2 h-2 bg-red-500 rounded-full animate-pulse"></div>
                <span>Transcribing...</span>
              </div>
            )}
          </ScrollArea.Viewport>
          <ScrollArea.Scrollbar orientation="vertical">
            <ScrollArea.Thumb />
          </ScrollArea.Scrollbar>
        </ScrollArea.Root>
      </main>
    </div>
  );
}

export default App;