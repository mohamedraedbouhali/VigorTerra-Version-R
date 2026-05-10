import { useState, useRef, useEffect } from 'react'
import Layout from '../components/Layout'
import { useLanguage } from '../context/LanguageContext'
import './AskMePage.css'

export default function AskMePage() {
  const { t } = useLanguage()
  const [messages, setMessages] = useState([])
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)
  const [waitSeconds, setWaitSeconds] = useState(0)
  const messagesEndRef = useRef(null)
  const messageIdRef = useRef(2)
  const waitTimerRef = useRef(null)

  // Load conversation history on component mount
  useEffect(() => {
    const savedMessages = localStorage.getItem('terraChatHistory')
    if (savedMessages) {
      try {
        const parsedMessages = JSON.parse(savedMessages)
        setMessages(parsedMessages)
        // Set next message ID
        const maxId = Math.max(...parsedMessages.map(m => m.id), 1)
        messageIdRef.current = maxId + 1
      } catch (e) {
        console.error('Error loading chat history:', e)
        // Fallback to default message
        setMessages([
          {
            id: 1,
            type: 'bot',
            text: "💚 Hi! I'm Terra, your farming assistant. Ask me anything about crops, weather, or soil!"
          }
        ])
      }
    } else {
      // Default welcome message
      setMessages([
        {
          id: 1,
          type: 'bot',
          text: "💚 Hi! I'm Terra, your farming assistant. Ask me anything about crops, weather, or soil!"
        }
      ])
    }
  }, [])

  // Save conversation history whenever messages change
  useEffect(() => {
    if (messages.length > 0) {
      localStorage.setItem('terraChatHistory', JSON.stringify(messages))
    }
  }, [messages])

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }

  useEffect(() => {
    scrollToBottom()
  }, [messages])

  useEffect(() => {
    if (waitSeconds > 0) {
      waitTimerRef.current = setTimeout(() => {
        setWaitSeconds(waitSeconds - 1)
      }, 1000)
      return () => clearTimeout(waitTimerRef.current)
    }
  }, [waitSeconds])

  const quickReplies = [
    "What crops grow in Tunisia?",
    "How to improve soil?",
    "Pest control tips",
    "Best time to plant",
    "How to increase yield"
  ]

  const handleQuickReply = (question) => {
    setInput(question)
    // Auto-send after a brief delay
    setTimeout(() => {
      const fakeEvent = { preventDefault: () => { } }
      handleSendMessage(fakeEvent)
    }, 100)
  }

  const clearHistory = () => {
    setMessages([
      {
        id: 1,
        type: 'bot',
        text: "💚 Hi! I'm Terra, your farming assistant. Ask me anything about crops, weather, or soil!"
      }
    ])
    messageIdRef.current = 2
    localStorage.removeItem('terraChatHistory')
  }

  const handleSendMessage = async (e) => {
    e.preventDefault()
    if (!input.trim() || loading || waitSeconds > 0) return

    const userMessage = {
      id: messageIdRef.current++,
      type: 'user',
      text: input
    }
    const currentMessages = [...messages, userMessage]
    setMessages(currentMessages)
    setInput('')
    setLoading(true)

    try {
      // Format history for Gemini, ensuring valid alternating structure
      const validMessages = currentMessages.filter(m => !m.isError && m.id !== 1);

      const geminiHistory = validMessages.reduce((acc, current) => {
        const role = current.type === 'bot' ? 'model' : 'user';
        if (acc.length === 0) {
          if (role === 'user') acc.push({ role, parts: [{ text: current.text }] });
        } else {
          const lastIndex = acc.length - 1;
          if (acc[lastIndex].role === role) {
            acc[lastIndex].parts[0].text += '\n\n' + current.text;
          } else {
            acc.push({ role, parts: [{ text: current.text }] });
          }
        }
        return acc;
      }, []);

      const API_KEY = 'AIzaSyDlQejou_g8NubZ9hoSaZuBAt_rRPlBZ6w';
      const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=${API_KEY}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents: geminiHistory
        })
      });

      if (!response.ok) {
        const errData = await response.json().catch(() => null);
        throw new Error(errData?.error?.message || 'Error communicating with Gemini AI');
      }

      const data = await response.json();
      const answerText = data.candidates?.[0]?.content?.parts?.[0]?.text || "No response generated.";

      const botMessage = {
        id: messageIdRef.current++,
        type: 'bot',
        text: answerText
      }
      setMessages(prev => [...prev, botMessage])
    } catch (err) {
      const errorMessage = {
        id: messageIdRef.current++,
        type: 'bot',
        text: err.message || 'Sorry, I encountered an error. Please try again.',
        isError: true
      }
      setMessages(prev => [...prev, errorMessage])
    } finally {
      setLoading(false)
    }
  }

  return (
    <Layout>
      <div className="ask-me-page">
        <div className="ask-me-container">
          <div className="ask-me-header">
            <div className="header-icon">🌾</div>
            <h1>Ask Terra</h1>
          </div>

          <div className="messages-container">
            {messages.map(message => (
              <div
                key={message.id}
                className={`message ${message.type} ${message.isError ? 'error' : ''}`}
              >
                {message.type === 'bot' && <span className="bot-icon">🌱</span>}
                <div className="message-content">
                  {message.text}
                </div>
                {message.type === 'user' && <span className="user-icon">👨‍🌾</span>}
              </div>
            ))}
            {loading && (
              <div className="message bot loading">
                <span className="bot-icon">🌱</span>
                <div className="message-content">
                  <div className="typing-indicator">
                    <span></span>
                    <span></span>
                    <span></span>
                  </div>
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>

          <div className="quick-replies">
            <div className="quick-replies-title">💡 Quick Questions:</div>
            <div className="quick-replies-buttons">
              {quickReplies.map((question, index) => (
                <button
                  key={index}
                  className="quick-reply-btn"
                  onClick={() => handleQuickReply(question)}
                  disabled={loading || waitSeconds > 0}
                >
                  {question}
                </button>
              ))}
            </div>
          </div>

          <form className="input-form" onSubmit={handleSendMessage}>
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder={
                waitSeconds > 0
                  ? `Wait ${waitSeconds}s...`
                  : 'Ask Terra...'
              }
              className="message-input"
              disabled={loading || waitSeconds > 0}
            />
            <button
              type="submit"
              className="send-button"
              disabled={loading || waitSeconds > 0}
              title={waitSeconds > 0 ? `Wait ${waitSeconds} seconds` : 'Send'}
            >
              {loading ? '⏳' : waitSeconds > 0 ? '⏸️' : '✉️'}
            </button>
          </form>

          <div className="chat-controls">
            <button
              className="clear-history-btn"
              onClick={clearHistory}
              title="Clear conversation history"
            >
              🗑️ Clear History
            </button>
          </div>
        </div>
      </div>
    </Layout>
  )
}
