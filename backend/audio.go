package main

import (
	"encoding/json"
	"io"
	"net/http"

	"github.com/dima-b/go-task-backend/logger"
	"github.com/dima-b/go-task-backend/transcription"
)

type AudioTranscriptionRequest struct {
	PCMData []byte `json:"pcm_data"`
}

func transcribeAudio(w http.ResponseWriter, r *http.Request) {
	logger.Info("Transcribing audio").Send()

	// Check if it's multipart form data (frontend) or JSON (CLI via backend)
	contentType := r.Header.Get("Content-Type")
	
	if contentType == "application/json" {
		// Handle JSON request (for backward compatibility)
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

		// Use shared transcription function for PCM
		result, err := transcription.TranscribePCM(req.PCMData)
		if err != nil {
			logger.Error("Failed to transcribe audio").Err(err).Send()
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		logger.Info("Successfully transcribed audio").Str("text", result.Text).Send()
		
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(result)
		return
	}

	// Handle multipart form data (frontend)
	err := r.ParseMultipartForm(32 << 20) // 32MB max
	if err != nil {
		logger.Error("Failed to parse multipart form").Err(err).Send()
		http.Error(w, "Invalid multipart form", http.StatusBadRequest)
		return
	}

	// Get the audio file from the form
	file, _, err := r.FormFile("audio")
	if err != nil {
		logger.Error("Failed to get audio file from form").Err(err).Send()
		http.Error(w, "audio file is required", http.StatusBadRequest)
		return
	}
	defer file.Close()

	// Read the WAV file data
	wavData, err := io.ReadAll(file)
	if err != nil {
		logger.Error("Failed to read audio file").Err(err).Send()
		http.Error(w, "Failed to read audio file", http.StatusInternalServerError)
		return
	}

	if len(wavData) == 0 {
		logger.Error("Empty audio file provided").Send()
		http.Error(w, "audio file is empty", http.StatusBadRequest)
		return
	}

	// Use shared transcription function for WAV
	result, err := transcription.TranscribeWAV(wavData)
	if err != nil {
		logger.Error("Failed to transcribe audio").Err(err).Send()
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	logger.Info("Successfully transcribed audio").Str("text", result.Text).Send()
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result)
}
