# Структура React проектов

## Описание

Рекомендации по организации структуры React приложений с применением принципов чистой архитектуры. Рассматриваются различные подходы в зависимости от размера и сложности проекта.

## Когда использовать

- ✅ React приложения любого размера
- ✅ Когда нужна масштабируемая структура
- ✅ Командная разработка
- ✅ Долгосрочные проекты

## Подходы к структуре

### 1. Feature-based структура (Рекомендуется)

Организация по функциональным модулям. Каждая фича самодостаточна.

```
src/
├── app/                       # Конфигурация приложения
│   ├── store/
│   ├── router/
│   └── App.tsx
├── features/                  # Функциональные модули
│   ├── auth/
│   │   ├── api/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── store/
│   │   └── types/
│   ├── notes/
│   │   ├── api/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── store/
│   │   └── types/
│   └── profile/
│       ├── api/
│       ├── components/
│       ├── hooks/
│       └── types/
├── shared/                    # Общие компоненты
│   ├── components/
│   ├── hooks/
│   ├── utils/
│   └── types/
└── index.tsx
```

### 2. Domain-driven структура

Организация по доменам с четким разделением слоев.

```
src/
├── app/
├── domain/                    # Бизнес-логика
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/                      # Работа с данными
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── presentation/              # UI слой
│   ├── components/
│   ├── pages/
│   └── hooks/
└── shared/
```

### 3. Component-based структура (Для маленьких проектов)

Организация по типам компонентов.

```
src/
├── components/
├── pages/
├── hooks/
├── services/
├── utils/
└── types/
```

## Детальная структура Feature-based

### Структура фичи

```
features/notes/
├── api/
│   └── notesApi.ts
├── components/
│   ├── NoteCard/
│   │   ├── NoteCard.tsx
│   │   ├── NoteCard.module.css
│   │   └── index.ts
│   └── NoteForm/
│       ├── NoteForm.tsx
│       └── index.ts
├── hooks/
│   ├── useNotes.ts
│   └── useCreateNote.ts
├── store/
│   ├── notesSlice.ts
│   └── notesThunks.ts
├── types/
│   └── note.types.ts
└── index.ts
```

### Domain слой (TypeScript)

```typescript
// features/notes/types/note.types.ts
export interface Note {
  id: string;
  title: string;
  content: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface NoteRepository {
  getNotes(): Promise<Note[]>;
  createNote(note: Omit<Note, 'id' | 'createdAt' | 'updatedAt'>): Promise<Note>;
  deleteNote(id: string): Promise<void>;
}
```

### Data слой

```typescript
// features/notes/api/notesApi.ts
import { Note } from '../types/note.types';

const API_BASE = '/api/notes';

export const notesApi = {
  async getNotes(): Promise<Note[]> {
    const response = await fetch(API_BASE);
    if (!response.ok) throw new Error('Failed to fetch notes');
    const data = await response.json();
    return data.map((item: any) => ({
      ...item,
      createdAt: new Date(item.createdAt),
      updatedAt: new Date(item.updatedAt),
    }));
  },

  async createNote(note: Omit<Note, 'id' | 'createdAt' | 'updatedAt'>): Promise<Note> {
    const response = await fetch(API_BASE, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(note),
    });
    if (!response.ok) throw new Error('Failed to create note');
    const data = await response.json();
    return {
      ...data,
      createdAt: new Date(data.createdAt),
      updatedAt: new Date(data.updatedAt),
    };
  },

  async deleteNote(id: string): Promise<void> {
    const response = await fetch(`${API_BASE}/${id}`, {
      method: 'DELETE',
    });
    if (!response.ok) throw new Error('Failed to delete note');
  },
};
```

### Presentation слой

#### Redux Toolkit

