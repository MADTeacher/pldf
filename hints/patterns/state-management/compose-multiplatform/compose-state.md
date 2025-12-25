# Compose State для локального состояния

## Описание

Compose State - это встроенный механизм управления локальным состоянием в Jetpack Compose. Используется для состояния, которое нужно только внутри одного composable функции.

## Когда использовать

- ✅ Локальное состояние компонента
- ✅ Простые формы и интерактивные элементы
- ✅ Когда состояние не нужно вне компонента

## Когда НЕ использовать

- ❌ Глобальное состояние приложения
- ❌ Состояние, которое нужно в нескольких компонентах
- ❌ Сложная бизнес-логика

## Базовое использование

### remember и mutableStateOf

```kotlin
@Composable
fun Counter() {
    var count by remember { mutableStateOf(0) }

    Column {
        Text("Count: $count")
        Button(onClick = { count++ }) {
            Text("Increment")
        }
    }
}
```

### rememberSaveable для сохранения состояния

```kotlin
@Composable
fun TextInput() {
    var text by rememberSaveable { mutableStateOf("") }

    TextField(
        value = text,
        onValueChange = { text = it },
        label = { Text("Enter text") }
    )
}
```

## Преимущества

- ✅ Простота - встроено в Compose
- ✅ Автоматические обновления UI
- ✅ Подходит для локального состояния

## Best Practices

1. **Используйте remember** для сохранения состояния между recompositions
2. **Используйте rememberSaveable** для сохранения при конфигурационных изменениях
3. **Поднимайте состояние** когда нужно делиться между компонентами

## Связанные паттерны

- [StateFlow](stateflow.md) - для глобального состояния
- [ViewModel](viewmodel.md) - для сложной логики

