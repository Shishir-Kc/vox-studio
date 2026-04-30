import { Hono } from "hono"
import { get_all_posts } from "../../repositories/read/post.read";
import { createdb } from "../../lib/db";

type Bindings = {
  SUPABASE_URL: string;
  SUPABASE_SERVICE_ROLE: string
}

const app = new Hono<{ Bindings: Bindings }>();

app.get("/posts", async (c) => {
  const db = createdb(c.env.SUPABASE_URL, c.env.SUPABASE_SERVICE_ROLE);
  const posts = await get_all_posts(db);
  return c.json(posts)
})

export default app

