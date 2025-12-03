# Refactoring Plan

**Date**: 3 December 2025  
**Branch**: main (completed work merged from core/add-id-to-task)

---

## Overview

This plan addresses architectural improvements identified in the DDD, Hexagonal Architecture, and Elixir Idioms reviews. Changes are ordered by dependencies and grouped logically.

---

## ✅ Phase 1: Task Identity & Domain Improvements (COMPLETED)

### ✅ 1.1 Add ID field to Task (hash-based) - COMPLETED

**Goal**: Give tasks unique identity using SHA-256 hash of description

**Changes**:
- ✅ `lib/todo/core/task.ex`:
  - Updated `@enforce_keys` to `[:id, :description]`
  - Added `id` field to struct
  - Updated type spec to include `id: String.t()`
  - Added `Task.new/1` and `Task.new/2` functions that generate ID from description hash
  - Uses `:crypto.hash(:sha256, description) |> Base.encode16(case: :lower)`

**Benefits**:
- Unique identity for each task
- Natural deduplication (same description = same ID)
- Deterministic (reproducible across sessions)
- Enables stable task references

---

### ✅ 1.2 Update TaskList to use task IDs instead of indices - COMPLETED

**Goal**: Domain operations use stable IDs, not fragile positional indices

**Changes**:
- ✅ `lib/todo/core/task_list.ex`:
  - Updated `TaskListBehaviour` callbacks:
    - `mark_task_as_done(TaskList.t(), String.t())` - task_id instead of integer
    - `remove_task_from_list(TaskList.t(), String.t())` - task_id instead of integer
  - Implemented `find_task_by_id/2` helper function
  - Updated `mark_task_as_done/2` to find task by ID using `Enum.map`
  - Updated `remove_task_from_list/2` to filter by ID using `Enum.reject/2`
- ✅ Updated all tests to use task IDs instead of indices

