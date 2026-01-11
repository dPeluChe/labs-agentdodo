# Agent Dodo — Plan de Producto y Arquitectura

> macOS Native Twitter/X Client with AI Intelligence Layer

## 🎯 Objetivo del MVP

Construir una app macOS nativa (Swift/SwiftUI) de calidad "Pro" que funcione como tu centro de comando para X (Twitter). No es solo un cliente, es una herramienta de productividad con:

- **Composer "Keyboard-First"** para escribir y publicar sin distracciones.
- **Intelligence Layer** modular para asistencia de escritura (agnóstico del proveedor).
- **Persistencia local robusta** (Drafts, History, Search).
- **Experiencia Nativa macOS** (Ventanas flotantes, Drag & Drop, Atajos).

---

## 1. Stack y Decisiones Clave

### UI / App
- **Swift + SwiftUI**: Diseño responsivo y moderno.
- **Window Management**:
  - Ventana principal con Sidebar (Write / Inbox / Explore / Settings).
  - **Quick Composer**: `NSPanel` flotante, activable globalmente, independiente del foco principal.
- **Keyboard-First Design**: Toda acción crítica debe tener atajo (⌘+N, ⌘+Enter, ⌘+S).

### Auth (Fase API)
- OAuth 2.0 con PKCE (`ASWebAuthenticationSession`).
- Tokens seguros en Keychain.

### Persistencia / DB Local
- **SwiftData**:
  - Esquemas versionados (`VersionedSchema`) desde el día 1 para migraciones seguras.
  - Uso de `@ModelActor` para operaciones en background thread-safe.

### Networking & Sync
- **Background Tasks**: Uso de `BGTaskScheduler` para refrescar Inbox/Menciones mientras la app está minimizada.
- **Error Handling**: Mapeo inteligente de errores (ej. Rate Limits con cuenta regresiva en UI).

### Intelligence Layer (LLM)
- **Factory Pattern**: `LLMProvider` protocol.
- **Soporte futuro**: OpenAI, Anthropic, o **Local CoreML/Llama.cpp** (privacidad máxima).

---

## 2. UI/UX (Mock-First Development)

### Navegación Principal (Sidebar)
1. **Write**: Editor completo.
2. **Inbox**: Menciones y DMs unificados.
3. **Explore**: Tendencias y Búsquedas guardadas.
4. **Drafts**: Borradores con versiones.
5. **History**: Log de actividad local.
6. **Settings**: Configuración y gestión de datos.

### Vista "Write" (Composer)
**Experiencia "Pro":**
- **Editor Rico**: Markdown highlighting básico.
- **Media Handling**: **Drag & Drop** nativo de imágenes/video desde Finder al lienzo.
- **Tone Selector**: Casual / Pro / Spicy / Neutral.
- **Atajos**: ⌘+Enter (Post), ⌘+S (Save Draft).

### Vista "Inbox"
- **Conversation View**: Hilos renderizados localmente con cache.
- **Quick Reply**: Respuesta inline sin abrir nueva ventana.

### Quick Composer (NSPanel)
- Ventana "siempre visible" (opcional) que flota sobre otras apps.
- Minimalista: Solo texto + botón enviar.
- Se cierra automáticamente al enviar exitosamente.

---

## 3. Estrategia de Datos & Mocks

### Mock Data Layer (Inmediato)
- `MockTimelineService`, `MockInboxService`.
- **Simulación de Estados**:
  - Toggle en modo "Developer" para forzar errores de red, timeouts o rate limits y probar la resiliencia de la UI.

### DB Local (SwiftData)
Entidades clave:
- **Draft**: Soporta `attachments` (rutas locales) y `variants` (versiones de IA).
- **Post**: Estado `queued` para soporte offline.
- **MediaAsset**: Referencia a archivos locales para upload diferido.

---

## 4. Arquitectura Interna (Clean Architecture)

### Capas Refinadas

1. **Presentation**: SwiftUI Views + `KeyboardShortcuts`.
2. **ViewModels**: `@MainActor` gestionando estado de UI.
3. **Domain**:
   - Protocolos (`LLMProvider`, `PostService`).
   - UseCases puros (`GenerateRewriteUseCase`, `SyncInboxUseCase`).
4. **Infrastructure**:
   - `BackgroundSyncManager`: Orquestación de tareas en segundo plano.
   - `LLMFactory`: Selección dinámica del motor de IA.
   - `XAPIClient`: Manejo de límites y reintentos.
   - `SwiftDataStore`: Actores aislados para escritura.

---

## 5. Roadmap por Fases

### Fase A — Foundation & UX (MVP Local)
- App Shell + Sidebar.
- **CI/CD Inicial**: GitHub Actions para build y SwiftLint.
- SwiftData con Migrations setup.
- Composer con Drag & Drop (mock upload) y Atajos.
- Mocks completos (Estados de carga/error).

### Fase B — Auth & API Basics
- Login OAuth.
- Posting real (texto + media).
- Error Handling robusto (Rate Limits amigables).

### Fase C — Sync & Background
- Fetch periódico de Inbox.
- Background App Refresh.
- Cache de imágenes.

### Fase D — Intelligence Layer
- Implementación de `LLMProvider`.
- Features: Rewrite, Summarize thread, Tone check.
- Opción "Local-only" (privacidad).

---

## 6. Siguiente Paso

Convertir este plan en tareas técnicas detalladas en `BACKLOG.md` y configurar el entorno de CI.