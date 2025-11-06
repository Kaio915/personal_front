"use client"

import type React from "react"

import { useState, useEffect } from "react"
import { useAuth } from "@/lib/auth-context"
import { useRouter, useSearchParams } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Textarea } from "@/components/ui/textarea"
import { Dumbbell, CheckCircle } from "lucide-react"
import Link from "next/link"
import { BackButton } from "@/components/back-button"

export default function SignupPage() {
  const { signup, user } = useAuth()
  const router = useRouter()
  const searchParams = useSearchParams()
  const typeParam = searchParams.get("type")

  const [activeTab, setActiveTab] = useState<"student" | "trainer">(typeParam === "trainer" ? "trainer" : "student")
  const [error, setError] = useState("")
  const [success, setSuccess] = useState(false)

  const [studentData, setStudentData] = useState({
    name: "",
    email: "",
    password: "",
    goals: "",
    fitnessLevel: "",
  })

  const [trainerData, setTrainerData] = useState({
    name: "",
    email: "",
    password: "",
    specialty: "",
    cref: "",
    experience: "",
    bio: "",
    hourlyRate: "",
    city: "", // Added city field
  })

  useEffect(() => {
    if (user) {
      router.push(user.userType === "trainer" ? "/dashboard/trainer" : "/dashboard/student")
    }
  }, [user, router])

  const handleStudentSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError("")
    setSuccess(false)

    if (!studentData.name || !studentData.email || !studentData.password) {
      setError("Por favor, preencha todos os campos obrigatórios")
      return
    }

    const successResult = await signup({
      ...studentData,
      userType: "student",
    })

    if (successResult) {
      setSuccess(true)
    } else {
      setError("Email já cadastrado ou erro ao criar conta")
    }
  }

  const handleTrainerSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError("")
    setSuccess(false)

    if (!trainerData.name || !trainerData.email || !trainerData.password || !trainerData.cref || !trainerData.city) {
      setError("Por favor, preencha todos os campos obrigatórios")
      return
    }

    const successResult = await signup({
      ...trainerData,
      userType: "trainer",
    })

    if (successResult) {
      setSuccess(true)
    } else {
      setError("Email já cadastrado ou erro ao criar conta")
    }
  }

  if (success) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-background to-muted flex items-center justify-center p-4">
        <Card className="w-full max-w-md">
          <CardHeader className="text-center">
            <div className="flex justify-center mb-4">
              <CheckCircle className="h-16 w-16 text-green-500" />
            </div>
            <CardTitle className="text-2xl">Cadastro Enviado!</CardTitle>
            <CardDescription className="text-base">
              Seu cadastro foi enviado com sucesso e está aguardando aprovação do administrador. Você receberá uma
              notificação quando seu cadastro for aprovado.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Button className="w-full" asChild>
              <Link href="/">Voltar para Início</Link>
            </Button>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-background to-muted flex items-center justify-center p-4">
      <div className="absolute top-4 left-4">
        <BackButton />
      </div>

      <Card className="w-full max-w-2xl">
        <CardHeader className="text-center">
          <div className="flex justify-center mb-4">
            <Dumbbell className="h-12 w-12 text-primary" />
          </div>
          <CardTitle className="text-3xl">Criar Conta</CardTitle>
          <CardDescription>Escolha o tipo de conta e preencha seus dados</CardDescription>
        </CardHeader>
        <CardContent>
          <Tabs value={activeTab} onValueChange={(v) => setActiveTab(v as "student" | "trainer")}>
            <TabsList className="grid w-full grid-cols-2 mb-6">
              <TabsTrigger value="student">Aluno</TabsTrigger>
              <TabsTrigger value="trainer">Personal Trainer</TabsTrigger>
            </TabsList>

            {/* Student Signup */}
            <TabsContent value="student">
              <form onSubmit={handleStudentSubmit} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="student-name">Nome Completo *</Label>
                  <Input
                    id="student-name"
                    value={studentData.name}
                    onChange={(e) => setStudentData({ ...studentData, name: e.target.value })}
                    placeholder="Seu nome"
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="student-email">Email *</Label>
                  <Input
                    id="student-email"
                    type="email"
                    value={studentData.email}
                    onChange={(e) => setStudentData({ ...studentData, email: e.target.value })}
                    placeholder="seu@email.com"
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="student-password">Senha *</Label>
                  <Input
                    id="student-password"
                    type="password"
                    value={studentData.password}
                    onChange={(e) => setStudentData({ ...studentData, password: e.target.value })}
                    placeholder="Mínimo 6 caracteres"
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="student-goals">Objetivos</Label>
                  <Textarea
                    id="student-goals"
                    value={studentData.goals}
                    onChange={(e) => setStudentData({ ...studentData, goals: e.target.value })}
                    placeholder="Ex: Perder peso, ganhar massa muscular..."
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="student-level">Nível de Condicionamento</Label>
                  <Input
                    id="student-level"
                    value={studentData.fitnessLevel}
                    onChange={(e) => setStudentData({ ...studentData, fitnessLevel: e.target.value })}
                    placeholder="Ex: Iniciante, Intermediário, Avançado"
                  />
                </div>

                {error && <p className="text-sm text-destructive">{error}</p>}

                <Button type="submit" className="w-full">
                  Criar Conta de Aluno
                </Button>
              </form>
            </TabsContent>

            {/* Trainer Signup */}
            <TabsContent value="trainer">
              <form onSubmit={handleTrainerSubmit} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="trainer-name">Nome Completo *</Label>
                  <Input
                    id="trainer-name"
                    value={trainerData.name}
                    onChange={(e) => setTrainerData({ ...trainerData, name: e.target.value })}
                    placeholder="Seu nome"
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="trainer-email">Email *</Label>
                  <Input
                    id="trainer-email"
                    type="email"
                    value={trainerData.email}
                    onChange={(e) => setTrainerData({ ...trainerData, email: e.target.value })}
                    placeholder="seu@email.com"
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="trainer-password">Senha *</Label>
                  <Input
                    id="trainer-password"
                    type="password"
                    value={trainerData.password}
                    onChange={(e) => setTrainerData({ ...trainerData, password: e.target.value })}
                    placeholder="Mínimo 6 caracteres"
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="trainer-cref">CREF *</Label>
                  <Input
                    id="trainer-cref"
                    value={trainerData.cref}
                    onChange={(e) => setTrainerData({ ...trainerData, cref: e.target.value })}
                    placeholder="Número do CREF"
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="trainer-city">Cidade *</Label>
                  <Input
                    id="trainer-city"
                    value={trainerData.city}
                    onChange={(e) => setTrainerData({ ...trainerData, city: e.target.value })}
                    placeholder="Ex: São Paulo, Rio de Janeiro"
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="trainer-specialty">Especialidade</Label>
                  <Input
                    id="trainer-specialty"
                    value={trainerData.specialty}
                    onChange={(e) => setTrainerData({ ...trainerData, specialty: e.target.value })}
                    placeholder="Ex: Musculação, Funcional, Emagrecimento"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="trainer-experience">Experiência</Label>
                  <Input
                    id="trainer-experience"
                    value={trainerData.experience}
                    onChange={(e) => setTrainerData({ ...trainerData, experience: e.target.value })}
                    placeholder="Ex: 5 anos"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="trainer-rate">Valor por Hora</Label>
                  <Input
                    id="trainer-rate"
                    value={trainerData.hourlyRate}
                    onChange={(e) => setTrainerData({ ...trainerData, hourlyRate: e.target.value })}
                    placeholder="Ex: R$ 100"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="trainer-bio">Biografia</Label>
                  <Textarea
                    id="trainer-bio"
                    value={trainerData.bio}
                    onChange={(e) => setTrainerData({ ...trainerData, bio: e.target.value })}
                    placeholder="Conte um pouco sobre você e sua metodologia..."
                  />
                </div>

                {error && <p className="text-sm text-destructive">{error}</p>}

                <Button type="submit" className="w-full">
                  Criar Conta de Personal Trainer
                </Button>
              </form>
            </TabsContent>
          </Tabs>

          <div className="mt-6 text-center text-sm">
            Já tem uma conta?{" "}
            <Link href="/login" className="text-primary hover:underline">
              Entrar
            </Link>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
