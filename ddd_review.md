# Domain-Driven Design Review

**Date**: 3 December 2025  
**Reviewer**: GitHub Copilot  
**Codebase**: ElixirTodo

---

## Overall Assessment

The codebase demonstrates **moderate DDD compliance** with strong architectural separation but some missing tactical patterns. The domain is simple (a todo list), so some DDD patterns may not be applicable, but there are both strengths and opportunities for improvement.

**Overall DDD Score: 2.1/5**

---

## ✅ Strengths

### 1. Domain Isolation ✓ Excellent (5/5)

The core domain (`lib/todo/core/`) is completely isolated with zero infrastructure dependencies. `Task` and `TaskList` contain only business logic with no file I/O, CLI concerns, or formatting.

```elixir
# lib/todo/core/task.ex
defmodule Todo.Core.Task do
  defstruct description: "", is_done: false
  @type t :: %__MODULE__{description: String.t(), is_done: boolean()}
end
```

**Strength**: Pure domain logic, no leaking concerns.

### 2. Ubiquitous Language ✓ Good (4/5)

Clear, business-focused terminology:
- `Task` with `description` and `is_done`
- `TaskList` with operations like `add_task_to_list`, `mark_task_as_done`, `get_not_done_tasks`
- Domain concepts are consistently named across all layers

**Minor Issue**: The term "list" is used both for the collection concept and in function names, which could be clearer (e.g., `add_task` vs `add_task_to_list`).

### 3. Dependency Direction ✓ Excellent (5/5)

Adapters depend on core domain, never the reverse. The CLI adapter imports `Todo.Core.Task` and `Todo.Core.TaskList`, maintaining proper dependency inversion.

```elixir
# lib/todo/adapters/cli.ex
defmodule Todo.Adapters.Cli do
  alias Todo.Core.Task
  alias Todo.Core.TaskList
  # ... adapter code depends on domain
end
```

### 4. Testability ✓ Good (4/5)

Domain logic is tested independently without mocks (pure functions). Adapter tests properly use Mox for behavior mocking.

```elixir
# test/todo/core/task_list_test.exs - No mocks, pure domain testing
test "adds tasks to a list", %{task_list: task_list, task: task} do
  added = TaskList.add_task_to_list(task_list, task)
  assert Enum.any?(added.tasks, fn t -> t == task end)
end
```

---

## ⚠️ Areas for DDD Improvement

### 1. Entity vs Value Object Classification - Needs Attention (1/5)

**Issue**: Both `Task` and `TaskList` are implemented as simple structs without clear identity semantics.

**Current State**:
```elixir
defmodule Todo.Core.Task do
  defstruct description: "", is_done: false
  @type t :: %__MODULE__{description: String.t(), is_done: boolean()}
end
```

**DDD Analysis**:
- **`Task` should be an Entity**: Tasks have lifecycle (created → marked done) and identity matters (which specific task was completed?). Without explicit identity, you can't distinguish between two tasks with the same description.
- **`TaskList` is ambiguous**: Could be a Value Object (immutable collection) OR an Aggregate Root (consistency boundary).

**Recommendation**:
```elixir
# Task as Entity with identity
defmodule Todo.Core.Task do
  defstruct id: nil, description: "", is_done: false
  
  @type t :: %__MODULE__{
    id: String.t(),  # UUID or similar
    description: String.t(), 
    is_done: boolean()
  }
  
  def new(description) do
    %__MODULE__{
      id: generate_id(),
      description: description,
      is_done: false
    }
  end
  
  defp generate_id, do: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
end

# TaskList as Aggregate Root
defmodule Todo.Core.TaskList do
  defstruct id: nil, tasks: []
  
  @type t :: %__MODULE__{
    id: String.t(),
    tasks: list(Task.t())
  }
end
```

**Impact**: High - This is a fundamental DDD pattern that affects domain modeling.

---

### 2. Aggregate Boundaries - Missing (1/5)

**Issue**: No clear aggregate root with transactional consistency guarantees.

**Current State**: `TaskList` acts like a collection without enforcing invariants or business rules.

**DDD Analysis**:
- Missing invariants (e.g., "task descriptions must not be empty", "can't mark already-done tasks as done again")
- No validation at the aggregate boundary
- Operations don't return domain events or validation results

