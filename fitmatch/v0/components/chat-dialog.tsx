"use client"

import { useState, useEffect, useRef } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { ScrollArea } from "@/components/ui/scroll-area"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Send } from "lucide-react"
import { useChat } from "@/lib/chat-context"

interface ChatDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  currentUserId: string
  currentUserName: string
  otherUserId: string
  otherUserName: string
}

export function ChatDialog({
  open,
  onOpenChange,
  currentUserId,
  currentUserName,
  otherUserId,
  otherUserName,
}: ChatDialogProps) {
  const { getConversation, sendMessage } = useChat()
  const [messageText, setMessageText] = useState("")
  const scrollRef = useRef<HTMLDivElement>(null)

  const conversation = getConversation(currentUserId, otherUserId)

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight
    }
  }, [conversation])

  const handleSend = () => {
    if (!messageText.trim()) return

    sendMessage(currentUserId, currentUserName, otherUserId, messageText)
    setMessageText("")
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[600px] h-[600px] flex flex-col">
        <DialogHeader>
          <DialogTitle>Chat com {otherUserName}</DialogTitle>
        </DialogHeader>

        <ScrollArea className="flex-1 pr-4" ref={scrollRef}>
          <div className="space-y-4">
            {conversation.length === 0 ? (
              <p className="text-center text-muted-foreground py-8">Nenhuma mensagem ainda. Inicie a conversa!</p>
            ) : (
              conversation.map((msg) => {
                const isCurrentUser = msg.senderId === currentUserId
                return (
                  <div key={msg.id} className={`flex gap-3 ${isCurrentUser ? "flex-row-reverse" : ""}`}>
                    <Avatar className="h-8 w-8">
                      <AvatarFallback className="text-xs">{msg.senderName.charAt(0)}</AvatarFallback>
                    </Avatar>
                    <div className={`flex flex-col ${isCurrentUser ? "items-end" : "items-start"} max-w-[70%]`}>
                      <div
                        className={`rounded-lg px-4 py-2 ${
                          isCurrentUser ? "bg-primary text-primary-foreground" : "bg-muted"
                        }`}
                      >
                        <p className="text-sm">{msg.content}</p>
                      </div>
                      <span className="text-xs text-muted-foreground mt-1">
                        {new Date(msg.timestamp).toLocaleTimeString("pt-BR", {
                          hour: "2-digit",
                          minute: "2-digit",
                        })}
                      </span>
                    </div>
                  </div>
                )
              })
            )}
          </div>
        </ScrollArea>

        <div className="flex gap-2 pt-4 border-t">
          <Input
            placeholder="Digite sua mensagem..."
            value={messageText}
            onChange={(e) => setMessageText(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && handleSend()}
          />
          <Button onClick={handleSend} size="icon">
            <Send className="h-4 w-4" />
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}
