package main

import (
	"bytes"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"time"

	"github.com/dima-b/go-task-backend/logger"
)

type AudioTranscriptionRequest struct {
	PCMData []byte `json:"pcm_data"`
}

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

func transcribeAudio(w http.ResponseWriter, r *http.Request) {
	logger.Info("Transcribing audio").Send()

	var req AudioTranscriptionRequest
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		logger.Error("Failed to decode audio transcription request").Err(err).Send()
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if len(req.PCMData) == 0 {
		logger.Error("No PCM data provided").Send()
		http.Error(w, "pcm_data is required", http.StatusBadRequest)
		return
	}

	// Convert PCM S16LE to WAV format
	wavData, err := pcmToWav(req.PCMData, 16000, 1, 16)
	if err != nil {
		logger.Error("Failed to convert PCM to WAV").Err(err).Send()
		http.Error(w, "Failed to convert audio format", http.StatusInternalServerError)
		return
	}

	// Get ElevenLabs API key from environment
	apiKey := os.Getenv("ELEVENLABS_API_KEY")
	if apiKey == "" {
		logger.Error("ELEVENLABS_API_KEY not set").Send()
		http.Error(w, "ElevenLabs API key not configured", http.StatusInternalServerError)
		return
	}

	// Create multipart form data
	var buf bytes.Buffer
	writer := multipart.NewWriter(&buf)

	// Add model_id field
	err = writer.WriteField("model_id", "eleven_multilingual_v2")
	if err != nil {
		logger.Error("Failed to write model_id field").Err(err).Send()
		http.Error(w, "Failed to prepare request", http.StatusInternalServerError)
		return
	}

	// Add audio file
	fileWriter, err := writer.CreateFormFile("file", "audio.wav")
	if err != nil {
		logger.Error("Failed to create form file").Err(err).Send()
		http.Error(w, "Failed to prepare request", http.StatusInternalServerError)
		return
	}

	_, err = fileWriter.Write(wavData)
	if err != nil {
		logger.Error("Failed to write audio data").Err(err).Send()
		http.Error(w, "Failed to prepare request", http.StatusInternalServerError)
		return
	}

	err = writer.Close()
	if err != nil {
		logger.Error("Failed to close multipart writer").Err(err).Send()
		http.Error(w, "Failed to prepare request", http.StatusInternalServerError)
		return
	}

	// Create request to ElevenLabs API
	req2, err := http.NewRequest("POST", "https://api.elevenlabs.io/v1/speech-to-text", &buf)
	if err != nil {
		logger.Error("Failed to create ElevenLabs request").Err(err).Send()
		http.Error(w, "Failed to create API request", http.StatusInternalServerError)
		return
	}

	req2.Header.Set("xi-api-key", apiKey)
	req2.Header.Set("Content-Type", writer.FormDataContentType())

	// Make request to ElevenLabs
	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req2)
	if err != nil {
		logger.Error("Failed to call ElevenLabs API").Err(err).Send()
		http.Error(w, "Failed to transcribe audio", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		logger.Error("ElevenLabs API error").Int("status_code", resp.StatusCode).Str("response", string(body)).Send()
		http.Error(w, fmt.Sprintf("Transcription failed: %s", string(body)), resp.StatusCode)
		return
	}

	// Parse ElevenLabs response
	var elevenLabsResp ElevenLabsResponse
	err = json.NewDecoder(resp.Body).Decode(&elevenLabsResp)
	if err != nil {
		logger.Error("Failed to decode ElevenLabs response").Err(err).Send()
		http.Error(w, "Failed to parse transcription response", http.StatusInternalServerError)
		return
	}

	logger.Info("Successfully transcribed audio").Str("text", elevenLabsResp.Text).Send()
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(elevenLabsResp)
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