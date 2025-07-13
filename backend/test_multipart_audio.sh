#!/bin/bash

echo "Testing /ai/audio endpoint with multipart form data..."

# Create a small test WAV file (1 second of silence)
python3 -c "
import wave
import struct

# Create a 1-second silence WAV file
sample_rate = 16000
duration = 1
frames = sample_rate * duration

with wave.open('/tmp/test_audio.wav', 'w') as wav_file:
    wav_file.setnchannels(1)  # mono
    wav_file.setsampwidth(2)  # 16-bit
    wav_file.setframerate(sample_rate)
    
    # Generate silence (zeros)
    for _ in range(frames):
        wav_file.writeframes(struct.pack('<h', 0))

print('Created test WAV file')
"

echo "Created test WAV file at /tmp/test_audio.wav"
echo "Sending multipart request to localhost:3000/ai/audio..."
echo "Note: This will fail if ELEVENLABS_API_KEY is not set in the backend environment"

curl -X POST \
  -F "audio=@/tmp/test_audio.wav" \
  http://localhost:3000/ai/audio

echo ""
echo "Test completed. Check the response above."
echo "If you see 'ELEVENLABS_API_KEY environment variable is required', set ELEVENLABS_API_KEY in your backend environment."