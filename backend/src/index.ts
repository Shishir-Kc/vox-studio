import { Hono } from 'hono'
import read from './routes/read/read'
import upload from './routes/upload/post'
import { cors } from 'hono/cors'

const app = new Hono()

app.use(
  '*',
  cors({
    origin: '*', // Match your frontend URL here!
    allowHeaders: ['Content-Type', 'Authorization'],
    allowMethods: ['POST', 'GET', 'OPTIONS', 'PUT', 'DELETE'],
    credentials: true,
  })
)

app.get('/', (c) => {
  return c.text('Hello USER')
})
app.route("/vox", read)
app.route('/vox/upload', upload)

export default app
