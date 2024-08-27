import warnings
warnings.filterwarnings("ignore", category=FutureWarning)

from fastapi import FastAPI, HTTPException, WebSocket, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import sounddevice as sd
import numpy as np
import whisper
import asyncio
import queue
import time
import logging
import os

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=[os.environ.get("FRONTEND_URL", "http://localhost:3000")],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

model = whisper.load_model("base")  # Load the Whisper model

class AudioRecordingRequest(BaseModel):
    duration: int

class AudioSegment:
    def __init__(self, audio_data, start_time):
        self.audio_data = audio_data
        self.start_time = start_time

async def record_audio(duration, fs, audio_queue, stop_event):
    chunk_duration = 1  # Record in 1-second chunks
    silence_threshold = 0.01  # Adjust this value based on your microphone and environment
    last_sound_time = time.time()
    segment_start_time = time.time()
    current_segment = []

    logger.info("Recording for %s seconds...", duration)
    for _ in range(int(duration / chunk_duration)):
        if stop_event.is_set():
            break
        
        try:
            recording = sd.rec(int(chunk_duration * fs), samplerate=fs, channels=1)
            sd.wait()
        except sd.PortAudioError as e:
            logger.error(f"Audio input error: {str(e)}")
            stop_event.set()
            break
        
        if np.abs(recording).mean() > silence_threshold:
            last_sound_time = time.time()
            current_segment.append(recording)
        else:
            if current_segment:
                segment = np.concatenate(current_segment)
                audio_queue.put(AudioSegment(segment, segment_start_time))
                current_segment = []
                segment_start_time = time.time()
        
        if time.time() - last_sound_time > 30:
            logger.info("No audio detected for 30 seconds. Stopping recording.")
            stop_event.set()
            break

    # Add any remaining audio in the current segment
    if current_segment:
        segment = np.concatenate(current_segment)
        audio_queue.put(AudioSegment(segment, segment_start_time))

async def transcribe_audio(audio_queue, stop_event, websocket):
    speaker_id = 1
    speakers = {}
    
    while not stop_event.is_set():
        try:
            audio_segment = audio_queue.get_nowait()
            audio_float32 = audio_segment.audio_data.flatten().astype(np.float32)
            try:
                result = await asyncio.to_thread(model.transcribe, audio_float32)
                
                # Simulate speaker identification (replace with actual speaker diarization if available)
                if result['text'] not in speakers:
                    speakers[result['text']] = f"Voice #{speaker_id}"
                    speaker_id += 1
                
                speaker_label = speakers[result['text']]
                transcription = f"{speaker_label}: {result['text']}"
                
                logger.info("Transcription (%.2f): %s", audio_segment.start_time, transcription)
                
                # Send transcription to the client via WebSocket
                await websocket.send_text(transcription)
            except Exception as e:
                logger.error(f"Whisper processing error: {str(e)}")
        except queue.Empty:
            await asyncio.sleep(0.1)

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    logger.info("WebSocket connection opened")
    
    fs = 44100  # Sample rate
    audio_queue = asyncio.Queue()
    stop_event = asyncio.Event()
    
    # Start recording and transcription tasks
    recording_task = asyncio.create_task(record_audio(3600, fs, audio_queue, stop_event))  # Record for 1 hour max
    transcription_task = asyncio.create_task(transcribe_audio(audio_queue, stop_event, websocket))
    
    try:
        while True:
            message = await websocket.receive_text()
            if message == "STOP":
                stop_event.set()
                break
    finally:
        # Ensure both tasks are stopped
        stop_event.set()
        await asyncio.gather(recording_task, transcription_task, return_exceptions=True)
        logger.info("WebSocket connection closed")

@app.get("/")
async def root():
    return {"message": "VoxInsights API is running"}

@app.post("/transcribe")
async def transcribe(request: Request):
    try:
        audio_data = await request.body()
        # Process the audio data and transcribe it
        # This is a placeholder - you'll need to implement the actual transcription logic
        result = await asyncio.to_thread(model.transcribe, audio_data)
        return {"transcription": result["text"]}
    except Exception as e:
        logger.error(f"Transcription error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Transcription error: {str(e)}")

@app.post("/record")
async def record(request: AudioRecordingRequest):
    try:
        fs = 44100  # Sample rate
        seconds = request.duration
        audio_queue = asyncio.Queue()
        stop_event = asyncio.Event()

        recording_task = asyncio.create_task(record_audio(seconds, fs, audio_queue, stop_event))
        await recording_task

        # Process the recorded audio (e.g., save it or transcribe it)
        # This is a placeholder - you'll need to implement the actual processing logic
        return {"message": "Recording completed"}
    except Exception as e:
        logger.error(f"Recording error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Recording error: {str(e)}")

@app.get("/history")
async def get_history():
    # This is a placeholder - you'll need to implement the actual history retrieval logic
    # For example, you might fetch transcription history from a database
    return {"history": []}

@app.websocket("/ws-connect")
async def websocket_connect(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            # Process the received data
            # This is a placeholder - you'll need to implement the actual WebSocket logic
            await websocket.send_text(f"Received: {data}")
    except Exception as e:
        logger.error(f"WebSocket error: {str(e)}")
    finally:
        await websocket.close()

if __name__ == "__main__":
    import uvicorn
    logger.info("Starting the FastAPI server...")
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8000)))