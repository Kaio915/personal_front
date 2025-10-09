"use client"

import { useAuth } from "@/lib/auth-context"
import { useAdmin } from "@/lib/admin-context"
import { useRouter } from "next/navigation"
import { useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Separator } from "@/components/ui/separator"
import { Shield, UserCheck, UserX, Users, Dumbbell, LogOut } from "lucide-react"
import { BackButton } from "@/components/back-button"

export default function AdminDashboard() {
  const { user, logout } = useAuth()
  const { pendingRegistrations, approveRegistration, rejectRegistration, refreshPending } = useAdmin()
  const router = useRouter()

  useEffect(() => {
    if (!user) {
      router.push("/login")
    } else if (user.userType !== "admin") {
      router.push("/")
    } else {
      console.log("[v0] Admin dashboard mounted, refreshing pending registrations")
      refreshPending()
    }
  }, [user, router, refreshPending])

  useEffect(() => {
    console.log("[v0] Pending registrations updated:", pendingRegistrations)
  }, [pendingRegistrations])

  if (!user || user.userType !== "admin") {
    return null
  }

  const pendingTrainers = pendingRegistrations.filter((r) => r.userType === "trainer")
  const pendingStudents = pendingRegistrations.filter((r) => r.userType === "student")

  console.log("[v0] Pending trainers:", pendingTrainers)
  console.log("[v0] Pending students:", pendingStudents)

  const handleApprove = (id: string) => {
    console.log("[v0] Approve button clicked for:", id)
    approveRegistration(id)
  }

  const handleReject = (id: string) => {
    if (confirm("Tem certeza que deseja rejeitar este cadastro?")) {
      console.log("[v0] Reject confirmed for:", id)
      rejectRegistration(id)
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-background to-muted">
      <header className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <BackButton />
            <div className="flex items-center gap-2">
              <Shield className="h-8 w-8 text-primary" />
              <div>
                <h1 className="text-2xl font-bold">Painel Administrativo</h1>
                <p className="text-sm text-muted-foreground">{user.name}</p>
              </div>
            </div>
          </div>
          <Button variant="outline" onClick={logout}>
            <LogOut className="h-4 w-4 mr-2" />
            Sair
          </Button>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8">
        <div className="grid gap-6 md:grid-cols-2 mb-8">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Dumbbell className="h-5 w-5" />
                Personal Trainers Pendentes
              </CardTitle>
              <CardDescription>Solicitações de cadastro aguardando aprovação</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">{pendingTrainers.length}</div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Users className="h-5 w-5" />
                Alunos Pendentes
              </CardTitle>
              <CardDescription>Solicitações de cadastro aguardando aprovação</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">{pendingStudents.length}</div>
            </CardContent>
          </Card>
        </div>

        <div className="space-y-8">
          <section>
            <h2 className="text-2xl font-bold mb-4">Personal Trainers Pendentes</h2>
            {pendingTrainers.length === 0 ? (
              <Card>
                <CardContent className="py-8 text-center text-muted-foreground">
                  Nenhuma solicitação de Personal Trainer pendente
                </CardContent>
              </Card>
            ) : (
              <div className="space-y-4">
                {pendingTrainers.map((registration) => (
                  <Card key={registration.id}>
                    <CardHeader>
                      <div className="flex items-start justify-between">
                        <div className="space-y-1">
                          <CardTitle>{registration.name}</CardTitle>
                          <CardDescription>{registration.email}</CardDescription>
                        </div>
                        <Badge>Personal Trainer</Badge>
                      </div>
                    </CardHeader>
                    <CardContent className="space-y-4">
                      <div className="grid gap-2 text-sm">
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">CREF:</span>
                          <span className="font-medium">{registration.cref}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">Cidade:</span>
                          <span className="font-medium">{registration.city}</span>
                        </div>
                        {registration.specialty && (
                          <div className="flex justify-between">
                            <span className="text-muted-foreground">Especialidade:</span>
                            <span className="font-medium">{registration.specialty}</span>
                          </div>
                        )}
                        {registration.experience && (
                          <div className="flex justify-between">
                            <span className="text-muted-foreground">Experiência:</span>
                            <span className="font-medium">{registration.experience}</span>
                          </div>
                        )}
                        {registration.hourlyRate && (
                          <div className="flex justify-between">
                            <span className="text-muted-foreground">Valor/Hora:</span>
                            <span className="font-medium">{registration.hourlyRate}</span>
                          </div>
                        )}
                        {registration.bio && (
                          <div className="space-y-1">
                            <span className="text-muted-foreground">Biografia:</span>
                            <p className="text-sm">{registration.bio}</p>
                          </div>
                        )}
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">Data de Cadastro:</span>
                          <span className="font-medium">
                            {new Date(registration.registrationDate).toLocaleDateString("pt-BR")}
                          </span>
                        </div>
                      </div>

                      <Separator />

                      <div className="flex gap-2">
                        <Button className="flex-1" variant="default" onClick={() => handleApprove(registration.id)}>
                          <UserCheck className="h-4 w-4 mr-2" />
                          Aprovar
                        </Button>
                        <Button className="flex-1" variant="destructive" onClick={() => handleReject(registration.id)}>
                          <UserX className="h-4 w-4 mr-2" />
                          Rejeitar
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </section>

          <section>
            <h2 className="text-2xl font-bold mb-4">Alunos Pendentes</h2>
            {pendingStudents.length === 0 ? (
              <Card>
                <CardContent className="py-8 text-center text-muted-foreground">
                  Nenhuma solicitação de Aluno pendente
                </CardContent>
              </Card>
            ) : (
              <div className="space-y-4">
                {pendingStudents.map((registration) => (
                  <Card key={registration.id}>
                    <CardHeader>
                      <div className="flex items-start justify-between">
                        <div className="space-y-1">
                          <CardTitle>{registration.name}</CardTitle>
                          <CardDescription>{registration.email}</CardDescription>
                        </div>
                        <Badge variant="secondary">Aluno</Badge>
                      </div>
                    </CardHeader>
                    <CardContent className="space-y-4">
                      <div className="grid gap-2 text-sm">
                        {registration.goals && (
                          <div className="space-y-1">
                            <span className="text-muted-foreground">Objetivos:</span>
                            <p className="text-sm">{registration.goals}</p>
                          </div>
                        )}
                        {registration.fitnessLevel && (
                          <div className="flex justify-between">
                            <span className="text-muted-foreground">Nível:</span>
                            <span className="font-medium">{registration.fitnessLevel}</span>
                          </div>
                        )}
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">Data de Cadastro:</span>
                          <span className="font-medium">
                            {new Date(registration.registrationDate).toLocaleDateString("pt-BR")}
                          </span>
                        </div>
                      </div>

                      <Separator />

                      <div className="flex gap-2">
                        <Button className="flex-1" variant="default" onClick={() => handleApprove(registration.id)}>
                          <UserCheck className="h-4 w-4 mr-2" />
                          Aprovar
                        </Button>
                        <Button className="flex-1" variant="destructive" onClick={() => handleReject(registration.id)}>
                          <UserX className="h-4 w-4 mr-2" />
                          Rejeitar
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </section>
        </div>
      </main>
    </div>
  )
}
