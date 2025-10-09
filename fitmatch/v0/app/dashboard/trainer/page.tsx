"use client"

import { useAuth } from "@/lib/auth-context"
import { useConnections } from "@/lib/connections-context"
import { useRouter } from "next/navigation"
import { useEffect, useState } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Dumbbell, LogOut, Users, UserCheck, Clock, Mail, MessageSquare, UserMinus } from "lucide-react"
import Link from "next/link"
import { ChatDialog } from "@/components/chat-dialog"
import { BackButton } from "@/components/back-button"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog"

export default function TrainerDashboard() {
  const { user, logout } = useAuth()
  const { getTrainerConnections, acceptConnection, rejectConnection, disconnectConnection } = useConnections()
  const router = useRouter()
  const [activeTab, setActiveTab] = useState("overview")
  const [chatOpen, setChatOpen] = useState(false)
  const [selectedStudent, setSelectedStudent] = useState<{ id: string; name: string } | null>(null)
  const [disconnectDialogOpen, setDisconnectDialogOpen] = useState(false)
  const [studentToDisconnect, setStudentToDisconnect] = useState<{ id: string; name: string } | null>(null)

  useEffect(() => {
    if (!user || user.userType !== "trainer") {
      router.push("/login")
    }
  }, [user, router])

  if (!user || user.userType !== "trainer") {
    return null
  }

  const allConnections = getTrainerConnections(user.id)
  const pendingRequests = allConnections.filter((conn) => conn.status === "pending")
  const acceptedConnections = allConnections.filter((conn) => conn.status === "accepted")

  const handleLogout = () => {
    logout()
    router.push("/")
  }

  const handleOpenChat = (studentId: string, studentName: string) => {
    setSelectedStudent({ id: studentId, name: studentName })
    setChatOpen(true)
  }

  const handleDisconnectClick = (studentId: string, studentName: string) => {
    setStudentToDisconnect({ id: studentId, name: studentName })
    setDisconnectDialogOpen(true)
  }

  const handleConfirmDisconnect = () => {
    if (studentToDisconnect && user) {
      disconnectConnection(studentToDisconnect.id, user.id)
      setDisconnectDialogOpen(false)
      setStudentToDisconnect(null)
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-background to-muted">
      {/* Header */}
      <header className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-2">
            <Dumbbell className="h-8 w-8 text-primary" />
            <h1 className="text-2xl font-bold">FitConnect</h1>
          </Link>
          <div className="flex items-center gap-4">
            <BackButton />
            <div className="text-right">
              <p className="font-medium">{user.name}</p>
              <p className="text-sm text-muted-foreground">Personal Trainer</p>
            </div>
            <Button variant="ghost" size="icon" onClick={handleLogout}>
              <LogOut className="h-5 w-5" />
            </Button>
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-8">
        <div className="mb-8">
          <h2 className="text-3xl font-bold mb-2">Dashboard</h2>
          <p className="text-muted-foreground">Gerencie seu perfil e seus alunos</p>
        </div>

        <Tabs value={activeTab} onValueChange={setActiveTab}>
          <TabsList className="mb-6">
            <TabsTrigger value="overview">Visão Geral</TabsTrigger>
            <TabsTrigger value="profile">Meu Perfil</TabsTrigger>
            <TabsTrigger value="students">Alunos</TabsTrigger>
            <TabsTrigger value="requests">
              Solicitações
              {pendingRequests.length > 0 && (
                <Badge variant="destructive" className="ml-2">
                  {pendingRequests.length}
                </Badge>
              )}
            </TabsTrigger>
          </TabsList>

          {/* Overview Tab */}
          <TabsContent value="overview" className="space-y-6">
            <div className="grid md:grid-cols-3 gap-6">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Total de Alunos</CardTitle>
                  <Users className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{acceptedConnections.length}</div>
                  <p className="text-xs text-muted-foreground">Conexões ativas</p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Solicitações Pendentes</CardTitle>
                  <Clock className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{pendingRequests.length}</div>
                  <p className="text-xs text-muted-foreground">Aguardando resposta</p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Perfil</CardTitle>
                  <UserCheck className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">Ativo</div>
                  <p className="text-xs text-muted-foreground">CREF: {user.cref}</p>
                </CardContent>
              </Card>
            </div>

            {/* Recent Activity */}
            <Card>
              <CardHeader>
                <CardTitle>Atividade Recente</CardTitle>
                <CardDescription>Últimas solicitações de conexão</CardDescription>
              </CardHeader>
              <CardContent>
                {allConnections.length === 0 ? (
                  <p className="text-muted-foreground text-center py-8">Nenhuma solicitação ainda</p>
                ) : (
                  <div className="space-y-4">
                    {allConnections.slice(0, 5).map((conn) => (
                      <div key={conn.id} className="flex items-center justify-between">
                        <div className="flex items-center gap-3">
                          <Avatar>
                            <AvatarFallback>{conn.studentName.charAt(0)}</AvatarFallback>
                          </Avatar>
                          <div>
                            <p className="font-medium">{conn.studentName}</p>
                            <p className="text-sm text-muted-foreground">{conn.studentEmail}</p>
                          </div>
                        </div>
                        <Badge
                          variant={
                            conn.status === "accepted" ? "default" : conn.status === "pending" ? "secondary" : "outline"
                          }
                        >
                          {conn.status === "accepted" ? "Aceito" : conn.status === "pending" ? "Pendente" : "Rejeitado"}
                        </Badge>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          {/* Profile Tab */}
          <TabsContent value="profile">
            <Card>
              <CardHeader>
                <CardTitle>Meu Perfil</CardTitle>
                <CardDescription>Informações visíveis para os alunos</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <label className="text-sm font-medium">Nome</label>
                  <p className="text-lg">{user.name}</p>
                </div>
                <div>
                  <label className="text-sm font-medium">Email</label>
                  <p className="text-lg">{user.email}</p>
                </div>
                <div>
                  <label className="text-sm font-medium">CREF</label>
                  <p className="text-lg">{user.cref}</p>
                </div>
                {user.specialty && (
                  <div>
                    <label className="text-sm font-medium">Especialidade</label>
                    <p className="text-lg">{user.specialty}</p>
                  </div>
                )}
                {user.experience && (
                  <div>
                    <label className="text-sm font-medium">Experiência</label>
                    <p className="text-lg">{user.experience}</p>
                  </div>
                )}
                {user.hourlyRate && (
                  <div>
                    <label className="text-sm font-medium">Valor por Hora</label>
                    <p className="text-lg">{user.hourlyRate}</p>
                  </div>
                )}
                {user.bio && (
                  <div>
                    <label className="text-sm font-medium">Biografia</label>
                    <p className="text-lg">{user.bio}</p>
                  </div>
                )}
                <Button asChild>
                  <Link href="/dashboard/trainer/edit-profile">Editar Perfil</Link>
                </Button>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Students Tab */}
          <TabsContent value="students">
            <Card>
              <CardHeader>
                <CardTitle>Meus Alunos</CardTitle>
                <CardDescription>Alunos conectados com você</CardDescription>
              </CardHeader>
              <CardContent>
                {acceptedConnections.length === 0 ? (
                  <p className="text-muted-foreground text-center py-8">Você ainda não tem alunos conectados</p>
                ) : (
                  <div className="space-y-4">
                    {acceptedConnections.map((conn) => (
                      <div key={conn.id} className="flex items-center gap-4 p-4 border rounded-lg">
                        <Avatar className="h-12 w-12">
                          <AvatarFallback className="text-lg">{conn.studentName.charAt(0)}</AvatarFallback>
                        </Avatar>
                        <div className="flex-1">
                          <p className="font-medium text-lg">{conn.studentName}</p>
                          <div className="flex items-center gap-2 text-sm text-muted-foreground">
                            <Mail className="h-4 w-4" />
                            {conn.studentEmail}
                          </div>
                        </div>
                        <div className="flex gap-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleOpenChat(conn.studentId, conn.studentName)}
                          >
                            <MessageSquare className="h-4 w-4 mr-2" />
                            Chat
                          </Button>
                          <Button
                            variant="destructive"
                            size="sm"
                            onClick={() => handleDisconnectClick(conn.studentId, conn.studentName)}
                          >
                            <UserMinus className="h-4 w-4 mr-2" />
                            Desconectar
                          </Button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          {/* Requests Tab */}
          <TabsContent value="requests">
            <Card>
              <CardHeader>
                <CardTitle>Solicitações de Conexão</CardTitle>
                <CardDescription>Gerencie as solicitações dos alunos</CardDescription>
              </CardHeader>
              <CardContent>
                {pendingRequests.length === 0 ? (
                  <p className="text-muted-foreground text-center py-8">Nenhuma solicitação pendente</p>
                ) : (
                  <div className="space-y-4">
                    {pendingRequests.map((conn) => (
                      <div key={conn.id} className="flex items-center justify-between p-4 border rounded-lg">
                        <div className="flex items-center gap-4">
                          <Avatar className="h-12 w-12">
                            <AvatarFallback className="text-lg">{conn.studentName.charAt(0)}</AvatarFallback>
                          </Avatar>
                          <div>
                            <p className="font-medium text-lg">{conn.studentName}</p>
                            <div className="flex items-center gap-2 text-sm text-muted-foreground">
                              <Mail className="h-4 w-4" />
                              {conn.studentEmail}
                            </div>
                            <p className="text-xs text-muted-foreground mt-1">
                              {new Date(conn.createdAt).toLocaleDateString("pt-BR")}
                            </p>
                          </div>
                        </div>
                        <div className="flex gap-2">
                          <Button onClick={() => acceptConnection(conn.id)} size="sm">
                            Aceitar
                          </Button>
                          <Button onClick={() => rejectConnection(conn.id)} variant="outline" size="sm">
                            Rejeitar
                          </Button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>

      {/* Chat Dialog */}
      {selectedStudent && user && (
        <ChatDialog
          open={chatOpen}
          onOpenChange={setChatOpen}
          currentUserId={user.id}
          currentUserName={user.name}
          otherUserId={selectedStudent.id}
          otherUserName={selectedStudent.name}
        />
      )}

      {/* Disconnect Confirmation Dialog */}
      <AlertDialog open={disconnectDialogOpen} onOpenChange={setDisconnectDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Desconectar aluno?</AlertDialogTitle>
            <AlertDialogDescription>
              Tem certeza que deseja desconectar {studentToDisconnect?.name}? Esta ação não pode ser desfeita e todas as
              mensagens do chat serão mantidas.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction onClick={handleConfirmDisconnect}>Desconectar</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
