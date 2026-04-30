import { createClient } from "@supabase/supabase-js";


/*
 * i am using service_role key instead of annon 
 */

export const createdb = (url: string, key: string) => {
  return createClient(url, key);
}
