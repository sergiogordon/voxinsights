# VoxInsights

VoxInsights is an API for real-time audio recording, transcription, and analysis.

## API Features

Our API provides the following key features:

1. Real-time audio recording
2. Speech-to-text transcription
3. Sentiment analysis
4. Speaker diarization

## Endpoints

### /start_recording_and_transcribing/

This endpoint initiates the recording and transcription process.

#### Request

- Method: POST
- Content-Type: application/json

```json
{
  "audio_format": "wav",
  "sample_rate": 44100,
  "channels": 2,
  "transcription_config": {
    "language_code": "en-US",
    "max_alternatives": 1
  }
}
```

#### Response

- Status Code: 200 OK
- Content-Type: application/json

```json
{
  "recording_id": "unique_recording_id",
  "transcription_id": "unique_transcription_id"
}
```

#### Example Request

```bash
curl -X POST \
  https://api.voxinsights.com/start_recording_and_transcribing/ \
  -H 'Content-Type: application/json' \
  -d '{
        "audio_format": "wav",
        "sample_rate": 44100,
        "channels": 2,
        "transcription_config": {
          "language_code": "en-US",
          "max_alternatives": 1
        }
      }'
```

#### Example Response

```json
{
  "recording_id": "unique_recording_id",
  "transcription_id": "unique_transcription_id"
}
```