**Benefits**:
- Domain operations are stable (don't break when tasks reorder)
- Removes 1-based indexing concern from domain (UI-only)
- Better alignment with DDD Entity pattern

---

### ✅ 1.3 Update CLI adapter to map indices to task IDs - COMPLETED

**Goal**: Keep 1-based indexing for user display, but convert to task IDs for domain calls

**Changes**:
- ✅ `lib/todo/adapters/cli.ex`:
  - Added helper function `get_task_id_at_position(task_list, index)` 
    - Takes 1-based index from user
    - Returns `{:ok, task_id}` or `{:error, :task_not_found}`
  - Updated `run/3` for "done" command:
    - Parse index from user input
    - Call `get_task_id_at_position/2` to get task_id
    - Handle error case with `{:error, "Task #{index} not found"}`
    - Pass task_id to `mark_task_as_done/2`
  - Updated `run/3` for "remove" command similarly
  - Updated `run/3` for "add" command to use `Task.new/1`
  - Added `format_result/1` clause to handle `{:error, message}` tuples
- ✅ Updated CLI tests to verify error handling
- ✅ Updated Main to handle `{:error, message}` from CLI

**Benefits**:
- UI still shows familiar 1-based indices
- Domain layer only deals with stable IDs
- Clear separation of concerns (presentation vs domain)
- Graceful error handling for invalid indices

---

## Phase 2: Hexagonal Architecture Fixes

### 2.1 Update Storage port to use domain concepts and define error cases

**Goal**: Use domain terminology and specify error cases for invariant violations

**Changes**:
- `lib/todo/ports/ports.ex`:
  - Remove `alias Todo.Adapters.Storage` from `Todo.Ports.Storage`
  - Rename callbacks to use domain concepts (not file concepts):
    - `@callback get(config) :: {:ok, TaskList.t()} | {:error, :file_error}` (was `read`)
    - `@callback save(config, TaskList.t()) :: :ok | {:error, :write_failed}` (was `write`)
  - Add type: `@type config :: term()`
  - Add documentation explaining config is opaque
  - Define error cases that align with domain invariants

**Benefits**:
- Port is independent of specific adapter implementation
- Could swap in PostgresStorage, S3Storage, etc. with different config structures
- Domain-focused naming (get/save) instead of infrastructure naming (read/write)
- Clear error contract for adapters to implement

---

### 2.2 Update Storage adapter to accept TaskList domain objects

**Goal**: Storage adapter works with domain objects, handles its own serialization

**Changes**:
- `lib/todo/adapters/storage.ex`:
  - Rename methods to match port (domain concepts):
    - `read/1` → `get/1`
    - `write/2` → `save/2`
  - Update `@behaviour` implementation to match new port signature
  - Change `save/2` to accept `TaskList.t()` instead of `String.t()`
  - Add compile-time DI for CliFormatter:
    ```elixir
    @formatter Application.compile_env(:todo, :formatter_module, Todo.Adapters.CliFormatter)
    ```
  - Call `@formatter.format/1` inside `save/2` before writing to file
  - Keep `get/1` signature but ensure it returns `{:ok, TaskList.t()}`
  - Update serialization to include task IDs in file format (for persistence)

**Benefits**:
- Storage operates on domain concepts, not strings
- Domain-focused naming aligns with repository pattern
- Serialization is adapter's responsibility
- Different storage adapters could use different formats (JSON, binary, etc.)

---

### 2.3 Update Main to use new Storage method names

**Goal**: Main uses domain-focused storage operations

**Changes**:
- `lib/todo/main.ex`:
  - Update calls to use new method names:
    - `Storage.read(storage)` → `Storage.get(storage)`
    - `Storage.write(storage, updated)` → `Storage.save(storage, updated)`
  - Update `parse/1` to pass task_list (not formatted string) to `Storage.save/2`
  - Remove any formatting concerns from Main
  - Pattern match should be:
    ```elixir
    {:ok, updated, desc} ->
      Storage.save(storage, updated)  # updated is TaskList, not String
      desc
    ```

**Benefits**:
- Clearer separation of concerns
- Main doesn't need to know about formatting
- Consistent domain object flow
- Domain-focused vocabulary throughout

---

## Phase 3: Update Tests

### 3.1 Update Task tests

**Changes**:
- `test/todo/core/task_test.exs`:
  - Update test for `@enforce_keys` to include `:id`
  - Add test for `Task.new/1`:
    - Verify it generates an ID
    - Verify same description produces same ID
    - Verify different descriptions produce different IDs
  - Update any direct struct creation to use `Task.new/1`

---

### 3.2 Update TaskList tests

**Changes**:
- `test/todo/core/task_list_test.exs`:
  - Update all task creation to use `Task.new/1`
  - Update `mark_task_as_done` tests to pass task_id instead of index
  - Update `remove_task_from_list` tests to pass task_id instead of index
  - Add test for error case when task_id not found
  - Verify operations work with task IDs

---

### 3.3 Update CLI tests

**Changes**:
- `test/todo/adapters/cli_test.exs`:
  - Update mocks to expect task IDs instead of indices
  - Update expectations for `mark_task_as_done` calls
  - Update expectations for `remove_task_from_list` calls
  - Verify CLI still shows 1-based indices to users
  - Verify CLI converts indices to task IDs before domain calls

---

### 3.4 Update Storage tests

**Changes**:
- `test/todo/adapters/storage_test.exs`:
  - Update all method names:
    - `Storage.read(storage)` → `Storage.get(storage)`
    - `Storage.write(storage, ...)` → `Storage.save(storage, ...)`
  - Update all task creation to use `Task.new/1`
  - Update `save/2` tests to pass `TaskList.t()` instead of strings
  - Add mock for CliFormatter if needed for formatting
  - Verify serialization includes task IDs
  - Verify deserialization reconstructs task IDs correctly
  - Update test file format to include IDs in lines

---

## Phase 4: Add Invariant Validation (TaskList as Consistency Boundary)

### 4.1 Return result tuples instead of raising exceptions

**Goal**: Domain operations communicate errors through return values, not exceptions

**Changes**:
- `lib/todo/core/task_list.ex`:
  - Update all public functions to return `{:ok, TaskList.t()}` or `{:error, atom()}`
  - `add_task_to_list/2` → `{:ok, TaskList.t()}` (always succeeds after validation)
  - `mark_task_as_done/2` → `{:ok, TaskList.t()} | {:error, :task_not_found | :already_done}`
  - `remove_task_from_list/2` → `{:ok, TaskList.t()} | {:error, :task_not_found}`
  - Remove `raise` statements, return error tuples instead

**Benefits**:
- More idiomatic Elixir
- Adapters can handle errors gracefully
- Clearer contract about what can fail

---

### 4.2 Add validation at TaskList boundary

**Goal**: TaskList enforces business rules as a consistency boundary

**Changes**:
- `lib/todo/core/task_list.ex`:
  - Add `validate_not_duplicate/2` - Prevent duplicate tasks by ID
  - Call validation in `add_task_to_list/2` before adding
  - Task description validation already handled by `Task.new/1` via `@enforce_keys`

**Example**:
```elixir
def add_task_to_list(%TaskList{} = task_list, %Task{} = task) do
  with :ok <- validate_not_duplicate(task_list, task) do
    tasks = task_list.tasks ++ [task]
    {:ok, %TaskList{tasks: tasks}}
  end
end

defp validate_not_duplicate(%TaskList{tasks: tasks}, %Task{id: id}) do
  if Enum.any?(tasks, fn t -> t.id == id end),
    do: {:error, :duplicate_task},
    else: :ok
end
```

**Benefits**:
- Prevents duplicate tasks in the list
- Task-level validation delegated to Task module
- Clear validation failures

---

### 4.3 Update adapters and tests for new error handling

**Changes**:
- Update CLI adapter to handle `{:ok, _}` / `{:error, _}` returns
- Update Main to pattern match on result tuples
- Update all tests to expect result tuples
- Add tests for error cases (duplicate task, task not found, etc.)

---

## Phase 5: Optional Improvements (Defer)

### 5.1 Add concurrency with GenServers/message passing (fun learning project!)

**Goal**: Learn OTP patterns by making the app concurrent and event-driven

**Phase 5.1a - Basic GenServer Implementation**:
- Create `TaskListServer` GenServer to manage task list state
- Create `StorageServer` GenServer for async file I/O
- Replace direct function calls with GenServer messages
- Add supervision tree with `Application` supervisor

**Phase 5.1b - Event Infrastructure**:
- Add `EventBus` using `Phoenix.PubSub` or `Registry`
- Emit infrastructure-level events (not domain events):
  - `:task_added`, `:task_completed`, `:task_removed`
- `StorageServer` subscribes to events for auto-save
- Keep domain pure (no event emission in TaskList module)

**Example Flow**:
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

**Learning Objectives**:
- GenServer state management
- Supervision trees
- PubSub patterns
- Async message passing
- Process linking and monitoring
- Event-driven architecture

**Note**: Total overkill for CLI app, but excellent for learning Elixir/OTP!

### 5.2 Use `%__MODULE__{}` consistently within modules (code polish)

**Goal**: Use `%__MODULE__{}` instead of explicit struct names within their own modules for better maintainability

**Changes**:
- `lib/todo/core/task_list.ex`:
  - Replace `%TaskList{tasks: tasks}` with `%__MODULE__{tasks: tasks}` in all struct constructions
  - Keep `%TaskList{}` in function parameters (pattern matching on type from outside)
- `lib/todo/core/task.ex`:
  - Replace `%Task{...}` with `%__MODULE__{...}` in struct constructions within the module
  - Keep `%Task{}` in function parameters

**Benefits**:
- Easier refactoring if module names change
- Consistent with `@type t :: %__MODULE__{...}` pattern
- Common Elixir idiom

**Priority**: Very Low - Minor code polish, no functional impact

### 5.3 Document bounded context in README
- Add section to README documenting the implicit bounded context
- Define what's in scope (task management) and out of scope (notifications, collaboration, analytics)
- Simple documentation, no need for complex context mapping

### 5.4 Document domain model (optional)
- Create `docs/domain_model.md` if detailed documentation is desired
- Document entity vs value object decisions
- Document ubiquitous language
- Create `docs/domain_model.md`
- Document bounded context
- Document entity vs value object decisions
- Document ubiquitous language

---

## Implementation Order & Status

1. ✅ **Phase 1.1**: Add Task ID field - COMPLETED
2. ✅ **Phase 1.2**: Update TaskList to use IDs - COMPLETED
3. ✅ **Phase 1.3**: Update CLI adapter - COMPLETED
4. ⏭️ **Phase 2.1**: Fix port-adapter coupling - NEXT
5. ⏭️ **Phase 2.2**: Update Storage to use TaskList
6. ⏭️ **Phase 2.3**: Update Main  
7. ⏭️ **Phase 3**: Update all tests
8. ⏭️ **Phase 4**: Add invariant validation
9. ⏭️ **Phase 5**: Documentation & optional features (defer unless needed)
7. **Phase 3**: Update all tests ✓ Verify everything works
8. **Phase 4**: Add invariant validation ✓ Domain integrity (addresses DDD critiques 7 & 8)
9. **Phase 5**: Documentation & optional features (defer unless needed)

---

## Testing Strategy

After each phase:
1. Run `mix test` to catch immediate breakage
2. Fix compilation errors before moving to next phase
3. Update tests incrementally with implementation

Final verification:
```bash
mix test
mix compile --warnings-as-errors
```

---

## Rollback Plan

Each phase should be committed separately:
```bash
git add -p  # Stage specific changes
git commit -m "Phase 1.1: Add Task ID field"
```

If issues arise, can revert specific commits without losing all progress.

---

## Notes

- **Task ID hash**: Using SHA-256 of description provides deterministic IDs
- **No application layer**: User chose to keep Main calling adapters directly
- **CliFormatter is shared**: Both CLI adapter (for display) and Storage adapter (for file serialization) use CliFormatter. Not purely an internal concern - it's the serialization format.
- **Index → ID mapping**: CLI adapter's responsibility to translate user input
- **Domain-focused naming**: Storage uses `get`/`save` instead of `read`/`write` to reflect domain concepts, not file operations
- **TaskList as Value Object**: TaskList is implemented as a Value Object (immutable collection) rather than an Aggregate Root. The current system manages a single todo list without needing TaskList identity. If future requirements demand multiple named lists ("Work Tasks", "Personal Tasks"), TaskList could be promoted to an Aggregate Root with an `id` field, but this is not currently justified by the domain.
- **TaskList as Consistency Boundary**: Even though TaskList is a Value Object, it still acts as a consistency boundary enforcing invariants on its contained tasks (no duplicates, validation rules, capacity limits). This follows DDD principles where aggregates protect business rules.
- **Keep TaskListBehaviour**: The behaviour remains for test isolation and dependency injection, following common Elixir patterns. While not a pure DDD Domain Service, it enables clean testing of adapters with mocks. If the system grows to handle multiple task lists, this could evolve into a true Service layer.
- **Skip Domain Events**: Event sourcing and domain events (DDD critique #5) are too complex for this simple CLI app. Deferred unless specific audit/integration requirements emerge.
- **Implicit Bounded Context**: The app operates within a single implicit bounded context (Task Management). Will be documented in README (DDD critique #6) without complex context mapping.
- **Invariant Validation**: Phase 4 addresses DDD critiques #7 (invariant enforcement) and #8 (index-based operations) by adding validation and using task IDs.
- **Keep ports in single file**: App is too simple to justify separating Cli and Storage ports into separate files. All port definitions remain in `lib/todo/ports/ports.ex`.
- **Port error specifications**: Ports define error cases to align with domain invariants post-refactoring (duplicate tasks, task not found, file I/O failures).

