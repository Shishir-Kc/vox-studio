import { Hono } from 'hono'
import read from './routes/read/read'
import upload from './routes/upload/post'
import { cors } from 'hono/cors'

const app = new Hono()

app.use(
  cors({
    origin: ['https://shishirkhatri.com.np', 'https://blog.shishirkhatri.com.np', 'http://localhost:5173'],
    allowHeaders: ['Content-Type', 'Authorization', 'X-API-KEY'],
    allowMethods: ['GET', 'POST'],
    credentials: true,
  })
)
app.get('/', (c) => {
  return c.text('Hello USER')
})
app.route("/vox", read)
app.route('/vox/upload', upload)

export default app
