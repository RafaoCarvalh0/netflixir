# Netflixir

A personal study project that implements video streaming techniques similar to Netflix, built with Elixir and Phoenix LiveView.

🔗 **[Live Demo - NETFLIXIR](https://netflixir.gigalixirapp.com/)**

[![Website Status](https://img.shields.io/website?url=https%3A%2F%2Fnetflixir.gigalixirapp.com)](https://netflixir.gigalixirapp.com/)

### ⚠️ Important Notice
> Due to Backblaze B2 free tier limitations, videos might be temporarily unavailable if the data transfer limit has been reached. The transfer quota is reset every 24 hours at 21:00 (Brasília Time, UTC-3).

### 🎮 Become "The only thing they fear"
> **Did you know?** When videos are unavailable, try accessing the website through your browser - you might discover a (not very) hidden surprise! 🕹️ ✨

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
- **Database**: PostgreSQL (configured but not currently in use)

### Infrastructure
- **Storage**: Using Backblaze B2's free tier (10GB) for video storage
- **Hosting**: Deployed on Gigalixir's free tier
- **Database**: PostgreSQL is configured for future features but not currently utilized

## Development Setup

### Prerequisites
- Elixir and Erlang (recommended via `asdf install`)
- FFmpeg (required for video processing)
- PostgreSQL (configured but optional for current MVP)

### Local Setup
1. Clone the repository
2. Install dependencies:
```bash
mix setup
```
3. Configure environment variables:
```bash
# Required for Backblaze B2 storage
export STORAGE_BUCKET="your-backblaze-bucket"
export B2_KEY_ID="your-backblaze-key-id"
export B2_APP_KEY="your-backblaze-application-key"
export B2_REGION="your-backblaze-region"
export B2_HOST="your-backblaze-host"
export B2_PORT="your-backblaze-port"
```
4. Start the server:
```bash
mix phx.server
```

The server will be available at [`localhost:4000`](http://localhost:4000)

## Video Processing Pipeline

The project implements a complete video processing pipeline that:
1. Transcodes the input video to an optimized format
2. Creates multiple resolution variants (1080p, 720p, 480p, 360p, 240p, 144p)
3. Generates HLS segments and playlists
4. Organizes files in the correct structure for streaming
5. Uploads processed content to Backblaze B2

## Learning Resources

To learn more about the technologies used:
* [Phoenix Framework](https://www.phoenixframework.org/)
* [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html)
* [FFmpeg](https://ffmpeg.org/documentation.html)
* [HLS Streaming](https://developer.apple.com/streaming/)
* [Backblaze B2](https://www.backblaze.com/b2/docs/)
* [Gigalixir](https://gigalixir.com/docs)

This project also leveraged AI technologies extensively during development, which proved invaluable for learning, problem-solving, and understanding complex streaming concepts. AI assistance helped in making architectural decisions, debugging issues, and implementing best practices.

## Contributing

This is a personal study project, but suggestions and contributions are welcome! Feel free to open issues or submit pull requests.

