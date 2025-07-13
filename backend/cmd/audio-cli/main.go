package main

import (
	"bufio"
	"bytes"
	"encoding/binary"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"os/exec"
	"time"
)


type ElevenLabsResponse struct {
	LanguageCode        string `json:"language_code"`
	LanguageProbability float64 `json:"language_probability"`
	Text                string `json:"text"`
	Words               []Word `json:"words"`
}

type Word struct {
	Word      string  `json:"word"`
	Start     float64 `json:"start"`
	End       float64 `json:"end"`
	Punctuate bool    `json:"punctuate"`
}

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
	apiKey := os.Getenv("ELEVENLABS_API_KEY")
	if apiKey == "" {
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
	fmt.Println("📡 Sending to ElevenLabs transcription service...")

	// Transcribe audio directly
	result, err := transcribeAudioDirect(pcmData, apiKey)
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

func transcribeAudioDirect(pcmData []byte, apiKey string) (*ElevenLabsResponse, error) {
	// Convert PCM S16LE to WAV format
	wavData, err := pcmToWav(pcmData, 16000, 1, 16)
	if err != nil {
		return nil, fmt.Errorf("failed to convert PCM to WAV: %v", err)
	}

	// Create multipart form data
	var buf bytes.Buffer
	writer := multipart.NewWriter(&buf)

	// Add model_id field
	err = writer.WriteField("model_id", "eleven_multilingual_v2")
	if err != nil {
		return nil, fmt.Errorf("failed to write model_id field: %v", err)
	}

	// Add audio file
	fileWriter, err := writer.CreateFormFile("file", "audio.wav")
	if err != nil {
		return nil, fmt.Errorf("failed to create form file: %v", err)
	}

	_, err = fileWriter.Write(wavData)
	if err != nil {
		return nil, fmt.Errorf("failed to write audio data: %v", err)
	}

	err = writer.Close()
	if err != nil {
		return nil, fmt.Errorf("failed to close multipart writer: %v", err)
	}

	// Create request to ElevenLabs API
	req, err := http.NewRequest("POST", "https://api.elevenlabs.io/v1/speech-to-text", &buf)
	if err != nil {
		return nil, fmt.Errorf("failed to create ElevenLabs request: %v", err)
	}

	req.Header.Set("xi-api-key", apiKey)
	req.Header.Set("Content-Type", writer.FormDataContentType())

	// Make request to ElevenLabs
	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to call ElevenLabs API: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("ElevenLabs API error (status %d): %s", resp.StatusCode, string(body))
	}

	// Parse ElevenLabs response
	var elevenLabsResp ElevenLabsResponse
	err = json.NewDecoder(resp.Body).Decode(&elevenLabsResp)
	if err != nil {
		return nil, fmt.Errorf("failed to decode ElevenLabs response: %v", err)
	}

	return &elevenLabsResp, nil
}

// pcmToWav converts PCM S16LE data to WAV format
func pcmToWav(pcmData []byte, sampleRate, channels, bitsPerSample int) ([]byte, error) {
	var buf bytes.Buffer
	
	// WAV header
	dataSize := len(pcmData)
	fileSize := 36 + dataSize
	
	// RIFF header
	buf.WriteString("RIFF")
	binary.Write(&buf, binary.LittleEndian, uint32(fileSize))
	buf.WriteString("WAVE")
	
	// fmt chunk
	buf.WriteString("fmt ")
	binary.Write(&buf, binary.LittleEndian, uint32(16)) // fmt chunk size
	binary.Write(&buf, binary.LittleEndian, uint16(1))  // PCM format
	binary.Write(&buf, binary.LittleEndian, uint16(channels))
	binary.Write(&buf, binary.LittleEndian, uint32(sampleRate))
	
	byteRate := sampleRate * channels * bitsPerSample / 8
	binary.Write(&buf, binary.LittleEndian, uint32(byteRate))
	
	blockAlign := channels * bitsPerSample / 8
	binary.Write(&buf, binary.LittleEndian, uint16(blockAlign))
	binary.Write(&buf, binary.LittleEndian, uint16(bitsPerSample))
	
	// data chunk
	buf.WriteString("data")
	binary.Write(&buf, binary.LittleEndian, uint32(dataSize))
	buf.Write(pcmData)
	
	return buf.Bytes(), nil
}