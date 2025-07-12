package utils

import (
	"net/http"
	"strconv"

	"github.com/dima-b/go-task-backend/logger"
	"github.com/go-chi/chi/v5"
)

// ParseIDFromURL extracts and validates an ID parameter from the URL
func ParseIDFromURL(r *http.Request, w http.ResponseWriter, paramName string) (uint, bool) {
	idStr := chi.URLParam(r, paramName)
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		logger.Error("Invalid "+paramName).Str(paramName, idStr).Err(err).Send()
		http.Error(w, "Invalid "+paramName, http.StatusBadRequest)
		return 0, false
	}
	return uint(id), true
}

// ParseTaskID is a convenience function for parsing task IDs
func ParseTaskID(r *http.Request, w http.ResponseWriter) (uint, bool) {
	return ParseIDFromURL(r, w, "taskID")
}

// ParseProjectID is a convenience function for parsing project IDs
func ParseProjectID(r *http.Request, w http.ResponseWriter) (uint, bool) {
	return ParseIDFromURL(r, w, "projectID")
}

// ParseNoteID is a convenience function for parsing note IDs
func ParseNoteID(r *http.Request, w http.ResponseWriter) (uint, bool) {
	return ParseIDFromURL(r, w, "noteID")
}