package main

import (
	"bufio"
	"bytes"
	"flag"
	"fmt"
	"os"
	"os/exec"

	"github.com/dima-b/go-task-backend/transcription"
)



func main() {
	var (
		help = flag.Bool("help", false, "Show help")
	)
	flag.Parse()

	if *help {
		fmt.Println("Audio Recording and Transcription CLI")
		fmt.Println("Usage: audio-cli [options]")
		fmt.Println()
		fmt.Println("Options:")
		flag.PrintDefaults()
		fmt.Println()
		fmt.Println("Examples:")
		fmt.Println("  audio-cli                           # Record until any key is pressed")
		fmt.Println()
		fmt.Println("Controls:")
		fmt.Println("  Press ANY KEY to stop recording and start transcription")
		return
	}

	// Check if ffmpeg is available
	if !checkFFmpeg() {
		fmt.Println("Error: ffmpeg is required but not found in PATH")
		fmt.Println("Please install ffmpeg: sudo apt install ffmpeg (Ubuntu/Debian) or brew install ffmpeg (macOS)")
		os.Exit(1)
	}

	// Check if ElevenLabs API key is set
	if os.Getenv("ELEVENLABS_API_KEY") == "" {
		fmt.Println("Error: ELEVENLABS_API_KEY environment variable is required")
		fmt.Println("Set it with: export ELEVENLABS_API_KEY=your_api_key_here")
		os.Exit(1)
	}

	fmt.Println("🎤 Audio Recording and Transcription Tool")
	fmt.Println("Press ANY KEY to stop recording")
	fmt.Println()
	fmt.Println("🔴 Recording... (press any key to stop)")

	// Record audio
	pcmData, err := recordAudio()
	if err != nil {
		fmt.Printf("❌ Error recording audio: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("✅ Recorded %d bytes of audio data\n", len(pcmData))
	fmt.Println("📡 Transcribing audio...")

	// Transcribe audio using shared function
	result, err := transcription.TranscribePCM(pcmData)
	if err != nil {
		fmt.Printf("❌ Error transcribing audio: %v\n", err)
		os.Exit(1)
	}

	// Display results
	fmt.Println("\n🎯 Transcription Results:")
	fmt.Printf("Language: %s (%.2f%% confidence)\n", result.LanguageCode, result.LanguageProbability*100)
	fmt.Printf("Text: %s\n", result.Text)

	if len(result.Words) > 0 {
		fmt.Println("\n📝 Word-level timestamps:")
		for _, word := range result.Words {
			fmt.Printf("  %.2fs-%.2fs: %s\n", word.Start, word.End, word.Word)
		}
	}
}

func checkFFmpeg() bool {
	_, err := exec.LookPath("ffmpeg")
	return err == nil
}

func recordAudio() ([]byte, error) {
	// Use ffmpeg to record audio in PCM S16LE format at 16kHz
	args := []string{
		"-f", "pulse", // Use PulseAudio (Linux) - will fall back to other inputs
		"-i", "default", // Default audio input
		"-ar", "16000", // Sample rate 16kHz
		"-ac", "1", // Mono
		"-f", "s16le", // PCM signed 16-bit little-endian
		"-", // Output to stdout
	}

	cmd := exec.Command("ffmpeg", args...)
	
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	// Start the command
	err := cmd.Start()
	if err != nil {
		return nil, fmt.Errorf("failed to start ffmpeg: %v", err)
	}

	// Wait for any key press
	keyPressed := make(chan bool, 1)
	
	// Listen for any key in a separate goroutine
	go func() {
		reader := bufio.NewReader(os.Stdin)
		_, _, err := reader.ReadRune()
		if err == nil {
			keyPressed <- true
		}
	}()

	// Wait for any key press
	<-keyPressed
	fmt.Println("\n🛑 Key pressed, stopping recording...")
	
	// Stop ffmpeg
	err = cmd.Process.Kill()
	if err != nil {
		return nil, fmt.Errorf("failed to stop recording: %v", err)
	}

	// Wait for command to finish
	cmd.Wait() // Ignore error since we killed the process

	return stdout.Bytes(), nil
}

