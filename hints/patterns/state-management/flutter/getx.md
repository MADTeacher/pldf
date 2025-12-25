# GetX - все-в-одном решение для Flutter

## Описание

GetX - это легковесный и мощный пакет для Flutter, который предоставляет управление состоянием, навигацию, dependency injection и многое другое в одном пакете.

## Когда использовать

- ✅ Когда нужна быстрота разработки
- ✅ Для средних приложений
- ✅ Когда нужны все функции в одном пакете
- ✅ Для разработчиков, которые хотят минимум boilerplate

## Когда НЕ использовать

- ❌ Для больших командных проектов (может быть слишком "магическим")
- ❌ Когда нужна явная структура (GetX скрывает много деталей)
- ❌ Для приложений с очень сложной бизнес-логикой

## Базовое использование

### Установка

```yaml
dependencies:
  get: ^4.6.0
```

### Простой пример

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Controller
class CounterController extends GetxController {
  var count = 0.obs; // Observable

  void increment() => count++;
  void decrement() => count--;
}

// Главный виджет
void main() {
  runApp(GetMaterialApp(
    home: CounterWidget(),
  ));
}

// Использование в виджете
class CounterWidget extends StatelessWidget {
  final CounterController controller = Get.put(CounterController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Obx автоматически обновляется при изменении count
            Obx(() => Text(
              'Count: ${controller.count.value}',
              style: TextStyle(fontSize: 24),
            )),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => controller.decrement(),
                  child: Text('-'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => controller.increment(),
                  child: Text('+'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

## Продвинутые паттерны

### Навигация

```dart
// Переход на другую страницу
Get.to(() => NextPage());

// Переход с результатом
final result = await Get.to(() => NextPage());

// Назад
Get.back();
```

### Dependency Injection

```dart
// Регистрация зависимостей
Get.put(CounterController());
Get.lazyPut(() => ApiService());
Get.putAsync(() async => await DatabaseService.init());

// Получение зависимостей
final controller = Get.find<CounterController>();
```

## Преимущества

- ✅ Все в одном пакете
- ✅ Минимум boilerplate
- ✅ Быстрая разработка
- ✅ Хорошая производительность

## Недостатки

- ❌ Может быть слишком "магическим"
- ❌ Меньше контроля над деталями
- ❌ Может быть сложнее отлаживать

## Best Practices

1. **Используйте .obs** для реактивных переменных
2. **Используйте Obx** для автоматических обновлений
3. **Используйте Get.put** для создания контроллеров
4. **Используйте Get.find** для получения контроллеров

## Связанные паттерны

- [Provider](provider.md) - более явная альтернатива
- [BLoC](bloc.md) - для более структурированной архитектуры

