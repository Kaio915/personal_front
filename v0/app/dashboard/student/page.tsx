"use client"

import { useAuth } from "@/lib/auth-context"
import { useConnections } from "@/lib/connections-context"
import { useRouter } from "next/navigation"
import { useEffect, useState } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import {
  Dumbbell,
  LogOut,
  Search,
  UserCheck,
  Mail,
  Award,
  Clock,
  DollarSign,
  MessageSquare,
  UserMinus,
  MapPin,
  Star,
} from "lucide-react"
import Link from "next/link"
import type { User } from "@/lib/auth-context"
import { ChatDialog } from "@/components/chat-dialog"
import { RatingDialog } from "@/components/rating-dialog"
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

export default function StudentDashboard() {
  const { user, logout } = useAuth()
  const {
    getStudentConnections,
    getConnectedTrainer,
    sendConnectionRequest,
    disconnectConnection,
    rateTrainer,
    getTrainerAverageRating,
  } = useConnections()
  const router = useRouter()
  const [searchQuery, setSearchQuery] = useState("")
  const [searchType, setSearchType] = useState<"name" | "city">("name")
  const [searchResults, setSearchResults] = useState<User[]>([])
  const [chatOpen, setChatOpen] = useState(false)
  const [disconnectDialogOpen, setDisconnectDialogOpen] = useState(false)

  useEffect(() => {
    if (!user || user.userType !== "student") {
      router.push("/login")
    }
  }, [user, router])

  if (!user || user.userType !== "student") {
    return null
  }

  const myConnections = getStudentConnections(user.id)
  const connectedTrainer = getConnectedTrainer(user.id)
  const pendingRequests = myConnections.filter((conn) => conn.status === "pending")
  const currentConnection = myConnections.find(
    (conn) => conn.trainerId === connectedTrainer?.id && conn.status === "accepted",
  )
  const currentRating = currentConnection?.rating

  const handleSearch = () => {
    if (!searchQuery.trim()) {
      setSearchResults([])
      return
    }

    const usersJson = localStorage.getItem("users")
    const users = usersJson ? JSON.parse(usersJson) : []

    const trainers = users.filter((u: User) => {
      if (u.userType !== "trainer") return false

      if (searchType === "city") {
        return u.city?.toLowerCase().includes(searchQuery.toLowerCase())
      } else {
        return (
          u.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
          u.specialty?.toLowerCase().includes(searchQuery.toLowerCase())
        )
      }
    })

    setSearchResults(trainers)
  }

  const handleConnect = (trainer: User) => {
    sendConnectionRequest(trainer.id, user.id, user.name, user.email)
    alert("Solicitação enviada com sucesso!")
  }

  const hasRequestedTrainer = (trainerId: string) => {
    return myConnections.some((conn) => conn.trainerId === trainerId)
  }

  const handleLogout = () => {
    logout()
    router.push("/")
  }

  const handleOpenChat = () => {
    if (connectedTrainer && user) {
      setChatOpen(true)
    }
  }

  const handleDisconnectClick = () => {
    setDisconnectDialogOpen(true)
  }

  const handleConfirmDisconnect = () => {
    if (connectedTrainer && user) {
      disconnectConnection(user.id, connectedTrainer.id)
      setDisconnectDialogOpen(false)
    }
  }

  const handleRate = (rating: number) => {
    if (connectedTrainer && user) {
      rateTrainer(user.id, connectedTrainer.id, rating)
    }
  }

  const renderStars = (rating: number) => {
    return (
      <div className="flex items-center gap-1">
        {[1, 2, 3, 4, 5].map((star) => (
          <Star
            key={star}
            className={`h-4 w-4 ${star <= rating ? "fill-yellow-400 text-yellow-400" : "text-gray-300"}`}
          />
        ))}
        <span className="text-sm text-muted-foreground ml-1">({rating.toFixed(1)})</span>
      </div>
    )
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
              <p className="text-sm text-muted-foreground">Aluno</p>
            </div>
            <Button variant="ghost" size="icon" onClick={handleLogout}>
              <LogOut className="h-5 w-5" />
            </Button>
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-8">
        <div className="mb-8">
          <h2 className="text-3xl font-bold mb-2">Meu Dashboard</h2>
          <p className="text-muted-foreground">Encontre e conecte-se com personal trainers</p>
        </div>

        {/* Search Section */}
        <Card className="mb-8">
          <CardHeader>
            <CardTitle>Buscar Personal Trainers</CardTitle>
            <CardDescription>Pesquise por nome, especialidade ou cidade</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex flex-col md:flex-row gap-3">
              <Select value={searchType} onValueChange={(v) => setSearchType(v as "name" | "city")}>
                <SelectTrigger className="w-full md:w-[180px]">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="name">Nome/Especialidade</SelectItem>
                  <SelectItem value="city">Cidade</SelectItem>
                </SelectContent>
              </Select>

              <div className="relative flex-1">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder={
                    searchType === "city"
                      ? "Ex: São Paulo, Rio de Janeiro..."
                      : "Ex: João Silva, Musculação, Funcional..."
                  }
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  onKeyDown={(e) => e.key === "Enter" && handleSearch()}
                  className="pl-10"
                />
              </div>
              <Button onClick={handleSearch}>Buscar</Button>
            </div>

            {/* Search Results */}
            {searchResults.length > 0 && (
              <div className="mt-6 space-y-4">
                <h3 className="font-semibold">Resultados da Busca</h3>
                {searchResults.map((trainer) => {
                  const avgRating = getTrainerAverageRating(trainer.id)
                  return (
                    <Card key={trainer.id}>
                      <CardContent className="pt-6">
                        <div className="flex items-start gap-4">
                          <Avatar className="h-16 w-16">
                            <AvatarFallback className="text-xl">{trainer.name.charAt(0)}</AvatarFallback>
                          </Avatar>
                          <div className="flex-1">
                            <h4 className="text-xl font-semibold mb-2">{trainer.name}</h4>

                            {avgRating > 0 && <div className="mb-3">{renderStars(avgRating)}</div>}

                            <div className="grid md:grid-cols-2 gap-2 mb-4">
                              {trainer.city && (
                                <div className="flex items-center gap-2 text-sm">
                                  <MapPin className="h-4 w-4 text-muted-foreground" />
                                  <span>{trainer.city}</span>
                                </div>
                              )}
                              {trainer.specialty && (
                                <div className="flex items-center gap-2 text-sm">
                                  <Award className="h-4 w-4 text-muted-foreground" />
                                  <span>{trainer.specialty}</span>
                                </div>
                              )}
                              {trainer.experience && (
                                <div className="flex items-center gap-2 text-sm">
                                  <Clock className="h-4 w-4 text-muted-foreground" />
                                  <span>{trainer.experience} de experiência</span>
                                </div>
                              )}
                              {trainer.cref && (
                                <div className="flex items-center gap-2 text-sm">
                                  <UserCheck className="h-4 w-4 text-muted-foreground" />
                                  <span>CREF: {trainer.cref}</span>
                                </div>
                              )}
                              {trainer.hourlyRate && (
                                <div className="flex items-center gap-2 text-sm">
                                  <DollarSign className="h-4 w-4 text-muted-foreground" />
                                  <span>{trainer.hourlyRate}</span>
                                </div>
                              )}
                            </div>

                            {trainer.bio && <p className="text-sm text-muted-foreground mb-4">{trainer.bio}</p>}

                            <div className="flex items-center gap-2">
                              <Button
                                onClick={() => handleConnect(trainer)}
                                disabled={hasRequestedTrainer(trainer.id)}
                                size="sm"
                              >
                                {hasRequestedTrainer(trainer.id) ? "Solicitação Enviada" : "Conectar"}
                              </Button>
                              {hasRequestedTrainer(trainer.id) && (
                                <Badge variant="secondary">
                                  {myConnections.find((c) => c.trainerId === trainer.id)?.status === "accepted"
                                    ? "Conectado"
                                    : myConnections.find((c) => c.trainerId === trainer.id)?.status === "pending"
                                      ? "Aguardando"
                                      : "Rejeitado"}
                                </Badge>
                              )}
                            </div>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  )
                })}
              </div>
            )}

            {searchQuery && searchResults.length === 0 && (
              <p className="text-center text-muted-foreground mt-6">Nenhum personal trainer encontrado</p>
            )}
          </CardContent>
        </Card>

        <div className="grid md:grid-cols-2 gap-6">
          {/* Connected Trainer */}
          <Card>
            <CardHeader>
              <CardTitle>Meu Personal Trainer</CardTitle>
              <CardDescription>Personal trainer conectado com você</CardDescription>
            </CardHeader>
            <CardContent>
              {connectedTrainer ? (
                <div className="space-y-4">
                  <div className="flex items-center gap-4">
                    <Avatar className="h-16 w-16">
                      <AvatarFallback className="text-xl">{connectedTrainer.name.charAt(0)}</AvatarFallback>
                    </Avatar>
                    <div className="flex-1">
                      <h4 className="text-lg font-semibold">{connectedTrainer.name}</h4>
                      {connectedTrainer.specialty && (
                        <p className="text-sm text-muted-foreground">{connectedTrainer.specialty}</p>
                      )}
                    </div>
                  </div>

                  <div className="space-y-2 pt-4 border-t">
                    {connectedTrainer.email && (
                      <div className="flex items-center gap-2 text-sm">
                        <Mail className="h-4 w-4 text-muted-foreground" />
                        <span>{connectedTrainer.email}</span>
                      </div>
                    )}
                    {connectedTrainer.city && (
                      <div className="flex items-center gap-2 text-sm">
                        <MapPin className="h-4 w-4 text-muted-foreground" />
                        <span>{connectedTrainer.city}</span>
                      </div>
                    )}
                    {connectedTrainer.cref && (
                      <div className="flex items-center gap-2 text-sm">
                        <UserCheck className="h-4 w-4 text-muted-foreground" />
                        <span>CREF: {connectedTrainer.cref}</span>
                      </div>
                    )}
                    {connectedTrainer.hourlyRate && (
                      <div className="flex items-center gap-2 text-sm">
                        <DollarSign className="h-4 w-4 text-muted-foreground" />
                        <span>{connectedTrainer.hourlyRate}</span>
                      </div>
                    )}
                  </div>

                  <div className="flex gap-2 pt-4 border-t">
                    <Button onClick={handleOpenChat} className="flex-1">
                      <MessageSquare className="h-4 w-4 mr-2" />
                      Abrir Chat
                    </Button>
                    <Button variant="destructive" onClick={handleDisconnectClick}>
                      <UserMinus className="h-4 w-4 mr-2" />
                      Desconectar
                    </Button>
                  </div>

                  <div className="pt-4 border-t">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm font-medium">Sua Avaliação</span>
                      <RatingDialog
                        trainerName={connectedTrainer.name}
                        currentRating={currentRating}
                        onRate={handleRate}
                      />
                    </div>
                    {currentRating && (
                      <div className="flex items-center gap-2">
                        {[1, 2, 3, 4, 5].map((star) => (
                          <Star
                            key={star}
                            className={`h-5 w-5 ${star <= currentRating ? "fill-yellow-400 text-yellow-400" : "text-gray-300"}`}
                          />
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              ) : (
                <div className="text-center py-8">
                  <p className="text-muted-foreground mb-4">
                    Você ainda não está conectado com nenhum personal trainer
                  </p>
                  <p className="text-sm text-muted-foreground">Use a busca acima para encontrar profissionais</p>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Connection Status */}
          <Card>
            <CardHeader>
              <CardTitle>Status das Solicitações</CardTitle>
              <CardDescription>Acompanhe suas solicitações de conexão</CardDescription>
            </CardHeader>
            <CardContent>
              {myConnections.length === 0 ? (
                <div className="text-center py-8">
                  <p className="text-muted-foreground">Nenhuma solicitação enviada ainda</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {myConnections.map((conn) => {
                    const usersJson = localStorage.getItem("users")
                    const users = usersJson ? JSON.parse(usersJson) : []
                    const trainer = users.find((u: User) => u.id === conn.trainerId)

                    return (
                      <div key={conn.id} className="flex items-center justify-between p-3 border rounded-lg">
                        <div className="flex items-center gap-3">
                          <Avatar>
                            <AvatarFallback>{trainer?.name?.charAt(0) || "?"}</AvatarFallback>
                          </Avatar>
                          <div>
                            <p className="font-medium">{trainer?.name || "Personal Trainer"}</p>
                            <p className="text-xs text-muted-foreground">
                              {new Date(conn.createdAt).toLocaleDateString("pt-BR")}
                            </p>
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
                    )
                  })}
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* My Profile */}
        <Card className="mt-6">
          <CardHeader>
            <CardTitle>Meu Perfil</CardTitle>
            <CardDescription>Suas informações pessoais</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            <div>
              <label className="text-sm font-medium text-muted-foreground">Nome</label>
              <p className="text-lg">{user.name}</p>
            </div>
            <div>
              <label className="text-sm font-medium text-muted-foreground">Email</label>
              <p className="text-lg">{user.email}</p>
            </div>
            {user.goals && (
              <div>
                <label className="text-sm font-medium text-muted-foreground">Objetivos</label>
                <p className="text-lg">{user.goals}</p>
              </div>
            )}
            {user.fitnessLevel && (
              <div>
                <label className="text-sm font-medium text-muted-foreground">Nível de Condicionamento</label>
                <p className="text-lg">{user.fitnessLevel}</p>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Chat Dialog */}
      {connectedTrainer && user && (
        <ChatDialog
          open={chatOpen}
          onOpenChange={setChatOpen}
          currentUserId={user.id}
          currentUserName={user.name}
          otherUserId={connectedTrainer.id}
          otherUserName={connectedTrainer.name}
        />
      )}

      {/* Disconnect Confirmation Dialog */}
      <AlertDialog open={disconnectDialogOpen} onOpenChange={setDisconnectDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Desconectar do personal trainer?</AlertDialogTitle>
            <AlertDialogDescription>
              Tem certeza que deseja desconectar de {connectedTrainer?.name}? Esta ação não pode ser desfeita e todas as
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
