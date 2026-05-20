# Vox Studio

Vox Studio is a small, focused full-stack project organized as a monorepo with a Cloudflare Worker-based backend and a modern React + Vite frontend. The backend exposes a minimal API for posts backed by Supabase, while the frontend provides a lightweight UI that consumes that API.

Key components:
- Frontend (frontend/vox): React + TypeScript app built with Vite. Serves the UI assets via a Cloudflare Worker and communicates with the backend API.
- Backend (backend): Cloudflare Worker with Hono, backed by Supabase for persistent storage. Exposes endpoints for reading and uploading posts.
- Wrangler: Used to run and deploy the Cloudflare Workers locally and to production.
- Shared configuration: wrangler.jsonc files at frontend and backend configure the build/deploy process; the frontend serves static assets from the Vox app, while the backend handles API endpoints.

Project structure
- backend/
  - wrangler.jsonc                # Wrangler config for local/dev/prod
  - src/index.ts                  # Hono app entrypoint, routes mounted here
  - src/routes/read/read.ts        # GET /vox/posts -> fetch posts
  - src/routes/upload/post.ts      # POST /vox/upload/post -> upload new post
  - src/schema/upload/post.ts      # DTO validation schema for posts
  - src/lib/db.ts                   # Supabase client bootstrapper
  - src/repositories/read/post.read.ts   # DB read logic for posts
  - src/repositories/upload/post.upload.ts # DB write logic for posts

- frontend/
  - wrangler.jsonc                  # Wrangler config for frontend assets as worker
  - vox/                            # Vox React app (Vite dev server)
    - package.json                  # Dev/build scripts (dev: vite, build: tsc + vite)
    - dist/                         # Built assets (served as static assets by the worker)
    - .env.example                  # Example environment variables for frontend (VITE_API_URL)
  - color_scheme.md                 # Color tokens used by the frontend styling
- .claude/                           # (Other environment artifacts, if any, kept out of core README)
- frontend/vox/README.md             # Existing frontend guide (React + TS + Vite)
- backend/README.md                  # Backend usage guide, Cloudflare integration

How the architecture fits together
- Frontend (frontend/vox) is a React + TypeScript UI built with Vite. It communicates with the backend API via a base URL configured in Vite (VITE_API_URL).
- Backend (backend) exposes REST-like endpoints via Hono, backed by a Supabase database.
  - GET /vox/posts returns all posts from the database.
  - POST /vox/upload/post accepts a JSON payload to create a new post, validated against a Zod schema, and stores it in the database.
- Wrangler is used to run and deploy both frontend and backend as Cloudflare Workers. The frontend serves assets from vox/dist; the backend serves API routes under the Vox namespace.

API surface (backend)
- GET /vox/posts
  - Returns a list of posts from the database.
- POST /vox/upload/post
  - Expects a JSON body with: title, content, slug, excerpt, category, readingTime, featured.
  - Requires a valid X-API-KEY header matching the API_KEY environment binding.
  - Example payload:
    ```json
    {
      "title": "Sample Post",
      "slug": "sample-post",
      "excerpt": "An example excerpt",
      "content": "Full content of the post.",
      "category": "Tech",
      "readingTime": "5 min",
      "featured": false
    }
    ```

Data model (backend)
- Post table fields (as used by the backend):
  - id: UUID
  - slug: string
  - title: string
  - excerpt: string
  - content: string
  - category: string
  - date: timestamp/ISO string
  - readingTime: string
  - featured: boolean

How to run locally
Prerequisites
- Node.js (v18+ recommended)
- Wrangler (npm i -g wrangler) for Cloudflare Workers
- Access to a Supabase project (URL and a service role key) for backend DB
- A Cloudflare account for Wrangler deployment (optional for local dev)

1) Frontend (UI)
- cd frontend/vox
- npm install
- Create a local environment file if needed, see frontend/vox/.env.example (set VITE_API_URL to the backend URL during development or point to the local worker in dev mode).
- npm run dev
- Open http://localhost:5173 (default Vite port) to view the UI.

2) Backend (API)
- cd backend
- npm install
- Ensure environment bindings for Supabase URL, service role, and API key exist (these are accessed in wrangler.jsonc and src files).
- You can run in development mode with Wrangler: npm run dev
- For deployment: npm run deploy
- Wrangler will start a local worker (on a port, typically 8787) and proxy API requests as configured in wrangler.jsonc.

Environment and bindings (backend)
- SUPABASE_URL: Supabase database URL
- SUPABASE_SERVICE_ROLE: Supabase service role key
- API_KEY: Shared secret for POST /vox/upload/post API validation (X-API-KEY header)
- This project uses the following environment bindings in code:
  - In index.ts: app.use(cors(...)) with allowed origins and credentials
  - In read.ts: It creates a Supabase client with env.SUPABASE_URL and env.SUPABASE_SERVICE_ROLE
  - In upload.ts: It validates the payload and API key, then writes via Supabase

Notes
- The frontend UI and backend API are intentionally decoupled; the frontend calls the backend API at VITE_API_URL and does not assume a direct database connection.
- The frontend stores its UI assets in vox/dist and serves them via a Cloudflare Worker (frontend/wrangler.jsonc).
- The backend uses Hono for routing and Wrangler for development/deployment.
- There are existing docs in frontend/vox/README.md and backend/README.md which provide further in-repo guidance; this root README summarizes the structure and functionality at a high level.

Contributing and planning
- If you add new routes or alter the data model, update the backend schemas and repository layers accordingly.
- If you modify the frontend API surface, update the VITE_API_URL in the frontend config and the API interaction logic in the Vox UI.

License
- See LICENSE (if present) or the repository’s licensing terms.

Dev Quick Start
This repository includes a root npm script to boot both frontend and backend in parallel for local development.

Usage:
- npm run start:dev
- Or run the script directly:
  - chmod +x ./scripts/start-dev.sh
  - ./scripts/start-dev.sh
- Development diagram
```
Frontend Vox (Vite dev) <----> Backend API (Wrangler dev)
     http://localhost:5173               http://localhost:8787 (or the Wrangler dev URL)
        |                                      |
        | calls to base URL (VITE_API_URL)     |
        v                                      v
GET /vox/posts                               GET /vox/posts
POST /vox/upload/post (with API_KEY)        POST /vox/upload/post
```

Script overview
- scripts/start-dev.sh: boots the backend and frontend in parallel and streams logs to stdout.

License
- See LICENSE (if present) or the repository’s licensing terms.
