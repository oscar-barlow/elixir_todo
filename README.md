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
- **No Concurrency**: Avoid GenServer/Agent/Task; pure functions are enough here
- **Error Handling**: Invalid operations raise (e.g., `Enum.OutOfBoundsError` for bad indices)
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

## Roadmap
- Structural typing with Dialyzer and spec

