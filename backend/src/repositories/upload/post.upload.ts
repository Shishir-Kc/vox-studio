

export const upload_post = async (db: any, data: any) => {
  const { error } = await db.from("post").insert({
    id: crypto.randomUUID(),
    slug: data.slug,
    title: data.title,
    excerpt: data.excerpt,
    content: data.content,
    category: data.category,
    date: new Date().toISOString(),
    readingTime: data.readingTime,
    featured: data.featured,
  });
  if (error) throw error;

};
