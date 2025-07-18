# Audio Recording and Transcription CLI

A standalone command-line tool that records audio and transcribes it using the same ElevenLabs Speech-to-Text logic as the backend server.

## Prerequisites

- **ffmpeg**: Required for audio recording
  - Ubuntu/Debian: `sudo apt install ffmpeg`
  - macOS: `brew install ffmpeg`
  - Windows: Download from https://ffmpeg.org/

- **ElevenLabs API Key**: Required for transcription
  - Get your API key from https://elevenlabs.io/
  - Set it as an environment variable: `export ELEVENLABS_API_KEY=your_api_key_here`

## Building

```bash
./build.sh
```

## Setup

Set your ElevenLabs API key:

```bash
export ELEVENLABS_API_KEY=your_api_key_here
```

## Usage

```bash
# Show help
./audio-cli --help

# Start recording (press any key to stop)
./audio-cli
```

## Controls

- **Press ANY KEY**: Stop recording and start transcription

## Audio Format

The tool records audio in the following format:
- **Sample Rate**: 16 kHz
- **Channels**: 1 (mono)
- **Format**: PCM S16LE (16-bit signed little-endian)

This format is automatically converted to WAV and sent directly to the ElevenLabs API using shared transcription logic.

## Output

The tool provides:
- Language detection with confidence score
- Full transcription text
- Word-level timestamps (when available)

## Troubleshooting

### "ffmpeg not found"
Install ffmpeg using your system's package manager.

### "ELEVENLABS_API_KEY environment variable is required"
Set the API key: `export ELEVENLABS_API_KEY=your_api_key_here`

### "ElevenLabs API error"
- Check that your API key is valid
- Ensure you have sufficient API credits
- Verify your internet connection

### Audio input issues
- Linux: Make sure PulseAudio is running
- macOS: Grant microphone permissions if prompted
- Use `ffmpeg -f pulse -list_devices true -i dummy` to list available audio devices

## Features

- ✅ **Standalone**: No backend server required, works independently  
- ✅ **Shared logic**: Uses exact same transcription code as backend server
- ✅ **Simple controls**: Just press any key to stop recording
- ✅ **Clean architecture**: No code duplication between CLI and backend
- ✅ **Real-time**: Immediate transcription after recording
- ✅ **Detailed output**: Language detection and word timestamps