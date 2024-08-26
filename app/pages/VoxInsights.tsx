import { useState } from "react"
import { Button } from "@/components/ui/button"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Mic, MicOff } from "lucide-react"

export default function Component() {
  const [isRecording, setIsRecording] = useState(false)
  const [transcriptions, setTranscriptions] = useState([
    { speaker: "Me", text: "Hello, this is a sample transcription." },
    { speaker: "Speaker 2", text: "Great! Let's test this app." },
  ])

  const toggleRecording = () => {
    setIsRecording(!isRecording)
    // Here you would typically start/stop the actual recording and transcription process
  }

  return (
    <div className="flex flex-col min-h-screen bg-background">
      <header className="sticky top-0 z-10 bg-background border-b">
        <div className="container mx-auto px-4 py-4">
          <h1 className="text-2xl font-bold text-primary">VoxInsights</h1>
        </div>
      </header>
      <main className="flex-grow container mx-auto px-4 py-8 flex flex-col items-center">
        <Button
          size="lg"
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
        <ScrollArea className="w-full max-w-2xl h-[60vh] border rounded-lg p-4 bg-white dark:bg-gray-800">
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
        </ScrollArea>
      </main>
    </div>
  )
}