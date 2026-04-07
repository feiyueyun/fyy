# Framework Integration

FYY is agent-neutral — it works with any AI agent framework. This guide covers how to connect popular frameworks to the FYY platform.

## Supported Frameworks

| Framework | Integration Method | Status |
|-----------|-------------------|--------|
| [CrewAI](https://github.com/crewAIInc/crewAI) | MCP Server Gateway | Supported |
| [LangGraph](https://github.com/langchain-ai/langgraph) | MCP Server Gateway | Supported |
| [Mastra](https://github.com/mastra-ai/mastra) | MCP Server Gateway | Supported |
| [OpenClaw](https://github.com/openclaw) | Native skill.json | Supported |
| Any MCP-compatible agent | MCP Server Gateway | Supported |

## How Integration Works

FYY provides a **MCP Server Gateway** that exposes AI employee skills as standard MCP tools. Any agent framework that supports the Model Context Protocol can discover and invoke FYY skills.

```
┌──────────────────┐     MCP      ┌──────────────────┐
│  Your AI Agent   │◄────────────►│  FYY MCP Gateway │
│  (CrewAI, etc.)  │              │                  │
└──────────────────┘              └────────┬─────────┘
                                           │
                                  ┌────────▼─────────┐
                                  │  FYY Skill Mesh  │
                                  │  (WireGuard)     │
                                  └──────────────────┘
```

1. Your agent connects to FYY's MCP Gateway
2. The gateway exposes available skills as MCP tools
3. Your agent invokes skills through standard MCP calls
4. FYY routes the request through the encrypted mesh network
5. The skill executes and returns results

## CrewAI Integration

### Setup

```python
from crewai import Agent, Task, Crew
from crewai_tools import MCPTool

# Connect to FYY's MCP Gateway
fyy_tools = MCPTool(
    server_url="http://localhost:3000/mcp",  # FYY MCP Gateway
)

# Create an agent that uses FYY skills
listing_agent = Agent(
    role="E-Commerce Listing Specialist",
    goal="Create optimized multilingual product listings",
    tools=[fyy_tools],
)

# Define a task
task = Task(
    description="Generate Amazon JP listing for product: {product_description}",
    agent=listing_agent,
    expected_output="Optimized Japanese product listing ready to publish",
)

# Run
crew = Crew(agents=[listing_agent], tasks=[task])
result = crew.kickoff()
```

### What Happens

1. CrewAI agent discovers FYY skills through the MCP Gateway
2. Agent selects the `listing-generator` skill based on the task
3. FYY routes the request to the skill provider through the mesh network
4. The skill generates the listing and returns it
5. CrewAI agent receives the finished listing

## LangGraph Integration

### Setup

```python
from langgraph.prebuilt import create_react_agent
from langchain_mcp import MCPToolkit

# Connect to FYY's MCP Gateway
toolkit = MCPToolkit(server_url="http://localhost:3000/mcp")
tools = toolkit.get_tools()

# Create a LangGraph agent with FYY skills
agent = create_react_agent(
    model="gpt-4",
    tools=tools,
)

# Invoke
result = agent.invoke({
    "messages": [
        {"role": "user", "content": "Analyze competitor pricing for wireless earbuds on Amazon US"}
    ]
})
```

## OpenClaw Integration

OpenClaw skills use the same `skill.json` format as FYY. No conversion needed.

```bash
# Install an OpenClaw skill directly
fyy skill install <openclaw-skill-name>

# Start it
fyy skill start <openclaw-skill-name>
```

## Importing Existing Skills

### From Agent Skills (SKILL.md)

If you have skills defined in the Anthropic Agent Skills format:

```bash
# Single file
fyy skill import --from=agent-skills ./my-skill/SKILL.md

# Batch import from a directory
fyy skill import --from=agent-skills --dir=~/.claude/skills/
```

### From Any MCP Server

Any running MCP server can be registered as a FYY skill:

```bash
fyy skill register --name=my-tool --type=mcp --endpoint=http://localhost:8080
```

## Security

All inter-agent communication in FYY goes through WireGuard-encrypted mesh connections. When your CrewAI agent calls a FYY skill:

- The request is encrypted end-to-end
- The skill provider only sees the input, not your agent's internal state
- Grants control exactly what data the skill can access
- All invocations are logged for audit

This means you can safely use third-party skills without exposing your business data or agent logic.
