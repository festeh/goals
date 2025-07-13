#!/bin/bash

echo "Building audio-cli..."
go build -o audiocli .

if [ $? -eq 0 ]; then
    echo "✅ Build successful! Executable: ./audio-cli"
    echo ""
    echo "Setup:"
    echo "  export ELEVENLABS_API_KEY=your_api_key_here"
    echo ""
    echo "Usage:"
    echo "  ./audio-cli --help                    # Show help"
    echo "  ./audio-cli                          # Start recording (press any key to stop)"
    echo ""
    echo "Controls:"
    echo "  - Press ANY KEY to stop recording and start transcription"
    echo ""
    echo "Standalone tool - no backend server required!"
else
    echo "❌ Build failed"
    exit 1
fi
