package main

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/dima-b/go-task-backend/database"
	"github.com/dima-b/go-task-backend/logger"
	"github.com/dima-b/go-task-backend/middleware"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/cors"
	"github.com/joho/godotenv"
)

func main() {
	// Initialize logger first
	logger.InitLogger()

	err := godotenv.Load()
	if err != nil {
		logger.Warn("Error loading .env file, using environment variables").Err(err).Send()
	}

	err = database.InitDB()
	if err != nil {
		logger.Error("Unable to connect to database").Err(err).Send()
		return
	}

	logger.Info("Database initialized successfully").Send()

	r := chi.NewRouter()
	r.Use(middleware.LoggingMiddleware)
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: false,
		MaxAge:           300,
	}))

	r.Get("/", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("welcome"))
	})

	// Task routes
	r.Route("/tasks", func(r chi.Router) {
		r.Get("/", listTasks)
		r.Post("/", createTask)
		r.Route("/{taskID}", func(r chi.Router) {
			r.Put("/", updateTask)
			r.Delete("/", deleteTask)
		})
	})

	// Project routes
	r.Route("/projects", func(r chi.Router) {
		r.Get("/", listProjects)
		r.Post("/", createProject)
		r.Route("/{projectID}", func(r chi.Router) {
			r.Put("/", updateProject)
			r.Delete("/", deleteProject)
		})
	})

	logger.Info("Starting server on :3000").Send()
	err = http.ListenAndServe(":3000", r)
	if err != nil {
		logger.Error("Server failed to start").Err(err).Send()
	}
}

func listTasks(w http.ResponseWriter, r *http.Request) {
	logger.Info("Listing tasks").Send()
	
	var tasks []database.Task
	result := database.DB.Preload("Project").Find(&tasks)
	if result.Error != nil {
		logger.Error("Failed to retrieve tasks").Err(result.Error).Send()
		http.Error(w, result.Error.Error(), http.StatusInternalServerError)
		return
	}

	logger.Info("Successfully retrieved tasks").Int64("count", result.RowsAffected).Send()
	json.NewEncoder(w).Encode(tasks)
}

