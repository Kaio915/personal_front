"use client"

import { useAuth } from "@/lib/auth-context"
import { useRouter } from "next/navigation"
import { useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Dumbbell, Users, Search, TrendingUp } from "lucide-react"
import Link from "next/link"

export default function HomePage() {
  const { user } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (user) {
      if (user.userType === "admin") {
        router.push("/dashboard/admin")
      } else if (user.userType === "trainer") {
        router.push("/dashboard/trainer")
      } else {
        router.push("/dashboard/student")
      }
    }
  }, [user, router])

  return (
    <div className="min-h-screen bg-gradient-to-b from-background to-muted">
      {/* Header */}
      <header className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Dumbbell className="h-8 w-8 text-primary" />
            <h1 className="text-2xl font-bold">FitConnect</h1>
          </div>
          <div className="flex gap-3">
            <Button variant="ghost" asChild>
              <Link href="/login">Entrar</Link>
            </Button>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="container mx-auto px-4 py-20 text-center">
        <h2 className="text-5xl font-bold mb-6 text-balance">Conecte-se com os Melhores Personal Trainers</h2>
        <p className="text-xl text-muted-foreground mb-8 max-w-2xl mx-auto text-pretty">
          A plataforma que une profissionais de educação física qualificados com alunos em busca de resultados reais
        </p>
        <div className="flex gap-4 justify-center">
          <Button size="lg" asChild>
            <Link href="/login?type=student">Login como Aluno</Link>
          </Button>
          <Button size="lg" variant="outline" asChild>
            <Link href="/login?type=trainer">Login como Personal Trainer</Link>
          </Button>
        </div>
      </section>

      {/* Features */}
      <section className="container mx-auto px-4 py-16">
        <div className="grid md:grid-cols-3 gap-8">
          <Card>
            <CardHeader>
              <Search className="h-12 w-12 mb-4 text-primary" />
              <CardTitle>Busca Inteligente</CardTitle>
              <CardDescription>
                Encontre personal trainers por especialidade, localização e disponibilidade
              </CardDescription>
            </CardHeader>
          </Card>

          <Card>
            <CardHeader>
              <Users className="h-12 w-12 mb-4 text-primary" />
              <CardTitle>Conexão Direta</CardTitle>
              <CardDescription>Conecte-se diretamente com profissionais qualificados e certificados</CardDescription>
            </CardHeader>
          </Card>

          <Card>
            <CardHeader>
              <TrendingUp className="h-12 w-12 mb-4 text-primary" />
              <CardTitle>Acompanhamento</CardTitle>
              <CardDescription>Gerencie suas conexões e acompanhe seu progresso em um só lugar</CardDescription>
            </CardHeader>
          </Card>
        </div>
      </section>

      {/* CTA Section */}
      <section className="container mx-auto px-4 py-20 text-center">
        <Card className="max-w-3xl mx-auto bg-primary text-primary-foreground">
          <CardHeader>
            <CardTitle className="text-3xl">Pronto para começar?</CardTitle>
            <CardDescription className="text-primary-foreground/80 text-lg">
              Cadastre-se agora e dê o primeiro passo para alcançar seus objetivos
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Button size="lg" variant="secondary" asChild>
              <Link href="/signup">Criar Conta Gratuita</Link>
            </Button>
          </CardContent>
        </Card>
      </section>
    </div>
  )
}
