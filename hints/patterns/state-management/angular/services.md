# Services для управления состоянием в Angular

## Описание

Angular Services - это встроенный механизм для управления состоянием через сервисы с использованием RxJS BehaviorSubject или Subject.

## Когда использовать

- ✅ Простое и среднее состояние
- ✅ Когда NgRx избыточен
- ✅ Для быстрой разработки

## Базовое использование

```typescript
import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class CounterService {
  private countSubject = new BehaviorSubject<number>(0);
  count$ = this.countSubject.asObservable();

  increment() {
    this.countSubject.next(this.countSubject.value + 1);
  }

  decrement() {
    this.countSubject.next(this.countSubject.value - 1);
  }
}

// Использование в компоненте
import { Component } from '@angular/core';
import { CounterService } from './counter.service';

@Component({
  selector: 'app-counter',
  template: `
    <div>Count: {{ count$ | async }}</div>
    <button (click)="increment()">+</button>
  `
})
export class CounterComponent {
  count$ = this.counterService.count$;

  constructor(private counterService: CounterService) {}

  increment() {
    this.counterService.increment();
  }
}
```

## Преимущества

- ✅ Встроено в Angular
- ✅ Простота использования
- ✅ Интеграция с RxJS

## Недостатки

- ❌ Может быть неэффективно для больших приложений
- ❌ Нет централизованного управления

## Связанные паттерны

- [NgRx](ngrx.md) - для более сложных случаев

