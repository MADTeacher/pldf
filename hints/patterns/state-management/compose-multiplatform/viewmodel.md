# ViewModel паттерн в Compose Multiplatform

## Описание

ViewModel - это паттерн для хранения UI-связанных данных, которые переживают конфигурационные изменения. В Compose Multiplatform используется вместе со StateFlow для управления состоянием.

## Когда использовать

- ✅ UI логика, которая должна пережить конфигурационные изменения
- ✅ Сложная бизнес-логика
- ✅ Интеграция с репозиториями и API

## Базовое использование

```kotlin
import androidx.lifecycle.ViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class TasksViewModel(
    private val repository: TaskRepository
) : ViewModel() {
    private val _tasks = MutableStateFlow<List<Task>>(emptyList())
    val tasks: StateFlow<List<Task>> = _tasks.asStateFlow()

    private val _loading = MutableStateFlow(false)
    val loading: StateFlow<Boolean> = _loading.asStateFlow()

    init {
        loadTasks()
    }

    fun loadTasks() {
        viewModelScope.launch {
            _loading.value = true
            try {
                _tasks.value = repository.getTasks()
            } finally {
                _loading.value = false
            }
        }
    }
}

// Использование в Compose
@Composable
fun TasksScreen(
    viewModel: TasksViewModel = viewModel()
) {
    val tasks by viewModel.tasks.collectAsState()
    val loading by viewModel.loading.collectAsState()

    if (loading) {
        CircularProgressIndicator()
    } else {
        LazyColumn {
            items(tasks) { task ->
                TaskItem(task)
            }
        }
    }
}
```

## Преимущества

- ✅ Переживает конфигурационные изменения
- ✅ Разделение UI и бизнес-логики
- ✅ Интеграция с корутинами

## Best Practices

1. **Используйте viewModelScope** для корутин
2. **Используйте StateFlow** для состояния
3. **Не храните ссылки на Context** в ViewModel

## Связанные паттерны

- [StateFlow](stateflow.md) - для реактивного состояния
- [Compose State](compose-state.md) - для локального состояния

