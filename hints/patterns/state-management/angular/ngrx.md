# NgRx - Redux для Angular

## Описание

NgRx - это библиотека управления состоянием для Angular, основанная на Redux паттернах. Она использует RxJS для реактивного программирования.

## Когда использовать

- ✅ Большие Angular приложения
- ✅ Когда нужна предсказуемость
- ✅ Для командных проектов

## Базовое использование

```typescript
// Actions
import { createAction } from '@ngrx/store';

export const increment = createAction('[Counter] Increment');
export const decrement = createAction('[Counter] Decrement');

// Reducer
import { createReducer, on } from '@ngrx/store';

export const counterReducer = createReducer(
  0,
  on(increment, state => state + 1),
  on(decrement, state => state - 1)
);

// Использование в компоненте
import { Store } from '@ngrx/store';

@Component({
  selector: 'app-counter',
  template: `
    <div>Count: {{ count$ | async }}</div>
    <button (click)="increment()">+</button>
  `
})
export class CounterComponent {
  count$ = this.store.select('count');

  constructor(private store: Store) {}

  increment() {
    this.store.dispatch(increment());
  }
}
```

## Преимущества

- ✅ Предсказуемость
- ✅ Интеграция с RxJS
- ✅ Хорошая экосистема

## Недостатки

- ❌ Больше boilerplate
- ❌ Может быть избыточно для простых случаев

## Связанные паттерны

- [Services](services.md) - более простая альтернатива

