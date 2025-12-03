# Hexagonal Architecture Review

**Date**: 3 December 2025  
**Reviewer**: GitHub Copilot  
**Codebase**: ElixirTodo

---

## Overall Assessment

The codebase demonstrates **strong hexagonal architecture principles** with clear separation between domain, ports, and adapters. The dependency direction is correct, and the ports-and-adapters pattern is well-implemented. However, there are some minor violations and opportunities for improvement.

**Overall Hexagonal Architecture Score: 4.2/5**

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      External World                          │
│                                                              │
│  ┌──────────────┐                        ┌───────────────┐  │
│  │   Terminal   │                        │  File System  │  │
│  │    (User)    │                        │   (todo.txt)  │  │
│  └──────┬───────┘                        └───────┬───────┘  │
│         │                                        │          │
└─────────┼────────────────────────────────────────┼──────────┘
          │ Primary/Driving                        │ Secondary/Driven
          │                                        │
┌─────────▼────────────────────────────────────────▼──────────┐
│                    ADAPTERS (Outside)                        │
│                                                              │
│  ┌────────────────────┐              ┌──────────────────┐   │
│  │ Todo.Adapters.Cli  │              │ Todo.Adapters.   │   │
│  │                    │              │    Storage       │   │
│  │ + CliFormatter     │              │                  │   │
│  └─────────┬──────────┘              └──────────┬───────┘   │
│            │                                    │           │
└────────────┼────────────────────────────────────┼───────────┘
             │                                    │
             │ implements                implements│
             │                                    │
┌────────────▼────────────────────────────────────▼───────────┐
│                    PORTS (Boundary)                          │
│                                                              │
│  ┌────────────────┐  ┌──────────────┐  ┌────────────────┐  │
│  │  Todo.Ports.   │  │ Todo.Ports.  │  │  Todo.Ports.   │  │
│  │     Cli        │  │ CliFormatter │  │    Storage     │  │
│  └────────────────┘  └──────────────┘  └────────────────┘  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
                              │
                              │ uses
                              │
┌─────────────────────────────▼────────────────────────────────┐
│                   CORE DOMAIN (Inside)                       │
│                                                              │
│              ┌─────────────────────────────┐                 │
│              │    Todo.Core.TaskList       │                 │
│              │  (Aggregate/Domain Service) │                 │
│              │                             │                 │
│              │  + add_task_to_list        │                 │
│              │  + mark_task_as_done       │                 │
│              │  + get_not_done_tasks      │                 │
│              │  + remove_task_from_list   │                 │
│              └──────────┬──────────────────┘                 │
│                         │                                    │
│                         │ uses                               │
│                         │                                    │
│              ┌──────────▼──────────┐                         │
│              │   Todo.Core.Task    │                         │
│              │  (Domain Entity)    │                         │
│              │                     │                         │
│              │  - description      │                         │
│              │  - is_done          │                         │
│              └─────────────────────┘                         │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## ✅ Strengths

### 1. Dependency Direction ✓ Excellent (5/5)

**Perfect dependency inversion** - all dependencies flow inward toward the domain.

**Core Domain** (`lib/todo/core/`):
- ✅ Zero external dependencies
- ✅ Only aliases its own domain modules
- ✅ No knowledge of adapters, ports, or infrastructure

```elixir
# lib/todo/core/task.ex - Pure domain
defmodule Todo.Core.Task do
  defstruct description: "", is_done: false
  # No imports, no infrastructure, just data
end
```

**Adapters** (`lib/todo/adapters/`):
- ✅ Import domain modules
- ✅ Implement port behaviours
- ✅ Depend on core, never vice versa

```elixir
# lib/todo/adapters/cli.ex
defmodule Todo.Adapters.Cli do
  alias Todo.Core.Task          # ✓ Adapter depends on domain
  alias Todo.Core.TaskList
  @behaviour Todo.Ports.Cli     # ✓ Adapter implements port
```

### 2. Core Domain Isolation ✓ Excellent (5/5)

