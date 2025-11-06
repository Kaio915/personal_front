import type React from "react"
import type { Metadata } from "next"
import { GeistSans } from "geist/font/sans"
import { GeistMono } from "geist/font/mono"
import { Analytics } from "@vercel/analytics/next"
import "./globals.css"
import { AuthProvider } from "@/lib/auth-context"
import { ConnectionsProvider } from "@/lib/connections-context"
import { ChatProvider } from "@/lib/chat-context"
import { AdminProvider } from "@/lib/admin-context"
import { Suspense } from "react"

export const metadata: Metadata = {
  title: "FitConnect - Conecte-se com Personal Trainers",
  description: "Plataforma para conectar Personal Trainers e Alunos",
  generator: "v0.app",
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="pt-BR">
      <body className={`font-sans ${GeistSans.variable} ${GeistMono.variable}`}>
        <Suspense fallback={<div>Loading...</div>}>
          <AuthProvider>
            <AdminProvider>
              <ConnectionsProvider>
                <ChatProvider>{children}</ChatProvider>
              </ConnectionsProvider>
            </AdminProvider>
          </AuthProvider>
        </Suspense>
        <Analytics />
      </body>
    </html>
  )
}