**Recommendation**:
```elixir
defmodule Todo.Core.TaskList do
  # Aggregate Root
  
  def add_task(%TaskList{} = task_list, %Task{} = task) do
    with :ok <- validate_task_description(task),
         :ok <- validate_unique_description(task_list, task) do
      {:ok, %TaskList{tasks: task_list.tasks ++ [task]}}
    end
  end
  
  defp validate_task_description(%Task{description: ""}), 
    do: {:error, :empty_description}
  defp validate_task_description(_), 
    do: :ok
  
  defp validate_unique_description(%TaskList{tasks: tasks}, %Task{description: desc}) do
    if Enum.any?(tasks, fn t -> t.description == desc and not t.is_done end) do
      {:error, :duplicate_task}
    else
      :ok
    end
  end
end
```

**Impact**: High - Invariant protection is critical for maintaining domain integrity.

---

### 3. Repository Pattern - Partially Implemented (2/5)

**Issue**: `Storage` adapter exists but doesn't follow Repository pattern conventions.

**Current State**:
```elixir
defmodule Todo.Adapters.Storage do
  @behaviour Todo.Ports.Storage
  def read(%__MODULE__{} = storage) :: {:ok, TaskList.t()}
  def write(%__MODULE__{} = storage, contents) :: :ok
end
```

**DDD Issues**:
- Takes raw `contents` string instead of domain object in `write/2`
- Port definition lives in `lib/todo/ports/ports.ex` but references adapter (`alias Todo.Adapters.Storage`)
- No clear separation between "storage configuration" and "repository operations"
- Operations work with file concepts (read/write) rather than domain concepts (find/save)

**Recommendation**:
```elixir
# Port should be domain-focused
defmodule Todo.Ports.TaskListRepository do
  alias Todo.Core.TaskList
  
  @callback find_by_id(String.t()) :: {:ok, TaskList.t()} | {:error, :not_found}
  @callback save(TaskList.t()) :: {:ok, TaskList.t()} | {:error, term()}
  @callback delete(String.t()) :: :ok | {:error, term()}
end

# Adapter implements domain-focused operations
defmodule Todo.Adapters.FileSystemRepository do
  @behaviour Todo.Ports.TaskListRepository
  
  def save(%TaskList{} = task_list) do
    # Internal serialization concern - adapters handle formatting
    contents = serialize(task_list)
    # ... file operations
  end
  
  defp serialize(%TaskList{} = task_list) do
    # Adapter's responsibility to convert domain to storage format
  end
end
```

**Impact**: Medium - Repository pattern provides better abstraction for persistence.

---

### 4. Domain Services - Pattern Conflation (2/5)

**Issue**: `TaskListBehaviour` defines all operations but doesn't distinguish between application services and domain services.

**Current Operations**:
```elixir
defmodule Todo.Core.TaskListBehaviour do
  @callback add_task_to_list(TaskList.t(), Task.t()) :: TaskList.t()
  @callback mark_task_as_done(TaskList.t(), integer()) :: TaskList.t()
  @callback get_not_done_tasks(TaskList.t()) :: TaskList.t()
  @callback remove_task_from_list(TaskList.t(), integer()) :: TaskList.t()
end
```

**DDD Analysis**:
- These are appropriate for a **Domain Service** (stateless operations on domain objects)
- However, the `@behaviour` pattern suggests they're being used for DI/testing, not as a DDD domain service
- The behaviour exists primarily for mocking in tests, not for expressing domain concepts
- Creates unnecessary abstraction when there's only one implementation

**Recommendation**:

If the operations truly belong in the domain, they should be functions in the module that operate on the struct:

```elixir
# Just the module with functions - no behaviour needed for single implementation
defmodule Todo.Core.TaskList do
  # No @behaviour needed
  
  def add_task(%TaskList{} = list, %Task{} = task), do: ...
  def mark_done(%TaskList{} = list, task_id), do: ...
  def not_done_tasks(%TaskList{} = list), do: ...
end

# If you need mockability, use protocols or Mox at the adapter level, not domain
```

**Alternatively**, if you genuinely need multiple implementations:
```elixir
# This would be justified only if you had:
# - InMemoryTaskList
# - PersistentTaskList
# - DistributedTaskList
# etc.
```

**Impact**: Low - The current approach works but adds conceptual overhead.

---

### 5. Domain Events - Missing (0/5)

**Issue**: No events for tracking what happened in the domain.

