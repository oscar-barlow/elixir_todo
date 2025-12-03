# AI Agent Instructions for ElixirTodo

## Architecture: Ports and Adapters (Hexagonal)

This codebase follows a strict hexagonal/ports-and-adapters pattern:

- **Core Domain** (`lib/todo/core/`): Business logic with no external dependencies
  - `Task` - Simple data struct with `description` and `is_done`
  - `TaskList` - Core operations defined via `TaskListBehaviour` with `@callback`s
  - Task indexing is **1-based** (user-facing), not 0-based

- **Ports** (`lib/todo/ports/`): Behaviour definitions for adapters
  - `Todo.Ports.Cli` - Defines the CLI adapter contract
  - Future: `Storage` port (commented out, planned)

- **Adapters** (`lib/todo/adapters/`): External interface implementations
  - `Todo.Adapters.Cli` - Implements `@behaviour Todo.Ports.Cli`
  - Uses compile-time dependency injection via `Application.compile_env/3`

**Critical Pattern**: Core domain never imports adapters. Adapters import and use core domain.

## Dependency Injection via Application Config

The CLI adapter uses **compile-time DI** for testability:

```elixir
@task_list_module Application.compile_env(:todo, :task_list_module, Todo.Core.TaskList)
```

- **Production**: Defaults to `Todo.Core.TaskList`
- **Test**: `config/test.exs` sets `:task_list_module` to `TaskListMock`
- Mocks defined in `test/test_helper.exs` using `Mox.defmock/2`

## Testing Conventions

1. **TDD Workflow**: This project follows test-driven development - write tests before implementation

2. **Mox for Behaviour Mocking**: 
   - Define behaviours with `@callback` in core modules
   - Create mocks: `Mox.defmock(TaskListMock, for: Todo.Core.TaskListBehaviour)`
   - Always call `:verify_on_exit!` in test setup
   - Use `expect/3` or `stub/3` for mock expectations

3. **Test Organization**:
   - Mirror `lib/` structure in `test/`
   - Unit tests for core domain should NOT use mocks
   - Adapter tests SHOULD mock their dependencies

4. **Example Test Pattern** (from `cli_test.exs`):
   ```elixir
   expect(TaskListMock, :get_not_done_tasks, fn ^task_list -> 
     %TaskList{tasks: [shopping, dinner]} 
   end)
   ```

## Key Commands

- **Run tests**: `mix test`
- **Run single test file**: `mix test test/todo/core/task_list_test.exs`
- **Compile**: `mix compile`
- **Run in console**: `iex -S mix` (for REPL experimentation)

## Design Decisions & Constraints

1. **1-Based Indexing**: User-facing task numbers start at 1, internally converted to 0-based for `Enum` operations
   ```elixir
   Enum.fetch(task_list.tasks, index - 1)  # Note the -1
   ```

2. **No Premature Concurrency**: Avoid GenServers, Tasks, Agents, or other concurrency primitives unless there's a clear performance need. Keep it simple with pure functions.

3. **Readability Over Cleverness**: Prioritize clear, straightforward code. If a pipeline or abstraction makes the logic harder to follow, break it down.

4. **Self-Documenting Code**: Code should be clear enough to be self-documenting. Do NOT add `@doc` or `@moduledoc` to most modules - the code itself should explain its purpose through good naming and structure. This is counter to standard Elixir conventions but preferred for this codebase. Only add documentation for truly complex algorithms or non-obvious behavior.

5. **Error Handling**: Domain operations return result tuples instead of raising exceptions
   - Success: `{:ok, result}`
   - Failure: `{:error, :reason_atom}`
   - Example errors: `:duplicate_task`, `:task_not_found`, `:already_done`
   - Use `with` expressions for chaining operations that can fail
   - Adapters map domain errors to user-friendly messages

6. **Invariant Enforcement**: Domain modules (like `TaskList`) act as consistency boundaries
   - Validate business rules before state changes
   - Example: `validate_not_duplicate/2` prevents duplicate tasks
   - Return error tuples for validation failures

## Common Patterns

- **Result tuples for error handling**:
  ```elixir
  case TaskList.add_task_to_list(task_list, task) do
    {:ok, updated} -> {:ok, updated, "Added task"}
    {:error, :duplicate_task} -> {:error, "Task already exists"}
  end
  ```

- **`with` expressions for chaining operations**:
  ```elixir
  with {:ok, task_id} <- get_task_id_at_position(task_list, index),
       {:ok, done} <- TaskList.mark_task_as_done(task_list, task_id) do
    {:ok, done, "Marked task as done"}
  else
    {:error, reason} -> {:error, format_error(reason)}
  end
  ```

- **Pipe into `then/2`** for struct creation:
  ```elixir
  Enum.drop(task_list.tasks, index)
  |> then(fn tasks -> %TaskList{tasks: tasks} end)
  ```

- **Pattern match in function heads** for type safety:
  ```elixir
  def add_task_to_list(%TaskList{} = task_list, %Task{} = task)
  ```

- **Alias at module level**, not inline usage
