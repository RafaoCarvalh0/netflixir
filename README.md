# Netflixir

A personal study project that implements video streaming techniques similar to Netflix, built with Elixir and Phoenix LiveView.

![Build & Tests](https://github.com/RafaoCarvalh0/netflixir/actions/workflows/elixir.yml/badge.svg)

---

## ⚠️ Important Notice
> Due to Backblaze B2 free tier limitations, videos might be temporarily unavailable if the data transfer limit has been reached. The transfer quota is reset every 24 hours at 21:00 (Brasília Time, UTC-3).

## 🎮 Become "The only thing they fear"
> **Did you know?** When videos are unavailable, try accessing the website through your browser - you might discover a (not very) hidden surprise! 🕹️ ✨

🔗 **[Live Demo - NETFLIXIR](https://netflixir.gigalixirapp.com/)**

[![Website Status](https://img.shields.io/website?url=https%3A%2F%2Fnetflixir.gigalixirapp.com)](https://netflixir.gigalixirapp.com/)

---

## About

This project aims to understand and implement adaptive video streaming techniques, with a strong focus on backend development and video processing infrastructure. 

The project follows several software development principles and patterns to ensure maintainability and scalability:

### Development Principles
- **Domain-Driven Design (DDD)**: Clear separation of concerns with well-defined bounded contexts
- **Dependency Injection**: Flexible component coupling through behavior injection
- **DRY (Don't Repeat Yourself)**: Code reusability and maintainability
- **Clean Code Principles**:
  - Meaningful naming conventions
  - Single Responsibility Principle
  - Small, focused functions
  - Clear and descriptive documentation
  - Consistent code formatting
- **Test-Driven Development**:
  - Comprehensive test coverage
  - Behavior-driven development
  - Clear test organization
- **Architecture**:
  - Well-defined boundaries between layers
  - Clear separation between video processing, storage, and web interface
  - Modular and extensible design

The frontend implementation was largely assisted by AI, with code design decisions being made by the developer. JavaScript and HTML templates were mostly implemented by AI with minimal intervention, as the focus was on backend functionality. It currently focuses on serving a single video with multiple quality options, allowing users to experience how adaptive streaming works.

### Backend Architecture

- **LiveView/Controller**: Handles user interaction and events.
- **Service Layer**: Business logic, orchestration, and coordination.
- **Store Layer**: Data access, mapping, and transformation.
- **Storage Behaviour**: Abstracts storage, allowing easy swap between local, remote, or mock.
- **Video Processing Pipeline**: Handles transcoding, segmentation, and upload.

### Example Request Flow

1. User requests a video page via LiveView.
2. LiveView calls the Service Layer to fetch video metadata.
3. Service Layer uses Store Layer to get video info and paths.
4. Store Layer interacts with Storage Behaviour to list files or get signed URLs.
5. LiveView renders the page with video info and signed URLs for streaming.
6. The frontend player requests HLS playlists and segments, which are served from storage (and may be cached by Service Worker).

### Service Worker & Manual Media Cache

To improve performance and user experience, a Service Worker is used to cache images and HLS media files (`.m3u8`, `.ts`) in the browser. This allows for:
- Faster video startup and seeking for already-viewed segments
- Offline playback of cached segments
- Reduced bandwidth usage for repeat views

**Note:** The Service Worker only intercepts requests for static media files and does not interfere with LiveView, WebSocket, or API requests.


### Current MVP Features
- Video streaming with multiple quality options
- Manual quality selection interface
- HLS (HTTP Live Streaming) implementation
- Adaptive bitrate streaming support
- Video processing pipeline with multiple resolutions

### Tech Stack
- **Backend**: Elixir + Phoenix
- **Frontend**: Phoenix LiveView + TailwindCSS
- **Video Processing**: FFmpeg
- **Storage**: Backblaze B2 (Free Tier)
- **Deployment**: Gigalixir
- **Database**: PostgreSQL

### Infrastructure
- **Storage**: Using Backblaze B2's free tier (10GB) for video storage
- **Hosting**: Deployed on Gigalixir's free tier
- **Database**: PostgreSQL

## Prerequisites

Before you start, make sure you have the following installed on your machine:

- **Elixir** and **Erlang** (recommended via [asdf](https://asdf-vm.com/) install)
- **Docker**
- **FFmpeg** (required for video processing)
- **PostgreSQL client**

## Development Setup

### Prerequisites
- Elixir and Erlang (recommended via `asdf install` for local use)
- **OR** Docker and Docker Compose (recommended for a ready-to-use environment)
- FFmpeg (required only for local use, already included in Docker)
- PostgreSQL (required only for local use, already included in Docker Compose)

### Using Docker (recommended)

The project includes a `Dockerfile` and a `docker-compose.yml` that set up the entire environment automatically, including FFmpeg and PostgreSQL. To run the development environment:

1. Clone the repository
2. Run:
   ```sh
   docker-compose up --build
   ```
3. Access [`localhost:4000`](http://localhost:4000)

You can run commands like tests and migrations inside the container:

```sh
docker-compose run --rm app mix test
docker-compose run --rm app mix ecto.migrate
```

### Local Setup (optional)
If you prefer to run locally, install Elixir, Erlang, FFmpeg, and PostgreSQL manually. Then start the server with:

```sh
mix phx.server
```

The project is configured to work differently in each environment:

#### Development
In development mode, the project uses local storage for videos and thumbnails. No additional configuration is needed — files will be stored in the project's storage directory.

#### Testing
The testing environment uses mocks for storage operations, making it easy to test without external dependencies.