```typescript
// features/notes/store/notesSlice.ts
import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { Note } from '../types/note.types';

interface NotesState {
  notes: Note[];
  loading: boolean;
  error: string | null;
}

const initialState: NotesState = {
  notes: [],
  loading: false,
  error: null,
};

const notesSlice = createSlice({
  name: 'notes',
  initialState,
  reducers: {
    setLoading: (state, action: PayloadAction<boolean>) => {
      state.loading = action.payload;
    },
    setError: (state, action: PayloadAction<string | null>) => {
      state.error = action.payload;
    },
    setNotes: (state, action: PayloadAction<Note[]>) => {
      state.notes = action.payload;
    },
    addNote: (state, action: PayloadAction<Note>) => {
      state.notes.push(action.payload);
    },
    removeNote: (state, action: PayloadAction<string>) => {
      state.notes = state.notes.filter(note => note.id !== action.payload);
    },
  },
});

export const { setLoading, setError, setNotes, addNote, removeNote } = notesSlice.actions;
export default notesSlice.reducer;
```

```typescript
// features/notes/store/notesThunks.ts
import { AppDispatch } from '../../app/store';
import { notesApi } from '../api/notesApi';
import { setLoading, setError, setNotes, addNote, removeNote } from './notesSlice';

export const fetchNotes = () => async (dispatch: AppDispatch) => {
  try {
    dispatch(setLoading(true));
    dispatch(setError(null));
    const notes = await notesApi.getNotes();
    dispatch(setNotes(notes));
  } catch (error) {
    dispatch(setError(error instanceof Error ? error.message : 'Unknown error'));
  } finally {
    dispatch(setLoading(false));
  }
};

export const createNote = (note: Omit<Note, 'id' | 'createdAt' | 'updatedAt'>) =>
  async (dispatch: AppDispatch) => {
    try {
      dispatch(setLoading(true));
      dispatch(setError(null));
      const newNote = await notesApi.createNote(note);
      dispatch(addNote(newNote));
    } catch (error) {
      dispatch(setError(error instanceof Error ? error.message : 'Unknown error'));
    } finally {
      dispatch(setLoading(false));
    }
  };

export const deleteNote = (id: string) => async (dispatch: AppDispatch) => {
  try {
    dispatch(setLoading(true));
    dispatch(setError(null));
    await notesApi.deleteNote(id);
    dispatch(removeNote(id));
  } catch (error) {
    dispatch(setError(error instanceof Error ? error.message : 'Unknown error'));
  } finally {
    dispatch(setLoading(false));
  }
};
```

#### Custom Hooks

```typescript
// features/notes/hooks/useNotes.ts
import { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { AppDispatch, RootState } from '../../app/store';
import { fetchNotes } from '../store/notesThunks';

export const useNotes = () => {
  const dispatch = useDispatch<AppDispatch>();
  const { notes, loading, error } = useSelector((state: RootState) => state.notes);

  useEffect(() => {
    dispatch(fetchNotes());
  }, [dispatch]);

  return { notes, loading, error };
};
```

```typescript
// features/notes/hooks/useCreateNote.ts
import { useDispatch } from 'react-redux';
import { AppDispatch } from '../../app/store';
import { createNote as createNoteThunk } from '../store/notesThunks';
import { Note } from '../types/note.types';

export const useCreateNote = () => {
  const dispatch = useDispatch<AppDispatch>();

  const createNote = async (note: Omit<Note, 'id' | 'createdAt' | 'updatedAt'>) => {
    await dispatch(createNoteThunk(note));
  };

  return { createNote };
};
```

#### Components

```typescript
// features/notes/components/NoteCard/NoteCard.tsx
import React from 'react';
import { Note } from '../../types/note.types';
import styles from './NoteCard.module.css';

interface NoteCardProps {
  note: Note;
  onDelete: (id: string) => void;
}

export const NoteCard: React.FC<NoteCardProps> = ({ note, onDelete }) => {
  return (
    <div className={styles.card}>
      <h3>{note.title}</h3>
      <p>{note.content}</p>
      <button onClick={() => onDelete(note.id)}>Delete</button>
    </div>
  );
};
```