**DDD Rationale**: Domain events communicate important state changes, enable event sourcing, and facilitate integration between bounded contexts.

**Recommendation**: Consider emitting events for important state changes:
```elixir
defmodule Todo.Core.Events do
  defmodule TaskAdded do
    @enforce_keys [:task_id, :description, :timestamp]
    defstruct [:task_id, :description, :timestamp]
  end
  
  defmodule TaskCompleted do
    @enforce_keys [:task_id, :timestamp]
    defstruct [:task_id, :timestamp]
  end
  
  defmodule TaskRemoved do
    @enforce_keys [:task_id, :timestamp]
    defstruct [:task_id, :timestamp]
  end
end

# In domain operations
def mark_task_as_done(%TaskList{} = list, task_id) do
  case find_task(list, task_id) do
    {:ok, task} ->
      event = %Events.TaskCompleted{
        task_id: task.id, 
        timestamp: DateTime.utc_now()
      }
      updated_list = complete_task(list, task)
      {:ok, updated_list, [event]}
    :error ->
      {:error, :task_not_found}
  end
end
```

**Use Cases**:
- Audit trail of task changes
- Integration with notification system
- Analytics and reporting
- Event sourcing (if needed in future)

**Impact**: Low for current scope, but High if system grows or needs integration.

---

### 6. Bounded Context - Implicit but Not Explicit (3/5)

**Issue**: No clear bounded context definition or context map documentation.

**Current State**: Everything lives under `Todo.*` namespace, suggesting a single bounded context.

**DDD Analysis**:
For a simple todo app, one bounded context is appropriate. However, as the system grows, you might identify:
- **Task Management Context** (current core domain)
- **Notification Context** (future: reminders, deadlines)
- **Collaboration Context** (future: shared lists, assignments)
- **Reporting Context** (future: productivity analytics)

**Recommendation**: 
1. Document the bounded context explicitly in README or architecture docs
2. Define the context boundary and what concepts belong to it
3. Create a context map showing relationships if multiple contexts emerge

```markdown
## Bounded Context: Task Management

**Responsibility**: Managing individual tasks and task lists

**Core Concepts**:
- Task (Entity): A unit of work with description and completion state
- TaskList (Aggregate Root): Collection of tasks with consistency rules

**Outside Scope**:
- User management
- Notifications/reminders
- Collaboration features
- Analytics
```

**Impact**: Low for current size, but critical as system grows.

---

### 7. Invariant Enforcement - Weak (1/5)

**Issue**: No business rule validation or invariant protection.

**Examples of Missing Invariants**:
- ✗ Can add a task with empty description
- ✗ Can mark task as done multiple times (idempotent, but no signal)
- ✗ Can mark task at index 0 (raises `OutOfBoundsError` but could be domain error)
- ✗ 1-based indexing is UI concern leaking into domain
- ✗ No maximum task list size limit
- ✗ No description length validation

**Current Code**:
```elixir
# No validation happening
def add_task_to_list(%TaskList{} = task_list, %Task{} = task) do
  task_list.tasks ++ [task]
  |> then(&(%TaskList{tasks: &1}))
end
```

**Recommendation**:
```elixir
# Domain should use task IDs, not positional indices
def mark_task_as_done(%TaskList{} = list, task_id) when is_binary(task_id) do
  case find_task(list, task_id) do
    {:ok, task} when task.is_done -> 
      {:error, :already_completed}
    {:ok, task} -> 
      {:ok, complete_task(list, task)}
    :error -> 
      {:error, :task_not_found}
  end
end

# Validate at aggregate boundary
def add_task(%TaskList{} = list, description) when is_binary(description) do
  with :ok <- validate_description(description),
       :ok <- validate_capacity(list) do
    task = Task.new(description)
    {:ok, %TaskList{tasks: list.tasks ++ [task]}}
  end
end

defp validate_description(""), do: {:error, :empty_description}
defp validate_description(desc) when byte_size(desc) > 500, do: {:error, :description_too_long}
defp validate_description(_), do: :ok

defp validate_capacity(%TaskList{tasks: tasks}) when length(tasks) >= 1000,
  do: {:error, :task_limit_reached}
defp validate_capacity(_), do: :ok
```

**Impact**: High - Invariants are the core of domain integrity.

---

### 8. Index-Based Operations - Domain Model Leak (2/5)

