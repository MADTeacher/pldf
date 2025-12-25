# Vuex для управления состоянием в Vue 2

## Описание

Vuex - это официальная библиотека управления состоянием для Vue.js. Она служит централизованным хранилищем для всех компонентов приложения.

## Когда использовать

- ✅ Vue 2 приложения
- ✅ Большие приложения с сложным состоянием
- ✅ Когда нужна централизация состояния

## Базовое использование

```javascript
import Vue from 'vue';
import Vuex from 'vuex';

Vue.use(Vuex);

const store = new Vuex.Store({
  state: {
    count: 0
  },
  mutations: {
    increment(state) {
      state.count++;
    },
    decrement(state) {
      state.count--;
    }
  },
  actions: {
    increment({ commit }) {
      commit('increment');
    }
  }
});

// Использование в компоненте
export default {
  computed: {
    count() {
      return this.$store.state.count;
    }
  },
  methods: {
    increment() {
      this.$store.dispatch('increment');
    }
  }
}
```

## Преимущества

- ✅ Официальная библиотека Vue 2
- ✅ Хорошая документация
- ✅ Интеграция с Vue DevTools

## Недостатки

- ❌ Только для Vue 2
- ❌ Больше boilerplate, чем Pinia

## Связанные паттерны

- [Pinia](pinia.md) - современная альтернатива для Vue 3

