
export const get_all_posts = async (db: any) => {
  const { data, error } = await db.from("post").select("*");
  console.log(data)
  if (error) throw error;
  return data
}
