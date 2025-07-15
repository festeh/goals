package ai

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/dima-b/go-task-backend/logger"
	"github.com/revrost/go-openrouter"
)

type Tool struct {
	Name        string                 `json:"name"`
	Description string                 `json:"description"`
	Parameters  map[string]interface{} `json:"parameters"`
	Function    func(args map[string]interface{}) (string, error)
}

type Agent struct {
	client        *openrouter.Client
	context       string
	tools         []Tool
	initialPrompt string
	model         string
}

type Message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type ToolCall struct {
	Name      string                 `json:"name"`
	Arguments map[string]interface{} `json:"arguments"`
}

func NewAgent(apiKey, context, initialPrompt string, tools []Tool) *Agent {
	client := openrouter.NewClient(apiKey)
	
	return &Agent{
		client:        client,
		context:       context,
		tools:         tools,
		initialPrompt: initialPrompt,
		model:         "google/gemini-2.0-flash-001",
	}
}

func (a *Agent) Execute(userInput string) (string, error) {
	logger.Info("Starting AI agent execution").
		Str("user_input", userInput).
		Str("model", a.model).
		Send()

	messages := []Message{
		{
			Role:    "system",
			Content: a.buildSystemPrompt(),
		},
		{
			Role:    "user",
			Content: userInput,
		},
	}

	maxIterations := 10
	for i := 0; i < maxIterations; i++ {
		logger.Info("Agent iteration").Int("iteration", i+1).Send()

		response, err := a.callModel(messages)
		if err != nil {
			logger.Error("Model call failed").Err(err).Send()
			return "", fmt.Errorf("model call failed: %w", err)
		}

		logger.Info("Model response received").Str("response", response).Send()

		toolCall, hasToolCall := a.parseToolCall(response)
		if !hasToolCall {
			logger.Info("No tool call found, returning response").Send()
			return response, nil
		}

		logger.Info("Tool call detected").Str("tool", toolCall.Name).Send()

		toolResult, err := a.executeTool(toolCall)
		if err != nil {
			logger.Error("Tool execution failed").Str("tool", toolCall.Name).Err(err).Send()
			return "", fmt.Errorf("tool execution failed: %w", err)
		}

		messages = append(messages, Message{
			Role:    "assistant",
			Content: response,
		})

		messages = append(messages, Message{
			Role:    "user",
			Content: fmt.Sprintf("Tool result: %s", toolResult),
		})

		logger.Info("Tool executed successfully").Str("tool", toolCall.Name).Str("result", toolResult).Send()
	}

	return "", fmt.Errorf("maximum iterations reached without final response")
}

func (a *Agent) buildSystemPrompt() string {
	var toolsDesc strings.Builder
	toolsDesc.WriteString("Available tools:\n")
	
	for _, tool := range a.tools {
		toolsDesc.WriteString(fmt.Sprintf("- %s: %s\n", tool.Name, tool.Description))
	}
	
	toolsDesc.WriteString("\nTo use a tool, respond with: TOOL_CALL: {\"name\": \"tool_name\", \"arguments\": {\"arg1\": \"value1\"}}\n")
	
	return fmt.Sprintf(`%s

Context: %s

%s

Instructions:
- Use the available tools to complete tasks
- Always respond with either a tool call or a final answer
- If you need to use a tool, format your response as specified above
- Provide clear and helpful responses`, a.initialPrompt, a.context, toolsDesc.String())
}

func (a *Agent) callModel(messages []Message) (string, error) {
	request := openrouter.CompletionRequest{
		Model:       a.model,
		MaxTokens:   1000,
		Temperature: 0.7,
	}

	for _, msg := range messages {
		request.Messages = append(request.Messages, openrouter.Message{
			Role:    msg.Role,
			Content: msg.Content,
		})
	}

	response, err := a.client.CreateCompletion(context.Background(), request)
	if err != nil {
		return "", err
	}

	if len(response.Choices) == 0 {
		return "", fmt.Errorf("no choices in response")
	}

	return response.Choices[0].Message.Content, nil
}

func (a *Agent) parseToolCall(response string) (ToolCall, bool) {
	const toolCallPrefix = "TOOL_CALL: "
	
	if !strings.Contains(response, toolCallPrefix) {
		return ToolCall{}, false
	}

	start := strings.Index(response, toolCallPrefix)
	if start == -1 {
		return ToolCall{}, false
	}

	jsonStr := response[start+len(toolCallPrefix):]
	
	lines := strings.Split(jsonStr, "\n")
	if len(lines) > 0 {
		jsonStr = lines[0]
	}

	var toolCall ToolCall
	if err := json.Unmarshal([]byte(jsonStr), &toolCall); err != nil {
		logger.Error("Failed to parse tool call").Str("json", jsonStr).Err(err).Send()
		return ToolCall{}, false
	}

	return toolCall, true
}

func (a *Agent) executeTool(toolCall ToolCall) (string, error) {
	for _, tool := range a.tools {
		if tool.Name == toolCall.Name {
			return tool.Function(toolCall.Arguments)
		}
	}
	
	return "", fmt.Errorf("tool not found: %s", toolCall.Name)
}

func (a *Agent) AddTool(tool Tool) {
	a.tools = append(a.tools, tool)
}

func (a *Agent) SetModel(model string) {
	a.model = model
}

func (a *Agent) SetContext(context string) {
	a.context = context
}
