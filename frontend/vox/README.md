# Vox Studio Frontend

The frontend of Vox Studio is a lightweight, modern UI built with React, TypeScript, and Vite. It is designed to consume the Vox Studio Backend API to display and manage posts.

## Tech Stack
- **Framework**: React 18+
- **Language**: TypeScript
- **Build Tool**: Vite
- **Deployment**: Served as static assets via a Cloudflare Worker (configured in `frontend/wrangler.jsonc`).

## Environment Configuration
The frontend communicates with the backend via a base API URL. This is configured using an environment variable:

- `VITE_API_URL`: The base URL of the backend API (e.g., `http://localhost:8787` for local dev or your production worker URL).

Example `.env` file:
```env
VITE_API_URL=http://localhost:8787
```

## Getting Started

### Installation
```bash
npm install
```

### Local Development
To run the frontend in development mode with Hot Module Replacement (HMR):
```bash
npm run dev
```
The app will typically be available at `http://localhost:5173`.

### Production Build
To build the project for production:
```bash
npm run build
```
The resulting assets in the `dist/` folder are served by the Cloudflare Worker.

## Project Structure
- `src/`: Contains the React components, hooks, and API integration logic.
- `public/`: Static assets.
- `index.html`: Entry point for the Vite application.