The domain is **completely independent** of all infrastructure concerns.

**No external dependencies in core**:
- ✅ No file I/O
- ✅ No CLI parsing
- ✅ No formatting logic
- ✅ No database/persistence
- ✅ Pure business logic only

This enables:
- Testing domain without any infrastructure
- Replacing adapters without touching domain
- Understanding business rules in isolation

### 3. Port Abstraction ✓ Good (4/5)

Ports define clear contracts for adapters to implement.

```elixir
defmodule Todo.Ports.Cli do
  @callback parse(TaskList.t(), {keyword(), String.t()}) :: 
    {:ok, TaskList.t(), String.t()} | {:ok, String.t()}
end

defmodule Todo.Ports.CliFormatter do
  @callback format(TaskList.t()) :: String.t()
end

defmodule Todo.Ports.Storage do
  @callback read(Storage.t()) :: {:ok, TaskList.t()}
  @callback write(Storage.t(), String.t()) :: :ok
end
```

**Strengths**:
- Clear interface contracts
- Type specifications provided
- Multiple return types for different scenarios

**Minor Issue**: See "Port Coupling" section below.

### 4. Compile-Time Dependency Injection ✓ Excellent (5/5)

Proper use of `Application.compile_env/3` for testability and flexibility.

```elixir
# lib/todo/adapters/cli.ex
@task_list_module Application.compile_env(
  :todo, 
  :task_list_module, 
  Todo.Core.TaskList  # Production default
)

@cli_formatter_module Application.compile_env(
  :todo, 
  :cli_formatter_module, 
  Todo.Adapters.CliFormatter
)
```

**Test Configuration**:
```elixir
# config/test.exs
config :todo, :task_list_module, TaskListMock
config :todo, :cli_formatter_module, CliFormatterMock
```

**Benefits**:
- ✅ Adapters can be swapped without code changes
- ✅ Tests use mocks configured at compile time
- ✅ Follows dependency inversion principle
- ✅ Clear production defaults with override capability

### 5. Clear Port Types ✓ Good (4/5)

**Primary (Driving) Ports** - User initiates action:
- `Todo.Ports.Cli` - Receives user commands
- Implemented by `Todo.Adapters.Cli`
- Direction: User → Adapter → Port → Domain

**Secondary (Driven) Ports** - Application initiates action:
- `Todo.Ports.Storage` - Application requests persistence
- `Todo.Ports.CliFormatter` - Application requests formatting
- Implemented by `Todo.Adapters.Storage` and `Todo.Adapters.CliFormatter`
- Direction: Domain → Port → Adapter → External System

This separation is conceptually correct but could be more explicit in the code organization.

### 6. Adapter Implementation ✓ Good (4/5)

All adapters properly implement their respective ports.

```elixir
# Each adapter declares its behaviour
defmodule Todo.Adapters.Cli do
  @behaviour Todo.Ports.Cli
  @impl true
  def parse(...), do: ...
end

defmodule Todo.Adapters.CliFormatter do
  @behaviour Todo.Ports.CliFormatter
  @impl true
  def format(...), do: ...
end

defmodule Todo.Adapters.Storage do
  @behaviour Todo.Ports.Storage
  @impl true
  def read(...), do: ...
  @impl true
  def write(...), do: ...
end
```

**Benefits**:
- Compiler enforces contract compliance
- Clear documentation of which port each adapter implements
- `@impl true` makes implementation explicit

---

## ⚠️ Issues & Violations

### 1. Port References Adapter - Boundary Violation (3/5)

**Issue**: `Todo.Ports.Storage` references `Todo.Adapters.Storage` - a port should not know about specific adapters.

**Current Code**:
```elixir
# lib/todo/ports/ports.ex
defmodule Todo.Ports.Storage do
  alias Todo.Adapters.Storage  # ❌ Port knows about adapter!

  @callback read(Storage.t()) :: {:ok, TaskList.t()}
  @callback write(Storage.t(), String.t()) :: :ok
end
```

