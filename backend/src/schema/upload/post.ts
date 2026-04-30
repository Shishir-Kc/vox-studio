import { z } from 'zod';

export const upload_post_schema = z.object(
  {
    title: z.string(),
    content: z.string(),
    slug: z.string(),
    excerpt: z.string(),
    category: z.string(),
    readingTime: z.string(),
    featured: z.boolean(),

  }
)
