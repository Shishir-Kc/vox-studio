import { useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Upload, FileText, BookOpen, Send, Clock, Calendar, Hash, ArrowRight, Zap, Shield, HelpCircle, Settings, X } from 'lucide-react'
import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'
import remarkBreaks from 'remark-breaks'
import { Spinner } from "@/components/ui/spinner"
import {
  NavigationMenu,
  NavigationMenuContent,
  NavigationMenuItem,
  NavigationMenuLink,
  NavigationMenuList,
  NavigationMenuTrigger,
} from "@/components/ui/navigation-menu"

type Page = 'upload' | 'posts' | 'settings'

interface Post {
  id: string
  slug: string
  title: string
  excerpt: string
  content: string
  date: string
  category: string
  readingTime: string
  featured: boolean
}

export default function App() {
  const [activePage, setActivePage] = useState<Page>('upload')
  const [posts, setPosts] = useState<Post[]>([])
  const [content, setContent] = useState('')
  const [isPublishing, setIsPublishing] = useState(false)
  const [isPublishModalOpen, setIsPublishModalOpen] = useState(false)
  const [isShortcutsOpen, setIsShortcutsOpen] = useState(false)
  const [isLoadingPosts, setIsLoadingPosts] = useState(false)
  const editorRef = useRef<HTMLTextAreaElement>(null)
  const [publishForm, setPublishForm] = useState({
    slug: '',
    title: '',
    excerpt: '',
    category: 'Draft',
    readingTime: '',
    featured: false
  })
  
  // Settings State
  const [apiKey, setApiKey] = useState(() => localStorage.getItem('vox_api_key') || '')
  const [apiEndpoint, setApiEndpoint] = useState(() => 
    localStorage.getItem('vox_api_endpoint') || import.meta.env.VITE_API_URL || ''
  )

  useEffect(() => {
    if (apiEndpoint) {
      localStorage.setItem('vox_api_endpoint', apiEndpoint)
    } else {
      localStorage.removeItem('vox_api_endpoint')
    }
  }, [apiEndpoint])

  useEffect(() => {
    if (apiKey) {
      localStorage.setItem('vox_api_key', apiKey)
    } else {
      localStorage.removeItem('vox_api_key')
    }
  }, [apiKey])

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.ctrlKey && e.key === '.') {
        e.preventDefault()
        setIsShortcutsOpen(prev => !prev)
      }
      if (isShortcutsOpen && e.key === 'Escape') {
        setIsShortcutsOpen(false)
      }
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [isShortcutsOpen])

  const insertText = (text: string, cursorOffset: number = 0) => {
    const editor = editorRef.current
    if (!editor) return

    const start = editor.selectionStart
    const end = editor.selectionEnd
    const newValue = content.substring(0, start) + text + content.substring(end)
    
    setContent(newValue)

    // Set focus back and position cursor
    setTimeout(() => {
      editor.focus()
      const newPos = start + cursorOffset
      editor.setSelectionRange(newPos, newPos)
    }, 0)
  }

  const getApiUrl = (path: string) => {
    const base = apiEndpoint || import.meta.env.VITE_API_URL || ''
    return `${base}${path}`
  }

  const fetchPosts = async () => {
    setIsLoadingPosts(true)
    try {
      const url = getApiUrl('/vox/posts')
      const headers: Record<string, string> = {}
      
      if (apiKey) {
        headers['X-API-KEY'] = apiKey
      }

      const response = await fetch(url, { headers })
      
      if (!response.ok) {
        throw new Error('Failed to fetch posts')
      }

      const data = await response.json()
      setPosts(data)
    } catch (error) {
      console.error('Error fetching posts:', error)
    } finally {
      setIsLoadingPosts(false)
    }
  }

  useEffect(() => {
    if (activePage === 'posts') {
      fetchPosts()
    }
  }, [activePage, apiEndpoint, apiKey])

  const navItems = [
    { key: 'upload', label: 'Studio', icon: Upload, description: 'Create and edit your stories' },
    { key: 'posts', label: 'Posts', icon: FileText, description: 'View your published entries' },
    { key: 'settings', label: 'Settings', icon: Settings, description: 'Configure application settings' },
  ] as const

  const openPublishModal = () => {
    if (!content.trim()) return
    setPublishForm({
      slug: content.slice(0, 30).toLowerCase().replace(/\s+/g, '-'),
      title: content.slice(0, 50) + (content.length > 50 ? '...' : ''),
      excerpt: content.slice(0, 100) + (content.length > 100 ? '...' : ''),
      category: 'Draft',
      readingTime: `${Math.max(1, Math.ceil(content.split(' ').length / 200))} min read`,
      featured: false
    })
    setIsPublishModalOpen(true)
  }

  const handlePublishConfirm = async () => {
    setIsPublishing(true)
    
    try {
      const endpoint = apiEndpoint || import.meta.env.VITE_API_URL || ''
      const url = `${endpoint}/vox/upload/post`
      
      const headers: Record<string, string> = {
        'Content-Type': 'application/json'
      }
      
      if (apiKey) {
        headers['X-API-KEY'] = apiKey
      }
      
      const response = await fetch(url, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          title: publishForm.title,
          content: content,
          slug: publishForm.slug,
          excerpt: publishForm.excerpt,
          category: publishForm.category,
          readingTime: publishForm.readingTime,
          featured: publishForm.featured
        })
      });

      if (!response.ok) {
        throw new Error('Failed to publish post');
      }

      const newPost: Post = {
        id: crypto.randomUUID(),
        ...publishForm,
        content,
        date: new Date().toISOString(),
      }
      
      setPosts([newPost, ...posts])
      setContent('')
      setIsPublishModalOpen(false)
      setActivePage('posts')
    } catch (error) {
      console.error('Error publishing post:', error);
    } finally {
      setIsPublishing(false)
    }
  }

  const pageVariants: any = {
    initial: { opacity: 0, y: 20 },
    animate: { opacity: 1, y: 0, transition: { duration: 0.4, ease: "easeOut" } },
    exit: { opacity: 0, y: -20, transition: { duration: 0.3 } }
  }

  return (
    <div className="min-h-screen bg-[var(--color-rich-black)] text-white selection:bg-[var(--color-charcoal)] selection:text-white flex flex-col font-sans">
      {/* Premium Navigation Header */}
      <header className="absolute top-0 left-0 right-0 z-50 w-full bg-transparent">
        <div className="container mx-auto max-w-6xl px-6 h-20 flex items-center justify-center">
          <NavigationMenu>
            <NavigationMenuList className="gap-2">
              {navItems.map((item) => {
                const Icon = item.icon
                const isActive = activePage === item.key
                
                const baseLinkClass = `inline-flex items-center justify-center transition-colors relative h-10 px-4 py-2 rounded-xl cursor-pointer outline-none ${
                  isActive ? 'text-white' : 'text-[var(--color-dim-gray)] hover:text-white'
                }`

                const content = (
                  <div className="flex items-center gap-2 relative z-10">
                    <Icon className="w-4 h-4 text-current" />
                    <span className="font-medium text-sm">{item.label}</span>
                  </div>
                )

                const activeIndicator = isActive && (
                  <motion.div
                    layoutId="nav-active"
                    className="absolute inset-0 bg-[var(--color-onyx)] rounded-xl border border-[var(--color-charcoal)]/30"
                    transition={{ type: "spring", bounce: 0.2, duration: 0.6 }}
                  />
                )

                return (
                  <NavigationMenuItem key={item.key}>
                    <NavigationMenuLink
                      onClick={() => setActivePage(item.key)}
                      className={baseLinkClass + " bg-transparent"}
                    >
                      {activeIndicator}
                      {content}
                    </NavigationMenuLink>
                  </NavigationMenuItem>
                )
              })}
            </NavigationMenuList>
          </NavigationMenu>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 w-full px-6 pt-24 pb-6 flex flex-col min-h-0">
        <AnimatePresence mode="wait">
          
          {activePage === 'upload' && (
            <motion.div
              key="upload"
              variants={pageVariants}
              initial="initial"
              animate="animate"
              exit="exit"
              className="flex-1 w-full flex gap-6 overflow-hidden min-h-0"
              style={{ height: 'calc(100vh - 8rem)' }}
            >
              {/* Left Side: Editor */}
              <div className="flex-1 flex flex-col bg-[var(--color-jet-black)] rounded-3xl border border-[var(--color-eerie-black)] p-2 shadow-2xl relative overflow-hidden min-h-0">
                <form
                  onSubmit={(e) => { e.preventDefault(); openPublishModal(); }}
                  className="flex-1 flex flex-col bg-[var(--color-rich-black)] rounded-2xl border border-[var(--color-eerie-black)] p-6 space-y-4 min-h-0"
                >
                    <textarea
                      placeholder="Write your story in Markdown..."
                      value={content}
                      ref={editorRef}
                      onKeyDown={(e) => {
                        if (e.ctrlKey && e.key === 'k') {
                          e.preventDefault()
                          insertText('[ ]( )', 1)
                        }
                        if (e.ctrlKey && e.shiftKey && e.key === 'I') {
                          e.preventDefault()
                          insertText('![ ]( )', 2)
                        }
                      }}
                      onChange={(e) => setContent(e.target.value)}
                      className="flex-1 w-full bg-transparent text-lg text-white placeholder-[var(--color-dim-gray)] focus:outline-none resize-none leading-relaxed font-mono min-h-0 overflow-y-auto"
                    />
                  
                  <div className="flex items-center justify-between pt-4 border-t border-[var(--color-eerie-black)] shrink-0">
                    <div className="text-sm text-[var(--color-dim-gray)] flex items-center gap-4">
                      <span>{content.length} characters</span>
                      <span>{content.split(/\s+/).filter(w => w.length > 0).length} words</span>
                    </div>

                    <button
                      type="submit"
                      disabled={!content.trim() || isPublishing}
                      className="group flex items-center gap-2 bg-white text-[var(--color-rich-black)] px-6 py-2.5 rounded-xl font-medium transition-all hover:bg-gray-100 hover:scale-[1.02] active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:scale-100"
                    >
                      {isPublishing ? (
                        <Spinner className="text-[var(--color-rich-black)]" />
                      ) : (
                        <>
                          Publish
                          <Send className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
                        </>
                      )}
                    </button>
                  </div>
                </form>
              </div>

              {/* Right Side: Preview */}
              <div className="flex-1 flex flex-col bg-[var(--color-jet-black)] rounded-3xl border border-[var(--color-eerie-black)] p-8 shadow-2xl overflow-y-auto min-h-0">
                <div className="prose prose-invert prose-p:text-white/80 prose-headings:text-white prose-a:text-white prose-a:underline hover:prose-a:text-white/80 prose-a:transition-colors prose-strong:text-white prose-code:text-white prose-code:bg-[var(--color-rich-black)] prose-code:px-1.5 prose-code:py-0.5 prose-code:rounded-md prose-code:before:content-none prose-code:after:content-none prose-pre:bg-[var(--color-rich-black)] prose-pre:border prose-pre:border-[var(--color-eerie-black)] prose-li:text-white/80 prose-blockquote:text-white/70 prose-blockquote:border-l-[var(--color-charcoal)] max-w-none">
                  {content ? (
                    <ReactMarkdown remarkPlugins={[remarkGfm, remarkBreaks]}>
                      {content}
                    </ReactMarkdown>
                  ) : (
                    <div className="flex items-center justify-center h-full text-white/40 italic font-sans text-lg">
                      Markdown preview will appear here...
                    </div>
                  )}
                </div>
              </div>
            </motion.div>
          )}

          {activePage === 'posts' && (
            <motion.div
              key="posts"
              variants={pageVariants}
              initial="initial"
              animate="animate"
              exit="exit"
              className="space-y-8"
            >
              {isLoadingPosts ? (
                <div className="text-center py-12">
                  <Spinner className="w-8 h-8 mx-auto mb-4" />
                  <p className="text-[var(--color-dim-gray)]">Loading posts...</p>
                </div>
              ) : posts.length === 0 ? (
                <div className="text-center py-12">
                  <FileText className="w-16 h-16 text-[var(--color-raisin-black)] mx-auto mb-6" />
                  <h3 className="text-xl font-medium mb-3">No posts yet</h3>
                  <p className="text-[var(--color-dim-gray)] max-w-md mx-auto">
                    Create your first post in the Studio to see it here.
                  </p>
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <AnimatePresence>
                    {posts.map((post, i) => (
                      <motion.article
                        key={post.id}
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.4, delay: i * 0.05 }}
                        whileHover={{ scale: 1.01, y: -4 }}
                        className="group bg-[var(--color-jet-black)] border border-[var(--color-eerie-black)] rounded-3xl p-8 hover:border-[var(--color-raisin-black)] transition-all cursor-pointer shadow-lg hover:shadow-2xl hover:shadow-[var(--color-charcoal)]/5 flex flex-col h-full relative overflow-hidden"
                      >
                        <div className="absolute top-0 right-0 p-8 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                           <ArrowRight className="w-6 h-6 text-[var(--color-dim-gray)] group-hover:text-white transition-colors" />
                        </div>

                        <div className="flex items-center gap-3 mb-6">
                          <span className="flex items-center gap-1.5 text-xs font-medium text-[var(--color-text-secondary)] bg-[var(--color-rich-black)] px-3 py-1.5 rounded-full border border-[var(--color-eerie-black)]">
                            <Hash className="w-3.5 h-3.5" />
                            {post.category}
                          </span>
                          {post.featured && (
                            <span className="flex items-center gap-1.5 text-xs font-medium text-[var(--color-rich-black)] bg-white px-3 py-1.5 rounded-full border border-white">
                              Featured
                            </span>
                          )}
                        </div>
                        
                        <h3 className="text-2xl font-semibold mb-4 pr-8 line-clamp-2 leading-tight group-hover:text-white transition-colors">{post.title}</h3>
                        <p className="text-[var(--color-dim-gray)] leading-relaxed mb-8 flex-1 line-clamp-3">
                          {post.excerpt}
                        </p>
                        
                        <div className="flex items-center gap-6 text-sm text-[var(--color-dim-gray)] border-t border-[var(--color-eerie-black)] pt-6 mt-auto">
                          <div className="flex items-center gap-2">
                            <Calendar className="w-4 h-4" />
                            {new Date(post.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                          </div>
                          <div className="flex items-center gap-2">
                            <Clock className="w-4 h-4" />
                            {post.readingTime}
                          </div>
                        </div>
                      </motion.article>
                    ))}
                  </AnimatePresence>
                </div>
              )}
            </motion.div>
          )}

          {activePage === 'settings' && (
            <motion.div
              key="settings"
              variants={pageVariants}
              initial="initial"
              animate="animate"
              exit="exit"
              className="max-w-2xl mx-auto"
            >
              <div className="mb-10">
                <h2 className="text-3xl font-bold tracking-tight mb-4">Settings</h2>
                <p className="text-[var(--color-dim-gray)] text-lg">
                  Configure your API connection and preferences.
                </p>
              </div>

              <div className="bg-[var(--color-jet-black)] border border-[var(--color-eerie-black)] rounded-3xl p-8 relative overflow-hidden shadow-2xl">
                <div className="space-y-6">
                  <div className="space-y-2">
                    <label className="text-sm font-medium text-white/80">
                      API Endpoint
                    </label>
                    <input
                      type="text"
                      placeholder="https://api.example.com/v1"
                      value={apiEndpoint}
                      onChange={(e) => setApiEndpoint(e.target.value)}
                      className="w-full bg-[var(--color-rich-black)] border border-[var(--color-eerie-black)] rounded-xl px-4 py-3 text-white placeholder-[var(--color-dim-gray)] focus:outline-none focus:border-[var(--color-charcoal)] transition-colors"
                    />
                    <p className="text-xs text-[var(--color-dim-gray)]">Settings are automatically saved</p>
                  </div>
                  
                  <div className="space-y-2">
                    <label className="text-sm font-medium text-white/80">
                      API Key
                    </label>
                    <input
                      type="password"
                      placeholder="sk-..."
                      value={apiKey}
                      onChange={(e) => setApiKey(e.target.value)}
                      className="w-full bg-[var(--color-rich-black)] border border-[var(--color-eerie-black)] rounded-xl px-4 py-3 text-white placeholder-[var(--color-dim-gray)] focus:outline-none focus:border-[var(--color-charcoal)] transition-colors"
                    />
                  </div>

                  <div className="pt-4 flex justify-end gap-3">
                    <button 
                      onClick={() => {
                        setApiEndpoint(import.meta.env.VITE_API_URL || '')
                        setApiKey('')
                      }}
                      className="px-5 py-2.5 rounded-xl font-medium text-[var(--color-dim-gray)] hover:text-white transition-colors"
                    >
                      Reset to Default
                    </button>
                  </div>
                </div>
              </div>
            </motion.div>
          )}

        </AnimatePresence>
      </main>

      {/* Publish Modal */}
      <AnimatePresence>
        {isShortcutsOpen && (
          <div className="fixed inset-0 z-[110] flex items-center justify-center p-4 sm:p-6">
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="absolute inset-0 bg-black/60 backdrop-blur-sm"
              onClick={() => setIsShortcutsOpen(false)}
            />
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 20 }}
              className="relative w-full max-w-md bg-[var(--color-jet-black)] border border-[var(--color-eerie-black)] rounded-3xl p-6 shadow-2xl overflow-hidden flex flex-col"
            >
              <div className="flex items-center justify-between mb-6 shrink-0">
                <h3 className="text-xl font-bold text-white">Keyboard Shortcuts</h3>
                <button
                  type="button"
                  onClick={() => setIsShortcutsOpen(false)}
                  className="p-2 hover:bg-[var(--color-rich-black)] rounded-full transition-colors text-[var(--color-dim-gray)] hover:text-white"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <div className="space-y-3">
                {[
                  { keys: 'Ctrl + .', action: 'Show/Hide Shortcuts' },
                  { keys: 'Ctrl + S', action: 'Publish Post' },
                  { keys: 'Ctrl + K', action: 'Insert Link' },
                  { keys: 'Ctrl + Shift + I', action: 'Insert Image' },
                  { keys: 'Ctrl + 1', action: 'Switch to Studio' },
                  { keys: 'Ctrl + 2', action: 'Switch to Posts' },
                  { keys: 'Ctrl + 3', action: 'Switch to Settings' },
                  { keys: 'Esc', action: 'Close Modal' },
                ].map((shortcut) => (
                  <div key={shortcut.keys} className="flex items-center justify-between p-3 rounded-xl bg-[var(--color-rich-black)] border border-[var(--color-eerie-black)] group hover:border-[var(--color-charcoal)] transition-colors">
                    <span className="text-sm text-[var(--color-dim-gray)] group-hover:text-white transition-colors">{shortcut.action}</span>
                    <kbd className="px-2 py-1 text-xs font-mono bg-[var(--color-onyx)] text-white border border-[var(--color-charcoal)] rounded-md shadow-sm">
                      {shortcut.keys}
                    </kbd>
                  </div>
                ))}
              </div>
              
              <div className="mt-6 text-center">
                <p className="text-xs text-[var(--color-dim-gray)]">Press <kbd className="px-1 py-0.5 bg-[var(--color-onyx)] rounded">Esc</kbd> to close</p>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {isPublishModalOpen && (

          <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 sm:p-6">
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="absolute inset-0 bg-black/60 backdrop-blur-sm"
              onClick={() => setIsPublishModalOpen(false)}
            />
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 20 }}
              className="relative w-full max-w-lg bg-[var(--color-jet-black)] border border-[var(--color-eerie-black)] rounded-3xl p-6 shadow-2xl overflow-hidden flex flex-col max-h-full"
            >
              <div className="flex items-center justify-between mb-6 shrink-0">
                <h3 className="text-xl font-bold text-white">Publish Options</h3>
                <button
                  type="button"
                  onClick={() => setIsPublishModalOpen(false)}
                  className="p-2 hover:bg-[var(--color-rich-black)] rounded-full transition-colors text-[var(--color-dim-gray)] hover:text-white"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <div className="space-y-4 overflow-y-auto flex-1 pr-2 pb-4 scrollbar-thin scrollbar-thumb-[var(--color-eerie-black)]">
                <div className="space-y-2">
                  <label className="text-sm font-medium text-[var(--color-text-secondary)] flex justify-between">
                    <span>Title</span>
                    <span className="text-[var(--color-dim-gray)] font-normal text-xs">{publishForm.title.length}/255</span>
                  </label>
                  <input
                    type="text"
                    maxLength={255}
                    value={publishForm.title}
                    onChange={(e) => setPublishForm({ ...publishForm, title: e.target.value })}
                    className="w-full bg-[var(--color-rich-black)] border border-[var(--color-eerie-black)] rounded-xl px-4 py-2.5 text-white placeholder-[var(--color-dim-gray)] focus:outline-none focus:border-[var(--color-charcoal)] transition-colors"
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-medium text-[var(--color-text-secondary)]">Slug</label>
                  <input
                    type="text"
                    value={publishForm.slug}
                    onChange={(e) => setPublishForm({ ...publishForm, slug: e.target.value })}
                    className="w-full bg-[var(--color-rich-black)] border border-[var(--color-eerie-black)] rounded-xl px-4 py-2.5 text-white placeholder-[var(--color-dim-gray)] focus:outline-none focus:border-[var(--color-charcoal)] transition-colors font-mono text-sm"
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-medium text-[var(--color-text-secondary)]">Excerpt</label>
                  <textarea
                    rows={3}
                    value={publishForm.excerpt}
                    onChange={(e) => setPublishForm({ ...publishForm, excerpt: e.target.value })}
                    className="w-full bg-[var(--color-rich-black)] border border-[var(--color-eerie-black)] rounded-xl px-4 py-2.5 text-white placeholder-[var(--color-dim-gray)] focus:outline-none focus:border-[var(--color-charcoal)] transition-colors resize-none"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <label className="text-sm font-medium text-[var(--color-text-secondary)]">Category</label>
                    <input
                      type="text"
                      value={publishForm.category}
                      onChange={(e) => setPublishForm({ ...publishForm, category: e.target.value })}
                      className="w-full bg-[var(--color-rich-black)] border border-[var(--color-eerie-black)] rounded-xl px-4 py-2.5 text-white placeholder-[var(--color-dim-gray)] focus:outline-none focus:border-[var(--color-charcoal)] transition-colors"
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="text-sm font-medium text-[var(--color-text-secondary)]">Reading Time</label>
                    <input
                      type="text"
                      value={publishForm.readingTime}
                      onChange={(e) => setPublishForm({ ...publishForm, readingTime: e.target.value })}
                      className="w-full bg-[var(--color-rich-black)] border border-[var(--color-eerie-black)] rounded-xl px-4 py-2.5 text-white placeholder-[var(--color-dim-gray)] focus:outline-none focus:border-[var(--color-charcoal)] transition-colors"
                    />
                  </div>
                </div>

                <div className="flex items-center gap-3 pt-2">
                  <button
                    type="button"
                    onClick={() => setPublishForm({ ...publishForm, featured: !publishForm.featured })}
                    className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors border ${publishForm.featured ? 'bg-white border-white' : 'bg-[var(--color-rich-black)] border-[var(--color-eerie-black)]'}`}
                  >
                    <span className={`inline-block h-4 w-4 transform rounded-full transition-transform ${publishForm.featured ? 'translate-x-6 bg-[var(--color-rich-black)]' : 'translate-x-1 bg-[var(--color-dim-gray)]'}`} />
                  </button>
                  <label className="text-sm font-medium text-[var(--color-text-secondary)] cursor-pointer select-none" onClick={() => setPublishForm({ ...publishForm, featured: !publishForm.featured })}>
                    Featured Post
                  </label>
                </div>
              </div>

              <div className="mt-6 flex justify-end gap-3 shrink-0 pt-4 border-t border-[var(--color-eerie-black)]">
                <button
                  type="button"
                  onClick={() => setIsPublishModalOpen(false)}
                  className="px-5 py-2.5 rounded-xl font-medium text-[var(--color-dim-gray)] hover:text-white transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  onClick={handlePublishConfirm}
                  disabled={isPublishing}
                  className="flex items-center gap-2 bg-white text-[var(--color-rich-black)] px-6 py-2.5 rounded-xl font-medium transition-all hover:bg-gray-100 active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isPublishing ? (
                    <Spinner className="text-[var(--color-rich-black)]" />
                  ) : (
                    <Send className="w-4 h-4" />
                  )}
                  Confirm Publish
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  )
}