**Issue**: Using 1-based positional indexing in domain operations is a UI concern leaking into core domain.

**Current Code**:
```elixir
def mark_task_as_done(%TaskList{} = task_list, index) when is_integer(index) do
  case Enum.fetch(task_list.tasks, index - 1) do  # Note the -1 conversion
    :error -> raise Enum.OutOfBoundsError
    {:ok, task} -> mark_task_complete_and_create_new_task_list(task_list, task, index)
  end
end
```

**Problems**:
- Domain logic knows about UI presentation (1-based vs 0-based)
- Fragile: task order matters for identity
- Can't reorganize tasks without breaking references
- Adapter (CLI) concern bleeding into domain

**Recommendation**:
```elixir
# Domain should use stable task IDs
def mark_task_as_done(%TaskList{} = list, task_id) when is_binary(task_id) do
  # ... use task.id for lookup
end

# CLI adapter handles index-to-ID mapping
defmodule Todo.Adapters.Cli do
  defp run(%TaskList{} = task_list, [], ["done", index_str]) do
    index = String.to_integer(index_str)
    # Adapter maps UI index to domain task ID
    task_id = get_task_id_at_position(task_list, index)
    done = @task_list_module.mark_task_as_done(task_list, task_id)
    {:ok, done, "Marked task #{index} as done"}
  end
  
  defp get_task_id_at_position(%TaskList{tasks: tasks}, position) do
    # UI uses 1-based indexing
    Enum.at(tasks, position - 1).id
  end
end
```

**Impact**: Medium - Improves domain purity and flexibility.

---

## 📊 DDD Scorecard

| DDD Pattern | Status | Score | Priority |
|-------------|--------|-------|----------|
| Ubiquitous Language | ✅ Well-named concepts | 4/5 | Low |
| Bounded Context | ⚠️ Implicit, not documented | 3/5 | Low |
| Entities | ❌ Missing identity | 1/5 | **High** |
| Value Objects | ⚠️ Unclear classification | 2/5 | Medium |
| Aggregates | ❌ No aggregate root with invariants | 1/5 | **High** |
| Domain Services | ⚠️ Pattern conflated with testing | 2/5 | Low |
| Repositories | ⚠️ Exists but not DDD-aligned | 2/5 | Medium |
| Domain Events | ❌ Not implemented | 0/5 | Low |
| Invariant Protection | ❌ No validation | 1/5 | **High** |
| Domain Isolation | ✅ Excellent separation | 5/5 | ✓ Done |

**Overall DDD Score: 2.1/5**

---

## 🎯 Priority Recommendations

### High Priority (Fundamental DDD)
1. **Add identity to `Task`** (make it a proper Entity)
   - Use UUIDs or generated IDs instead of positional indices
   - Enables stable task references across operations
   
2. **Add invariant validation** to domain operations
   - Validate task descriptions (non-empty, length limits)
   - Prevent duplicate active tasks
   - Enforce business rules at aggregate boundaries

3. **Return result tuples** (`{:ok, _}` / `{:error, _}`) instead of raising exceptions
   - More idiomatic Elixir
   - Better error handling in adapters
   - Allows domain to communicate errors without exceptions

4. **Use task IDs** instead of 1-based positional indexing
   - Remove UI concerns from domain
   - Make domain operations stable and meaningful
   - Enable task reordering without breaking operations

### Medium Priority (Better DDD Alignment)
5. **Refactor `Storage` to proper Repository** pattern
   - Define domain-focused repository port (find/save/delete)
   - Move serialization concerns into adapter
   - Operate on domain objects, not strings

6. **Document bounded context** and domain model
   - Explicitly define context boundaries
   - Document core concepts and their relationships
   - Create ubiquitous language glossary

7. **Clarify Entity vs Value Object** classification
   - Make `Task` an explicit Entity with identity
   - Consider if `TaskList` should be Value Object or Aggregate Root
   - Document the design decision

8. **Remove unnecessary `TaskListBehaviour`**
   - Use module functions directly (simpler, more Elixir-idiomatic)
   - Mock at adapter boundaries, not domain logic
   - Only add behaviour if multiple implementations needed

### Low Priority (Nice to Have)
9. **Add domain events** for integration scenarios
   - Track important state changes
   - Enable audit trail and analytics
   - Prepare for future integrations