**Problem**: The port interface is coupled to a specific adapter implementation. The type `Storage.t()` refers to the adapter's struct, not a domain concept.

**Impact**: 
- Can't easily swap storage adapters without changing the port
- Port is leaking implementation details
- Violates hexagonal principle of "ports owned by application"

**Recommendation**:
```elixir
# Option 1: Port uses domain-level configuration
defmodule Todo.Ports.TaskListRepository do
  alias Todo.Core.TaskList
  
  @type config :: term()  # Opaque to the port
  
  @callback read(config) :: {:ok, TaskList.t()} | {:error, term()}
  @callback write(config, TaskList.t()) :: :ok | {:error, term()}
end

# Option 2: Port doesn't take storage config at all
defmodule Todo.Ports.TaskListRepository do
  @callback find_default() :: {:ok, TaskList.t()} | {:error, :not_found}
  @callback save(TaskList.t()) :: :ok | {:error, term()}
end

# Adapter owns configuration
defmodule Todo.Adapters.FileSystemRepository do
  @behaviour Todo.Ports.TaskListRepository
  
  defstruct todo_folder: Path.expand("~"), todo_file: "todo.txt"
  
  def find_default do
    storage = %__MODULE__{}  # Adapter manages its own config
    # ... implementation
  end
end
```

**Priority**: High - This is a clear hexagonal violation.

---

### 2. Missing Application Layer - Responsibility Leak (3/5)

**Issue**: `Todo.Main` acts as both entry point AND application service, mixing infrastructure coordination with business orchestration.

**Current Code**:
```elixir
defmodule Todo.Main do
  alias Todo.Adapters.Cli
  alias Todo.Adapters.Storage  # ❌ Entry point knows about adapters

  def main(args \\ []) do
    args |> parse |> IO.puts
  end

  defp parse(args) do
    {opts, word, _} = args |> OptionParser.parse(switches: [not_done: :boolean])
    storage = %Storage{}
    {:ok, task_list} = Storage.read(storage)
    command = Enum.join(word, " ")

    case Cli.parse(task_list, {opts, command}) do
      {:ok, updated, desc} ->
        Storage.write(storage, updated)  # ❌ Main orchestrates storage
        desc
      {:ok, listed} ->
        listed
    end
  end
end
```

**Problems**:
- Entry point (`main/1`) directly calls adapters
- No clear application service layer
- Orchestration logic (read → parse → write) is in the entry point
- Hard to test the orchestration without running the full CLI

**Hexagonal Principle Violated**: The application layer should orchestrate domain and ports, keeping the entry point thin.

**Recommendation**:
```elixir
# New: Application service layer
defmodule Todo.Application.TaskListService do
  @storage_adapter Application.compile_env(:todo, :storage_adapter, Todo.Adapters.FileSystemRepository)
  @cli_adapter Application.compile_env(:todo, :cli_adapter, Todo.Adapters.Cli)

  def execute_command(command_string, opts \\ []) do
    with {:ok, task_list} <- @storage_adapter.read(),
         {:ok, result} <- @cli_adapter.parse(task_list, {opts, command_string}),
         :ok <- maybe_persist(result) do
      format_response(result)
    end
  end

  defp maybe_persist({:updated, task_list}), do: @storage_adapter.write(task_list)
  defp maybe_persist(_), do: :ok

  defp format_response({:updated, _task_list, message}), do: {:ok, message}
  defp format_response({:display, formatted}), do: {:ok, formatted}
end

# Thin entry point
defmodule Todo.Main do
  alias Todo.Application.TaskListService

  def main(args \\ []) do
    {opts, words, _} = OptionParser.parse(args, switches: [not_done: :boolean])
    command = Enum.join(words, " ")
    
    case TaskListService.execute_command(command, opts) do
      {:ok, output} -> IO.puts(output)
      {:error, reason} -> IO.puts("Error: #{reason}")
    end
  end
end
```

