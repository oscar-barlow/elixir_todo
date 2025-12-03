# ElixirTodo

ElixirTodo is a small, test-driven Elixir project demonstrating a clean Ports & Adapters (Hexagonal) architecture for a simple todo list. It emphasizes separation of concerns, compile-time dependency injection, and straightforward domain logic.

**Goals**
- Keep core business logic pure and dependency-free
- Use behaviours (ports) to define adapter contracts
- Inject adapter dependencies via application config for testability
- Favor clarity and simple functions over clever abstractions

## Architecture

Follows Hexagonal Architecture: core domain is pure and defines contracts; adapters implement those contracts and orchestrate IO/formatting. Core never imports adapters; adapters depend on core and ports.

## Dependency Injection

Adapters read dependencies at compile time using `Application.compile_env/3`. Defaults point to the real core modules in production; the test config overrides them to Mox mocks. This keeps the CLI adapter decoupled and easily testable.

## Design Decisions

- **1-Based Indexing**: User-facing task indices start at 1
  - Internally converted to 0-based when using `Enum`: `Enum.fetch(task_list.tasks, index - 1)`
  - CLI adapter maps user indices to stable task IDs for domain operations
- **ID-Based Task References**: Tasks have SHA-256 hash IDs based on description
  - Domain layer uses stable IDs instead of fragile positional indices
  - Natural deduplication (same description = same ID)
- **No Concurrency**: Avoid GenServer/Agent/Task; pure functions are enough for this CLI app
- **Error Handling**: Domain operations return result tuples (`{:ok, result}` or `{:error, reason}`)
  - More idiomatic Elixir than raising exceptions
  - Adapters map domain errors to user-friendly messages
- **Invariant Enforcement**: TaskList acts as a consistency boundary
  - Validates business rules (no duplicates, task must exist, etc.)
  - Returns error tuples for validation failures
- **Readability First**: Prefer straightforward pipelines and function heads over cleverness

## Setup

Requires Elixir.

```bash
mix deps.get
mix compile
```

## Usage

The app is available as an executable escript binary. Build it with:

```bash
mix escript.build
```

This creates a `todo` executable. Run it:

```bash
# Add a task
./todo add Buy groceries

# Show help
./todo help
```

Tasks are stored in `~/todo.txt`.

## Testing

Uses ExUnit and Mox. Tests follow TDD and mock adapter dependencies via behaviours. See the test files for examples of delegation and contract verification.

## Configuration

Adapter modules are set via application config. Production uses real implementations; tests override to mocks. This single configuration point ensures decoupling and easy swapping of dependencies.

## Future Ideas (Not Planned)

These are interesting learning exercises but overkill for a simple CLI todo app:

### Concurrency with GenServers & OTP

A fun OTP learning project would be making the app concurrent and event-driven:

**Basic GenServer Implementation:**
- `TaskListServer` GenServer to manage task list state
- `StorageServer` GenServer for async file I/O
- Supervision tree with `Application` supervisor
- Replace direct function calls with GenServer messages

**Event Infrastructure:**
- Add `EventBus` using `Phoenix.PubSub` or `Registry`
- Emit infrastructure-level events: `:task_added`, `:task_completed`, `:task_removed`
- `StorageServer` subscribes to events for auto-save
- Keep domain pure (no event emission in TaskList module)

**Example Flow:**
```elixir
# CLI sends command to TaskListServer
GenServer.call(TaskListServer, {:mark_done, task_id})

# TaskListServer calls pure domain
{:ok, updated_list} = TaskList.mark_task_as_done(state.list, task_id)

# TaskListServer emits event
EventBus.publish({:task_completed, task_id, updated_list})

# StorageServer receives event and saves async
def handle_info({:task_completed, _id, task_list}, state) do
  GenServer.cast(self(), {:save, task_list})
  {:noreply, state}
end
```

**Learning Objectives:**
- GenServer state management
- Supervision trees and fault tolerance
- PubSub patterns
- Async message passing
- Process linking and monitoring
- Event-driven architecture

**Note**: Total overkill for a CLI app, but excellent for learning Elixir/OTP patterns!

