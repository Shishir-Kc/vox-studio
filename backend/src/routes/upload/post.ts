import { upload_post_schema } from "../../schema/upload/post";
import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { createdb } from "../../lib/db";
import { upload_post } from "../../repositories/upload/post.upload";

const app = new Hono<{ Bindings: Bindings }>();

type Bindings = {
  SUPABASE_URL: string;
  SUPABASE_SERVICE_ROLE: string;
  API_KEY: string
}

app.post("/post", zValidator('json', upload_post_schema), async (c) => {
  const api_key = c.req.header("X-API-KEY")

  //
  // api valids here boiiiii
  //

  if (!api_key || api_key !== c.env.API_KEY) {
    return c.json(({
      "error": "missing_api_key or api_key_is_invalid",
    }), 401)
  }




  try {
    const data = c.req.valid('json');
    const db = createdb(c.env.SUPABASE_URL, c.env.SUPABASE_SERVICE_ROLE);
    const post = await upload_post(db, data);
    return c.json({
      'message': "post_uploaded"
    }, 200)
  }
  catch (err) {
    return c.json({
      "message": "failed to upload post"
    }, 500)
  }
})

export default app
