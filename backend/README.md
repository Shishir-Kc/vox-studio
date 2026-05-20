# Vox Studio Backend

The backend of Vox Studio is a high-performance API built with Hono and deployed on Cloudflare Workers. It provides the core logic for reading and uploading posts, using Supabase for persistent storage.

## Tech Stack
- **Framework**: [Hono](https://hono.dev/)
- **Runtime**: Cloudflare Workers
- **Database**: Supabase (PostgreSQL)
- **Validation**: Zod

## API Surface
All endpoints are mounted under the `/vox` namespace.

### Get All Posts
- **Endpoint**: `GET /vox/posts`
- **Description**: Fetches all posts from the Supabase database.
- **Response**: JSON array of post objects.

### Upload New Post
- **Endpoint**: `POST /vox/upload/post`
- **Description**: Creates a new post in the database.
- **Authentication**: Requires `X-API-KEY` header.
- **Payload**: 
  - `title` (string)
  - `slug` (string)
  - `content` (string)
  - `excerpt` (string)
  - `category` (string)
  - `readingTime` (string)
  - `featured` (boolean)

## Environment Variables
The backend requires the following bindings (configured via `wrangler.jsonc` or Cloudflare Dashboard):

- `SUPABASE_URL`: The URL of your Supabase project.
- `SUPABASE_SERVICE_ROLE`: The service role key for Supabase (bypasses RLS).
- `API_KEY`: A shared secret used to authenticate `POST` requests via the `X-API-KEY` header.

## Getting Started

### Installation
```bash
npm install
```

### Local Development
Run the backend locally using Wrangler:
```bash
npm run dev
```

### Deployment
Deploy the worker to Cloudflare:
```bash
npm run deploy
```

### Type Generation
To generate TypeScript types based on your Wrangler configuration:
```bash
npm run cf-typegen
```

## Implementation Details
- **Routing**: Defined in `src/index.ts` and split into route modules in `src/routes/`.
- **Data Access**: Abstracted into repositories in `src/repositories/` for better maintainability.
- **Validation**: Input payloads are validated using Zod schemas defined in `src/schema/`.
