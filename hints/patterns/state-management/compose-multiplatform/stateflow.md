# StateFlow для реактивного состояния в Compose Multiplatform

## Описание

StateFlow - это реактивный поток данных из Kotlin Coroutines, который хранит текущее значение состояния и позволяет подписываться на изменения. Идеально подходит для управления состоянием в Compose Multiplatform приложениях.

## Когда использовать

- ✅ Compose Multiplatform приложения
- ✅ Когда нужна реактивность и корутины
- ✅ Для глобального состояния приложения
- ✅ Когда нужна интеграция с Kotlin экосистемой

## Базовое использование

### Простой пример

```kotlin
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class CounterViewModel {
    private val _count = MutableStateFlow(0)
    val count: StateFlow<Int> = _count.asStateFlow()

    fun increment() {
        _count.value++
    }

    fun decrement() {
        _count.value--
    }
}

// Использование в Compose
@Composable
fun CounterScreen(viewModel: CounterViewModel = remember { CounterViewModel() }) {
    val count by viewModel.count.collectAsState()

    Column {
        Text("Count: $count")
        Button(onClick = { viewModel.increment() }) {
            Text("+")
        }
        Button(onClick = { viewModel.decrement() }) {
            Text("-")
        }
    }
}
```

### Асинхронные операции

```kotlin
class TasksViewModel {
    private val _tasks = MutableStateFlow<List<Task>>(emptyList())
    val tasks: StateFlow<List<Task>> = _tasks.asStateFlow()

    private val _loading = MutableStateFlow(false)
    val loading: StateFlow<Boolean> = _loading.asStateFlow()

    suspend fun loadTasks() {
        _loading.value = true
        try {
            _tasks.value = api.getTasks()
        } finally {
            _loading.value = false
        }
    }
}
```

## Преимущества

- ✅ Реактивность - автоматические обновления UI
- ✅ Интеграция с корутинами
- ✅ Типобезопасность
- ✅ Подходит для Compose

## Best Practices

1. **Используйте MutableStateFlow** для изменяемого состояния
2. **Экспортируйте StateFlow** для чтения
3. **Используйте collectAsState()** в Compose
4. **Обрабатывайте ошибки** в корутинах

## Связанные паттерны

- [Compose State](compose-state.md) - для локального состояния
- [ViewModel](viewmodel.md) - для UI логики