func createTask(w http.ResponseWriter, r *http.Request) {
	logger.Info("Creating new task").Send()
	
	var t database.Task
	err := json.NewDecoder(r.Body).Decode(&t)
	if err != nil {
		logger.Error("Failed to decode task request").Err(err).Send()
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	result := database.DB.Create(&t)
	if result.Error != nil {
		logger.Error("Failed to create task").Err(result.Error).Str("description", t.Description).Send()
		http.Error(w, result.Error.Error(), http.StatusInternalServerError)
		return
	}

	logger.Info("Successfully created task").Uint("task_id", t.ID).Str("description", t.Description).Send()
	json.NewEncoder(w).Encode(t)
}

func updateTask(w http.ResponseWriter, r *http.Request) {
	taskID := chi.URLParam(r, "taskID")
	logger.Info("Updating task").Str("task_id", taskID).Send()
	
	id, err := strconv.ParseUint(taskID, 10, 32)
	if err != nil {
		logger.Error("Invalid task ID").Str("task_id", taskID).Err(err).Send()
		http.Error(w, "Invalid task ID", http.StatusBadRequest)
		return
	}

	var t database.Task
	err = json.NewDecoder(r.Body).Decode(&t)
	if err != nil {
		logger.Error("Failed to decode task update request").Err(err).Send()
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	result := database.DB.Model(&t).Where("id = ?", uint(id)).Updates(t)
	if result.Error != nil {
		logger.Error("Failed to update task").Uint("task_id", uint(id)).Err(result.Error).Send()
		http.Error(w, result.Error.Error(), http.StatusInternalServerError)
		return
	}

	logger.Info("Successfully updated task").Uint("task_id", uint(id)).Send()
	w.WriteHeader(http.StatusOK)
}

func deleteTask(w http.ResponseWriter, r *http.Request) {
	taskID := chi.URLParam(r, "taskID")
	logger.Info("Deleting task").Str("task_id", taskID).Send()
	
	id, err := strconv.ParseUint(taskID, 10, 32)
	if err != nil {
		logger.Error("Invalid task ID").Str("task_id", taskID).Err(err).Send()
		http.Error(w, "Invalid task ID", http.StatusBadRequest)
		return
	}

	result := database.DB.Delete(&database.Task{}, uint(id))
	if result.Error != nil {
		logger.Error("Failed to delete task").Uint("task_id", uint(id)).Err(result.Error).Send()
		http.Error(w, result.Error.Error(), http.StatusInternalServerError)
		return
	}

	logger.Info("Successfully deleted task").Uint("task_id", uint(id)).Send()
	w.WriteHeader(http.StatusOK)
}

func listProjects(w http.ResponseWriter, r *http.Request) {
	logger.Info("Listing projects").Send()
	
	var projects []database.Project
	result := database.DB.Preload("Tasks").Find(&projects)
	if result.Error != nil {
		logger.Error("Failed to retrieve projects").Err(result.Error).Send()
		http.Error(w, result.Error.Error(), http.StatusInternalServerError)
		return
	}

	logger.Info("Successfully retrieved projects").Int64("count", result.RowsAffected).Send()
	json.NewEncoder(w).Encode(projects)
}

func createProject(w http.ResponseWriter, r *http.Request) {
	logger.Info("Creating new project").Send()
	
	var p database.Project
	err := json.NewDecoder(r.Body).Decode(&p)
	if err != nil {
		logger.Error("Failed to decode project request").Err(err).Send()
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	result := database.DB.Create(&p)
	if result.Error != nil {
		logger.Error("Failed to create project").Err(result.Error).Str("name", p.Name).Send()
		http.Error(w, result.Error.Error(), http.StatusInternalServerError)
		return
	}

	logger.Info("Successfully created project").Uint("project_id", p.ID).Str("name", p.Name).Send()
	json.NewEncoder(w).Encode(p)
}

func updateProject(w http.ResponseWriter, r *http.Request) {
	projectID := chi.URLParam(r, "projectID")
	logger.Info("Updating project").Str("project_id", projectID).Send()
	
	id, err := strconv.ParseUint(projectID, 10, 32)
	if err != nil {
		logger.Error("Invalid project ID").Str("project_id", projectID).Err(err).Send()
		http.Error(w, "Invalid project ID", http.StatusBadRequest)
		return
	}

	var p database.Project
	err = json.NewDecoder(r.Body).Decode(&p)
	if err != nil {
		logger.Error("Failed to decode project update request").Err(err).Send()
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	result := database.DB.Model(&p).Where("id = ?", uint(id)).Updates(p)
	if result.Error != nil {
		logger.Error("Failed to update project").Uint("project_id", uint(id)).Err(result.Error).Send()
		http.Error(w, result.Error.Error(), http.StatusInternalServerError)
		return
	}

	logger.Info("Successfully updated project").Uint("project_id", uint(id)).Send()
	w.WriteHeader(http.StatusOK)
}

func deleteProject(w http.ResponseWriter, r *http.Request) {
	projectID := chi.URLParam(r, "projectID")
	logger.Info("Deleting project").Str("project_id", projectID).Send()
	
	id, err := strconv.ParseUint(projectID, 10, 32)
	if err != nil {
		logger.Error("Invalid project ID").Str("project_id", projectID).Err(err).Send()
		http.Error(w, "Invalid project ID", http.StatusBadRequest)
		return
	}

	result := database.DB.Delete(&database.Project{}, uint(id))
	if result.Error != nil {
		logger.Error("Failed to delete project").Uint("project_id", uint(id)).Err(result.Error).Send()
		http.Error(w, result.Error.Error(), http.StatusInternalServerError)
		return
	}

	logger.Info("Successfully deleted project").Uint("project_id", uint(id)).Send()
	w.WriteHeader(http.StatusOK)
}