**Benefits**:
- Clear separation: entry point vs application logic
- Testable orchestration without CLI infrastructure
- Single responsibility for each layer
- Follows hexagonal "application service" pattern

**Priority**: Medium - Works but not ideal hexagonal structure.

---

### 3. Storage Adapter Takes String Instead of Domain Object (2/5)

**Issue**: `Todo.Ports.Storage.write/2` callback takes a `String.t()` instead of a domain object.

**Current Code**:
```elixir
defmodule Todo.Ports.Storage do
  @callback write(Storage.t(), String.t()) :: :ok
  #                              ^^^^^^^^^ Should be TaskList.t()
end

# In Todo.Main
Storage.write(storage, updated)  # `updated` is a formatted string
```

**Problem**: The port interface requires adapters to receive pre-formatted strings rather than domain objects. This means:
- Formatting happens BEFORE persistence (in the CLI adapter)
- Storage can't serialize domain objects independently
- Different storage adapters can't choose their own format
- Violates single responsibility (storage shouldn't care about string format)

**Hexagonal Violation**: Ports should operate on domain concepts, not presentation formats.

**Recommendation**:
```elixir
defmodule Todo.Ports.TaskListRepository do
  alias Todo.Core.TaskList
  
  @callback read(config) :: {:ok, TaskList.t()}
  @callback write(config, TaskList.t()) :: :ok  # ✓ Domain object
end

# Adapter handles serialization internally
defmodule Todo.Adapters.FileSystemRepository do
  def write(config, %TaskList{} = task_list) do
    contents = serialize_to_text(task_list)  # Adapter's choice
    File.write!(path, contents)
  end
  
  defp serialize_to_text(%TaskList{tasks: tasks}) do
    # Adapter owns the serialization format
    tasks
    |> Enum.with_index(1)
    |> Enum.map_join("\n", fn {task, idx} ->
      done = if task.is_done, do: " ✓", else: ""
      "#{idx}. #{task.description}#{done}"
    end)
  end
end
```

**Priority**: Medium - Works but limits flexibility.

---

### 4. Port Organization - All in One File (3/5)

**Issue**: All ports are defined in a single `lib/todo/ports/ports.ex` file with nested modules.

**Current Structure**:
```elixir
# lib/todo/ports/ports.ex
defmodule Todo.Ports do
  defmodule Cli do ... end
  defmodule CliFormatter do ... end
  defmodule Storage do ... end
end
```

**Problems**:
- Harder to navigate as ports grow
- Mixing primary and secondary ports in one namespace
- Less clear separation of concerns
- Difficult to see port relationships at a glance

**Recommendation**:
```
lib/todo/ports/
  ├── primary/
  │   └── cli.ex                    # Driving port
  └── secondary/
      ├── task_list_repository.ex   # Driven port
      └── task_formatter.ex         # Driven port
```

```elixir
# lib/todo/ports/primary/cli.ex
defmodule Todo.Ports.Primary.Cli do
  alias Todo.Core.TaskList
  @callback parse(TaskList.t(), {keyword(), String.t()}) :: result
end

# lib/todo/ports/secondary/task_list_repository.ex
defmodule Todo.Ports.Secondary.TaskListRepository do
  alias Todo.Core.TaskList
  @callback find_default() :: {:ok, TaskList.t()}
  @callback save(TaskList.t()) :: :ok
end
```

**Benefits**:
- Explicit primary vs secondary port separation
- Clearer file structure matches architectural intent
- Easier to locate specific ports
- Better scalability as system grows

**Priority**: Low - Organizational preference, works fine as-is for small project.

---

### 5. CliFormatter as Secondary Port - Questionable Classification (3/5)

**Issue**: `CliFormatter` is treated as a secondary (driven) port, but it's arguably part of the CLI adapter's responsibility.

**Current Structure**:
```
Todo.Adapters.Cli → uses → Todo.Ports.CliFormatter ← implements ← Todo.Adapters.CliFormatter
```

**Analysis**:
- Formatting is specific to CLI presentation
- No other adapter would need `CliFormatter`
- It's not a "port to the outside world" - it's an internal adapter concern

**Questions**:
- Would a web adapter use `CliFormatter`? No - it would have its own JSON formatter
- Would a GUI adapter use `CliFormatter`? No - it would render differently
- Is formatting a domain concern? No - it's presentation

**Hexagonal Principle**: Ports represent points where the application boundary crosses to external systems. Formatting is internal to the CLI adapter.

**Recommendation**:

**Option 1: Move formatter into CLI adapter (simpler)**
```elixir
defmodule Todo.Adapters.Cli do
  # ... CLI logic
  
  defp format_task_list(%TaskList{tasks: tasks}) do
    # Formatting is internal to the CLI adapter
    tasks
    |> Enum.with_index(1)
    |> Enum.map_join("\n", &format_task/1)
  end
  
  defp format_task({%Task{description: desc, is_done: true}, idx}),
    do: "#{idx}. #{desc} ✓"
  defp format_task({%Task{description: desc}, idx}),
    do: "#{idx}. #{desc}"
end
```

**Option 2: Keep as port if multiple presenters exist**
If you plan to have multiple output formats (CLI text, CLI colored, CLI JSON), then a port makes sense:
```elixir
defmodule Todo.Ports.Secondary.TaskListPresenter do
  @callback present(TaskList.t()) :: String.t()
end

# Then have multiple adapters:
# - Todo.Adapters.Presenters.PlainText
# - Todo.Adapters.Presenters.ColoredText
# - Todo.Adapters.Presenters.Json
```

**Current Verdict**: For a simple CLI app, the formatter port adds unnecessary abstraction. It should be internal to the CLI adapter.

**Priority**: Low - Works fine, but adds conceptual overhead.

---

### 6. No Error Handling at Port Boundaries (2/5)

**Issue**: Ports don't consistently define error cases in their contracts.

**Current Examples**:
```elixir
# Returns only success cases
@callback format(TaskList.t()) :: String.t()

# Returns tuple but no error case
@callback read(Storage.t()) :: {:ok, TaskList.t()}

# Could this fail? Not documented
@callback parse(TaskList.t(), {keyword(), String.t()}) :: 
  {:ok, TaskList.t(), String.t()} | {:ok, String.t()}
```

**Problems**:
- What happens if `format/1` receives invalid input?
- What if `read/1` fails (file not found, permissions, corrupt data)?
- What if `parse/2` receives malformed command?

**Hexagonal Principle**: Ports should explicitly define failure modes to help adapters implement proper error handling.

**Recommendation**:
```elixir
defmodule Todo.Ports.Secondary.TaskListRepository do
  @callback read(config) :: 
    {:ok, TaskList.t()} 
    | {:error, :not_found} 
    | {:error, :permission_denied}
    | {:error, :invalid_format}
    
  @callback write(config, TaskList.t()) :: 
    :ok 
    | {:error, :permission_denied}
    | {:error, :disk_full}
end

defmodule Todo.Ports.Primary.Cli do
  @callback parse(TaskList.t(), {keyword(), String.t()}) :: 
    {:ok, TaskList.t(), String.t()}  # Success with update
    | {:ok, String.t()}              # Success with display
    | {:error, :invalid_command}     # Unknown command
    | {:error, :invalid_arguments}   # Bad args
end
```

**Priority**: Medium - Important for production robustness.

---

## 📊 Hexagonal Architecture Scorecard

| Principle | Status | Score | Priority |
|-----------|--------|-------|----------|
| Dependency Direction | ✅ Perfect inward flow | 5/5 | ✓ Done |
| Core Domain Isolation | ✅ Zero infrastructure | 5/5 | ✓ Done |
| Port Abstraction | ✅ Clear contracts | 4/5 | Low |
| Adapter Implementation | ✅ Proper @behaviour | 4/5 | Low |
| Compile-Time DI | ✅ Excellent testability | 5/5 | ✓ Done |
| Primary/Secondary Separation | ⚠️ Implicit, not explicit | 4/5 | Low |
| Port Independence | ❌ Storage port refs adapter | 2/5 | **High** |
| Application Layer | ⚠️ Mixed into Main | 3/5 | Medium |
| Port-Adapter Decoupling | ⚠️ Storage takes String | 3/5 | Medium |
| Port Organization | ⚠️ Single file | 3/5 | Low |
| Formatter as Port | ⚠️ Questionable need | 3/5 | Low |
| Error Handling | ⚠️ Inconsistent contracts | 2/5 | Medium |

**Overall Hexagonal Score: 4.2/5**

---

## 🎯 Priority Recommendations

### High Priority (Core Hexagonal Violations)

1. **Fix Port-Adapter Reference in Storage Port**
   - Remove `alias Todo.Adapters.Storage` from `Todo.Ports.Storage`
   - Make port truly independent of adapter implementation
   - Use generic config type or remove config from port entirely

```elixir
# Before
defmodule Todo.Ports.Storage do
  alias Todo.Adapters.Storage  # ❌
  @callback read(Storage.t()) :: {:ok, TaskList.t()}
end

# After
defmodule Todo.Ports.TaskListRepository do
  alias Todo.Core.TaskList
  @callback find_default() :: {:ok, TaskList.t()} | {:error, term()}
  @callback save(TaskList.t()) :: :ok | {:error, term()}
end
```

### Medium Priority (Better Hexagonal Alignment)

2. **Extract Application Service Layer**
   - Move orchestration logic out of `Todo.Main`
   - Create `Todo.Application.TaskListService` to coordinate domain and adapters
   - Keep entry point thin and focused on I/O

3. **Make Storage Port Accept Domain Objects**
   - Change `write(config, String.t())` to `write(config, TaskList.t())`
   - Move serialization into adapter implementation
   - Let each adapter choose its own format

4. **Add Error Cases to Port Contracts**
   - Define explicit failure modes in all `@callback` specs
   - Document what errors adapters must handle
   - Improve robustness and adapter implementation clarity

### Low Priority (Nice to Have)

5. **Reorganize Ports by Primary/Secondary**
   - Split ports into `lib/todo/ports/primary/` and `lib/todo/ports/secondary/`
   - Makes architectural intent more explicit
   - Better scalability as system grows

6. **Reconsider CliFormatter as Separate Port**
   - Evaluate if formatter truly needs to be swappable
   - If only used by CLI, merge into CLI adapter
   - If multiple presenters needed, keep as port

---

## Architecture Compliance Table

### ✅ Hexagonal Principles Applied

| Principle | Implementation |
|-----------|----------------|
| **Dependency Inversion** | All dependencies flow toward domain; adapters never imported by core |
| **Port-Adapter Pattern** | Ports defined as behaviours; adapters implement them |
| **Testability** | Compile-time DI allows mock injection in tests |
| **Business Logic Isolation** | Domain is pure functions with no infrastructure |
| **Pluggable Adapters** | Adapters can be swapped via configuration |

### ⚠️ Hexagonal Violations

| Violation | Location | Impact |
|-----------|----------|--------|
| **Port references adapter** | `Todo.Ports.Storage` aliases `Todo.Adapters.Storage` | High - breaks port independence |
| **Missing application layer** | Orchestration in `Todo.Main` entry point | Medium - mixing concerns |
| **Port takes presentation format** | `Storage.write/2` takes `String.t()` | Medium - limits adapter flexibility |
| **Inconsistent error handling** | Ports don't define all error cases | Medium - unclear adapter contracts |

---

## Dependency Graph

### Current Dependencies (Simplified)

```
Main
 ├─→ Adapters.Cli
 ├─→ Adapters.Storage
 └─→ IO (Elixir stdlib)

Adapters.Cli
 ├─→ Ports.Cli (@behaviour)
 ├─→ Core.Task (alias)
 ├─→ Core.TaskList (alias)
 └─→ Adapters.CliFormatter (DI)

Adapters.CliFormatter
 ├─→ Ports.CliFormatter (@behaviour)
 ├─→ Core.Task (alias)
 └─→ Core.TaskList (alias)

Adapters.Storage
 ├─→ Ports.Storage (@behaviour)
 ├─→ Core.Task (alias)
 └─→ Core.TaskList (alias)

Ports.Storage ❌
 ├─→ Core.TaskList (alias) ✓
 └─→ Adapters.Storage (alias) ❌ VIOLATION

Core.TaskList
 ├─→ Core.TaskListBehaviour (@behaviour)
 └─→ Core.Task (alias)

Core.Task
 └─→ (no dependencies) ✓
```

**Key Observation**: The only backward dependency is `Ports.Storage → Adapters.Storage`. Removing this would achieve perfect hexagonal architecture.

---

## Recommended Architecture

### Ideal Hexagonal Structure

```
lib/todo/
├── core/                          # Domain (center of hexagon)
│   ├── task.ex                    # Entity
│   └── task_list.ex               # Aggregate/Domain Service
│
├── application/                   # Application services (orchestration)
│   └── task_list_service.ex      # Use-case orchestration
│
├── ports/                         # Application boundary
│   ├── primary/                   # Driving ports (user → app)
│   │   └── cli_command_handler.ex
│   └── secondary/                 # Driven ports (app → external)
│       ├── task_list_repository.ex
│       └── task_presenter.ex      # Optional if multiple formats
│
└── adapters/                      # External world implementations
    ├── primary/
    │   └── cli.ex                 # Terminal interface
    ├── secondary/
    │   ├── file_system_repository.ex
    │   └── plain_text_presenter.ex
    └── main.ex                    # Entry point (composition root)
```

### Data Flow

```
User Input
    │
    ▼
┌─────────────────────────────────────┐
│  Adapter: CLI                       │  Parse args, create domain request
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│  Application: TaskListService       │  Orchestrate use-case
└─────────────────────────────────────┘
    │
    ├─→ Domain: TaskList.add_task()   │  Business logic
    │
    ├─→ Port: Repository.save()       │  Request persistence
    │       │
    │       ▼
    │   Adapter: FileSystemRepository  │  Serialize & write
    │
    └─→ Port: Presenter.present()     │  Request formatting
            │
            ▼
        Adapter: PlainTextPresenter    │  Format for CLI
```

---

## Code Examples: Before & After

### Example 1: Port Independence

**Before (Port coupled to adapter)**:
```elixir
defmodule Todo.Ports.Storage do
  alias Todo.Adapters.Storage  # ❌ Port knows about adapter
  
  @callback read(Storage.t()) :: {:ok, TaskList.t()}
  @callback write(Storage.t(), String.t()) :: :ok
end
```

**After (Port independent)**:
```elixir
defmodule Todo.Ports.Secondary.TaskListRepository do
  alias Todo.Core.TaskList
  
  @type config :: term()  # Opaque - adapter decides structure
  
  @callback read(config) :: {:ok, TaskList.t()} | {:error, term()}
  @callback write(config, TaskList.t()) :: :ok | {:error, term()}
end

# Adapter owns its configuration
defmodule Todo.Adapters.Secondary.FileSystemRepository do
  @behaviour Todo.Ports.Secondary.TaskListRepository
  
  defstruct todo_folder: Path.expand("~"), todo_file: "todo.txt"
  
  @impl true
  def read(%__MODULE__{} = config) do
    # Adapter controls its own structure
  end
end
```

---

### Example 2: Application Service Layer

**Before (Orchestration in entry point)**:
```elixir
defmodule Todo.Main do
  def main(args) do
    {opts, word, _} = OptionParser.parse(args, switches: [not_done: :boolean])
    storage = %Storage{}
    {:ok, task_list} = Storage.read(storage)
    command = Enum.join(word, " ")
    
    case Cli.parse(task_list, {opts, command}) do
      {:ok, updated, desc} ->
        Storage.write(storage, updated)
        desc
      {:ok, listed} -> listed
    end
    |> IO.puts
  end
end
```

**After (Application service orchestrates)**:
```elixir
defmodule Todo.Application.TaskListService do
  @repository Application.compile_env(
    :todo, :repository, 
    Todo.Adapters.Secondary.FileSystemRepository
  )
  
  def execute_command(command_string, opts \\ []) do
    config = %@repository{}
    
    with {:ok, task_list} <- @repository.read(config),
         {:ok, result} <- parse_and_execute(task_list, command_string, opts),
         :ok <- persist_if_needed(config, result) do
      {:ok, format_result(result)}
    end
  end
  
  defp persist_if_needed(config, {:updated, task_list, _msg}) do
    @repository.write(config, task_list)
  end
  defp persist_if_needed(_config, _), do: :ok
end

# Thin entry point
defmodule Todo.Main do
  alias Todo.Application.TaskListService
  
  def main(args) do
    {opts, words, _} = OptionParser.parse(args, switches: [not_done: :boolean])
    command = Enum.join(words, " ")
    
    case TaskListService.execute_command(command, opts) do
      {:ok, output} -> IO.puts(output)
      {:error, reason} -> IO.puts("Error: #{inspect(reason)}")
    end
  end
end
```

---

### Example 3: Domain Objects in Ports

**Before (Port takes presentation format)**:
```elixir
@callback write(Storage.t(), String.t()) :: :ok

# In adapter
Storage.write(storage, formatted_string)  # Already formatted!
```

**After (Port takes domain object)**:
```elixir
@callback write(config, TaskList.t()) :: :ok | {:error, term()}

# In adapter
defmodule Todo.Adapters.Secondary.FileSystemRepository do
  @impl true
  def write(%__MODULE__{} = config, %TaskList{} = task_list) do
    contents = serialize(task_list)  # Adapter chooses format
    path = Path.join(config.todo_folder, config.todo_file)
    
    case File.write(path, contents) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
  
  # Serialization is adapter's responsibility
  defp serialize(%TaskList{tasks: tasks}) do
    tasks
    |> Enum.with_index(1)
    |> Enum.map_join("\n", fn {task, idx} ->
      done_marker = if task.is_done, do: " ✓", else: ""
      "#{idx}. #{task.description}#{done_marker}"
    end)
  end
end
```

---

## Final Verdict

### Summary

This codebase demonstrates **strong hexagonal architecture fundamentals** with minor violations:

**✅ Excellent (5/5)**:
- Dependency direction (all flow inward)
- Core domain isolation (zero infrastructure)
- Compile-time DI (perfect testability)

**✅ Good (4/5)**:
- Port abstraction (clear contracts)
- Adapter implementation (proper behaviours)
- Primary/secondary separation (conceptually correct)

**⚠️ Needs Improvement (2-3/5)**:
- Port-adapter coupling (Storage port refs adapter)
- Application layer (orchestration in Main)
- Port data types (takes String instead of domain object)
- Error handling (incomplete contracts)

### Key Strengths

1. **Clean dependency graph** - Near-perfect hexagonal structure
2. **Testability** - Easy to swap implementations
3. **Domain purity** - Business logic completely isolated
4. **Explicit contracts** - Behaviours make adapter requirements clear

### Critical Fixes Needed

1. Remove `alias Todo.Adapters.Storage` from `Todo.Ports.Storage`
2. Extract application service layer from `Todo.Main`
3. Make storage port operate on domain objects, not strings

### Overall Recommendation

For a simple todo CLI application, this architecture is **well-structured and maintainable**. The hexagonal principles are mostly well-applied, with only a few violations that should be addressed for production use.

The architecture would scale well to additional adapters (web API, GUI, different storage backends) with minimal changes - a key goal of hexagonal architecture.

**Recommended Path Forward**:
1. Fix high-priority violations (port independence, application layer)
2. Add comprehensive error handling to ports
3. Consider the medium-priority improvements if the system grows
4. Keep the excellent dependency direction and domain isolation
