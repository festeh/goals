#!/bin/bash

echo "Building audio-cli..."
go build -o audio-cli .

if [ $? -eq 0 ]; then
    echo "✅ Build successful! Executable: ./audio-cli"
    echo ""
    echo "Setup:"
    echo "  export ELEVENLABS_API_KEY=your_api_key_here"
    echo ""
    echo "Usage:"
    echo "  ./audio-cli --help                    # Show help"
    echo "  ./audio-cli                          # Start recording (press SPACE to stop)"
    echo ""
    echo "Controls:"
    echo "  - Press SPACE to stop recording and start transcription"
    echo ""
    echo "Make sure to set ELEVENLABS_API_KEY environment variable before running."
else
    echo "❌ Build failed"
    exit 1
fi