```typescript
// features/notes/components/NotesList/NotesList.tsx
import React from 'react';
import { useNotes } from '../../hooks/useNotes';
import { useDeleteNote } from '../../hooks/useDeleteNote';
import { NoteCard } from '../NoteCard/NoteCard';

export const NotesList: React.FC = () => {
  const { notes, loading, error } = useNotes();
  const { deleteNote } = useDeleteNote();

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div>
      {notes.map(note => (
        <NoteCard key={note.id} note={note} onDelete={deleteNote} />
      ))}
    </div>
  );
};
```

## Shared компоненты

```typescript
// shared/components/Button/Button.tsx
import React from 'react';
import styles from './Button.module.css';

interface ButtonProps {
  children: React.ReactNode;
  onClick?: () => void;
  variant?: 'primary' | 'secondary';
}

export const Button: React.FC<ButtonProps> = ({
  children,
  onClick,
  variant = 'primary',
}) => {
  return (
    <button
      className={`${styles.button} ${styles[variant]}`}
      onClick={onClick}
    >
      {children}
    </button>
  );
};
```

## App конфигурация

```typescript
// app/store/index.ts
import { configureStore } from '@reduxjs/toolkit';
import notesReducer from '../../features/notes/store/notesSlice';

export const store = configureStore({
  reducer: {
    notes: notesReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
```

```typescript
// app/App.tsx
import React from 'react';
import { Provider } from 'react-redux';
import { store } from './store';
import { NotesList } from '../features/notes/components/NotesList/NotesList';

export const App: React.FC = () => {
  return (
    <Provider store={store}>
      <div className="app">
        <NotesList />
      </div>
    </Provider>
  );
};
```

## Преимущества Feature-based структуры

- ✅ Модульность - каждая фича независима
- ✅ Масштабируемость - легко добавлять новые фичи
- ✅ Командная работа - разные команды работают над разными фичами
- ✅ Тестируемость - легко тестировать изолированно
- ✅ Переиспользование - shared компоненты используются везде

## Best Practices

1. **Разделяйте по фичам** - каждая фича самодостаточна
2. **Используйте shared для общих компонентов** - не дублируйте код
3. **Следуйте принципам чистой архитектуры** - разделение слоев
4. **Используйте TypeScript** - для типобезопасности
5. **Тестируйте каждый слой** - компоненты, хуки, API
6. **Используйте индексы для экспорта** - упрощает импорты
7. **Не смешивайте слои** - компоненты не знают о деталях API

## Альтернативные подходы к state management

### Context API (для простых случаев)

```typescript
// features/notes/context/NotesContext.tsx
import React, { createContext, useContext, useState, useEffect } from 'react';
import { Note } from '../types/note.types';
import { notesApi } from '../api/notesApi';

interface NotesContextType {
  notes: Note[];
  loading: boolean;
  error: string | null;
  fetchNotes: () => Promise<void>;
  createNote: (note: Omit<Note, 'id' | 'createdAt' | 'updatedAt'>) => Promise<void>;
}

const NotesContext = createContext<NotesContextType | undefined>(undefined);

export const NotesProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [notes, setNotes] = useState<Note[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchNotes = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await notesApi.getNotes();
      setNotes(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  const createNote = async (note: Omit<Note, 'id' | 'createdAt' | 'updatedAt'>) => {
    setLoading(true);
    setError(null);
    try {
      const newNote = await notesApi.createNote(note);
      setNotes(prev => [...prev, newNote]);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchNotes();
  }, []);

  return (
    <NotesContext.Provider value={{ notes, loading, error, fetchNotes, createNote }}>
      {children}
    </NotesContext.Provider>
  );
};

export const useNotesContext = () => {
  const context = useContext(NotesContext);
  if (!context) {
    throw new Error('useNotesContext must be used within NotesProvider');
  }
  return context;
};
```

## Связанные паттерны

- [Clean Architecture](clean-architecture.md) - общие принципы
- [Redux](../state-management/react/redux.md) - для управления состоянием
- [Context API](../state-management/react/context-api.md) - альтернатива Redux