10. **Extract explicit aggregate root** concept
    - Define clear consistency boundaries
    - Document transactional guarantees
    - Consider concurrent access patterns

---

## Code Examples: Before & After

### Example 1: Entity with Identity

**Before (Missing Identity)**:
```elixir
defmodule Todo.Core.Task do
  defstruct description: "", is_done: false
end

# Two tasks with same description are indistinguishable
task1 = %Task{description: "Buy milk"}
task2 = %Task{description: "Buy milk"}
# task1 == task2  # true - but they're different tasks!
```

**After (Entity with Identity)**:
```elixir
defmodule Todo.Core.Task do
  @enforce_keys [:id, :description]
  defstruct [:id, :description, is_done: false]
  
  def new(description) do
    %__MODULE__{
      id: generate_id(),
      description: description,
      is_done: false
    }
  end
  
  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end

# Each task has unique identity
task1 = Task.new("Buy milk")
task2 = Task.new("Buy milk")
# task1.id != task2.id  # true - they're different entities
```

### Example 2: Invariant Protection

**Before (No Validation)**:
```elixir
def add_task_to_list(%TaskList{} = task_list, %Task{} = task) do
  task_list.tasks ++ [task]
  |> then(&(%TaskList{tasks: &1}))
end

# Can add invalid tasks
add_task_to_list(list, %Task{description: ""})  # Allows empty!
```

**After (Aggregate with Invariants)**:
```elixir
def add_task(%TaskList{} = list, description) when is_binary(description) do
  with :ok <- validate_description(description),
       :ok <- validate_capacity(list),
       :ok <- validate_unique(list, description) do
    task = Task.new(description)
    {:ok, %TaskList{tasks: list.tasks ++ [task]}}
  end
end

defp validate_description(""), do: {:error, :empty_description}
defp validate_description(desc) when byte_size(desc) > 500, 
  do: {:error, :description_too_long}
defp validate_description(_), do: :ok

defp validate_capacity(%TaskList{tasks: tasks}) when length(tasks) >= 1000,
  do: {:error, :task_limit_reached}
defp validate_capacity(_), do: :ok

# Now enforces business rules
add_task(list, "")  # {:error, :empty_description}
```

### Example 3: Repository Pattern

**Before (Storage-Focused)**:
```elixir
defmodule Todo.Ports.Storage do
  @callback read(Storage.t()) :: {:ok, TaskList.t()}
  @callback write(Storage.t(), String.t()) :: :ok  # Takes string!
end
```

**After (Domain-Focused Repository)**:
```elixir
defmodule Todo.Ports.TaskListRepository do
  @callback find_by_id(String.t()) :: {:ok, TaskList.t()} | {:error, :not_found}
  @callback save(TaskList.t()) :: {:ok, TaskList.t()} | {:error, term()}
  @callback list_all() :: {:ok, list(TaskList.t())}
end

# Adapter handles serialization
defmodule Todo.Adapters.FileSystemRepository do
  def save(%TaskList{} = task_list) do
    contents = serialize(task_list)  # Adapter's job
    # ... file operations
  end
end
```

---

## Final Verdict

This codebase demonstrates:

**✅ Excellent**: Architectural separation (hexagonal/ports-and-adapters)  
**⚠️ Moderate**: DDD strategic design (bounded context, ubiquitous language)  
**❌ Weak**: DDD tactical patterns (entities, aggregates, invariants)

### Key Insight

The code follows **"screaming architecture"** - it's immediately clear this is a todo application. The hexagonal architecture provides excellent boundaries and testability.

However, it leans heavily toward **functional programming with structs** rather than DDD's object-oriented heritage. This is acceptable and even preferable in Elixir, but some fundamental DDD concepts still apply:

- **Entities need identity** (works in FP with ID fields)
- **Aggregates need invariants** (works in FP with validation functions)
- **Domain operations should return results** (idiomatic Elixir with `{:ok, _}` / `{:error, _}`)

### Recommendation

For a production todo application:
1. Implement **High Priority** recommendations (entities, invariants, result tuples, task IDs)
2. Consider **Medium Priority** if system grows beyond simple usage
3. Skip **Low Priority** unless specific requirements emerge (events, multiple contexts)

The domain is simple enough that over-applying DDD tactical patterns could add unnecessary complexity. Focus on the fundamentals: entity identity, invariant protection, and clear boundaries.
