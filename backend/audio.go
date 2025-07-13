package main

import (
	"encoding/json"
	"net/http"

	"github.com/dima-b/go-task-backend/logger"
	"github.com/dima-b/go-task-backend/transcription"
)

type AudioTranscriptionRequest struct {
	PCMData []byte `json:"pcm_data"`
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

	// Use shared transcription function
	result, err := transcription.TranscribePCM(req.PCMData)
	if err != nil {
		logger.Error("Failed to transcribe audio").Err(err).Send()
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	logger.Info("Successfully transcribed audio").Str("text", result.Text).Send()
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result)
}
