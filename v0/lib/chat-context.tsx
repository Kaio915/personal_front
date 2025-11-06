"use client"

import { createContext, useContext, useState, useEffect, type ReactNode } from "react"

export interface Message {
  id: string
  senderId: string
  senderName: string
  receiverId: string
  content: string
  timestamp: string
}

interface ChatContextType {
  messages: Message[]
  sendMessage: (senderId: string, senderName: string, receiverId: string, content: string) => void
  getConversation: (userId1: string, userId2: string) => Message[]
}

const ChatContext = createContext<ChatContextType | undefined>(undefined)

export function ChatProvider({ children }: { children: ReactNode }) {
  const [messages, setMessages] = useState<Message[]>([])

  useEffect(() => {
    const storedMessages = localStorage.getItem("messages")
    if (storedMessages) {
      setMessages(JSON.parse(storedMessages))
    }
  }, [])

  const saveMessages = (newMessages: Message[]) => {
    setMessages(newMessages)
    localStorage.setItem("messages", JSON.stringify(newMessages))
  }

  const sendMessage = (senderId: string, senderName: string, receiverId: string, content: string) => {
    const newMessage: Message = {
      id: Date.now().toString(),
      senderId,
      senderName,
      receiverId,
      content,
      timestamp: new Date().toISOString(),
    }

    saveMessages([...messages, newMessage])
  }

  const getConversation = (userId1: string, userId2: string) => {
    return messages
      .filter(
        (msg) =>
          (msg.senderId === userId1 && msg.receiverId === userId2) ||
          (msg.senderId === userId2 && msg.receiverId === userId1),
      )
      .sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime())
  }

  return (
    <ChatContext.Provider
      value={{
        messages,
        sendMessage,
        getConversation,
      }}
    >
      {children}
    </ChatContext.Provider>
  )
}

export function useChat() {
  const context = useContext(ChatContext)
  if (context === undefined) {
    throw new Error("useChat must be used within a ChatProvider")
  }
  return context
}
