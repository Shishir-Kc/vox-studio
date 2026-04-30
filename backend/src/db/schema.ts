import { pgTable, uuid, text, boolean, timestamp } from "drizzle-orm/pg-core";

export const read_post_data_schema = pgTable("post", {
  id: uuid("id").primaryKey().defaultRandom(),
  slug: text("slug").notNull(),
  title: text("title").notNull(),
  excerpt: text("excerpt").notNull(),
  content: text("content").notNull(),
  date: timestamp("date").defaultNow(),
  category: text("category").notNull(),
  readingTime: text("readingTime").notNull(),
  featured: boolean("featured").notNull(),
});

/*
 * i really dont know why i added this ' shema ' 
 *
 */
