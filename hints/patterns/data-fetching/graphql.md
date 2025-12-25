# GraphQL клиенты

## Описание

GraphQL - это язык запросов для API и runtime для выполнения этих запросов. GraphQL позволяет клиентам запрашивать только нужные данные, уменьшая количество запросов и размер ответов.

## Когда использовать

- ✅ Сложные связанные данные
- ✅ Нужна гибкость в запросах
- ✅ Хотите уменьшить количество запросов
- ✅ Разные клиенты нуждаются в разных данных

## Когда НЕ использовать

- ❌ Простые CRUD операции
- ❌ Команда не знакома с GraphQL
- ❌ Нужна простота REST API
- ❌ Кэширование на уровне HTTP важно

## Основные концепции

### Запросы (Queries)

```graphql
query GetUser($id: ID!) {
  user(id: $id) {
    id
    name
    email
    posts {
      id
      title
      comments {
        id
        text
      }
    }
  }
}
```

### Мутации (Mutations)

```graphql
mutation CreateTask($input: TaskInput!) {
  createTask(input: $input) {
    id
    title
    completed
  }
}
```

### Подписки (Subscriptions)

```graphql
subscription OnTaskUpdated {
  taskUpdated {
    id
    title
    completed
  }
}
```

## Пример реализации

### Apollo Client (React)

```javascript
import { ApolloClient, InMemoryCache, gql, useQuery, useMutation } from '@apollo/client';

// Настройка клиента
const client = new ApolloClient({
  uri: 'https://api.example.com/graphql',
  cache: new InMemoryCache(),
  headers: {
    authorization: `Bearer ${localStorage.getItem('token')}`
  }
});

// Определение запроса
const GET_TASKS = gql`
  query GetTasks {
    tasks {
      id
      title
      completed
      user {
        id
        name
      }
    }
  }
`;

// Использование запроса
function TasksList() {
  const { data, loading, error, refetch } = useQuery(GET_TASKS);

  if (loading) return <div>Загрузка...</div>;
  if (error) return <div>Ошибка: {error.message}</div>;

  return (
    <div>
      {data.tasks.map(task => (
        <div key={task.id}>{task.title}</div>
      ))}
      <button onClick={() => refetch()}>Обновить</button>
    </div>
  );
}

// Определение мутации
const CREATE_TASK = gql`
  mutation CreateTask($input: TaskInput!) {
    createTask(input: $input) {
      id
      title
      completed
    }
  }
`;

// Использование мутации
function CreateTaskForm() {
  const [createTask, { loading, error }] = useMutation(CREATE_TASK, {
    refetchQueries: [{ query: GET_TASKS }] // Обновление списка после создания
  });

  const handleSubmit = async (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    
    try {
      await createTask({
        variables: {
          input: {
            title: formData.get('title'),
            completed: false
          }
        }
      });
    } catch (err) {
      console.error('Ошибка создания задачи:', err);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input name="title" placeholder="Название задачи" />
      <button type="submit" disabled={loading}>
        {loading ? 'Создание...' : 'Создать'}
      </button>
      {error && <div>Ошибка: {error.message}</div>}
    </form>
  );
}
```

### React Query с GraphQL

```javascript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { request, gql } from 'graphql-request';

const GET_TASKS = gql`
  query GetTasks {
    tasks {
      id
      title
      completed
    }
  }
`;

function useTasks() {
  return useQuery({
    queryKey: ['tasks'],
    queryFn: async () => {
      const data = await request('https://api.example.com/graphql', GET_TASKS);
      return data.tasks;
    }
  });
}

function useCreateTask() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (input) => {
      const CREATE_TASK = gql`
        mutation CreateTask($input: TaskInput!) {
          createTask(input: $input) {
            id
            title
            completed
          }
        }
      `;
      const data = await request('https://api.example.com/graphql', CREATE_TASK, { input });
      return data.createTask;
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['tasks']);
    }
  });
}
```

## Преимущества

- ✅ Гибкость - клиент запрашивает только нужные данные
- ✅ Меньше запросов - один запрос для связанных данных
- ✅ Типобезопасность - схема определяет типы
- ✅ Интроспекция - можно запросить схему API

## Недостатки

- ❌ Сложнее, чем REST
- ❌ Кэширование сложнее
- ❌ Может быть избыточно для простых случаев
- ❌ Требует больше настройки на сервере

## Best Practices

1. **Используйте фрагменты** для переиспользования полей
2. **Обрабатывайте ошибки** на уровне запросов и полей
3. **Кэшируйте запросы** для улучшения производительности
4. **Используйте переменные** вместо строковой интерполяции
5. **Валидируйте запросы** перед отправкой
6. **Используйте подписки** для real-time обновлений

## Связанные паттерны

- [REST API](rest-api.md) - альтернативный подход
- [WebSocket](websocket.md) - для real-time обновлений через подписки

