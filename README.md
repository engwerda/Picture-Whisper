# PictureWhisper

PictureWhisper is an Elixir-based web application that allows users to generate images using AI, powered by OpenAI's DALL-E model. This project demonstrates the integration of Phoenix LiveView for real-time user interactions and OpenAI's API for image generation.

## Features

- User authentication system
- Real-time image generation using DALL-E
- Image management (view, delete, download)
- Customizable image size and quality
- Pagination for image gallery
- Free tier with global API key and premium tier with user's own API key

## Technologies Used

- Elixir
- Phoenix Framework
- Phoenix LiveView
- PostgreSQL
- OpenAI API
- Tailwind CSS
- AWS S3 (or compatible storage)

## Getting Started

### Prerequisites

- Elixir 1.14 or later
- Phoenix 1.7.14 or later
- PostgreSQL or use the provided Docker Compose setup

### Installation

1. Clone the repository:
   ```sh
   git clone https://github.com/engwerda/Picture-Whisper.git
   cd picture_whisper
   ```

2. Install dependencies:
   ```sh
   mix deps.get
   ```

3. Set up the database:

   Option A: Using local PostgreSQL
   ```sh
   mix ecto.setup
   ```

   Option B: Using Docker Compose
   ```sh
   docker-compose up -d
   ```

4. Set up environment variables:
   Copy the `env_example` file to `.env` and edit it:
   ```sh
   cp env_example .env
   ```
   Then open `.env` in your text editor and add your OpenAI API key:
   ```sh
   OPENAI_GLOBAL_API_KEY=your_openai_api_key_here
   ```

5. Start the Phoenix server:
   ```sh
   mix phx.server
   ```
   or
```sh
   iex -S mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Running Tests

To run the tests for PictureWhisper, use the following command:

```sh
mix test
```

```sh
mix test --trace
```
## Deployment

This application is designed to be deployed on platforms like Fly.io. Make sure to set up the necessary environment variables and adjust the configuration files accordingly.


## License

This project is licensed under the MIT License.

