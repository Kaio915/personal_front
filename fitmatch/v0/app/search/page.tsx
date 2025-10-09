"use client"

import { useAuth } from "@/lib/auth-context"
import { useConnections } from "@/lib/connections-context"
import { useRouter } from "next/navigation"
import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Dumbbell, Search, Award, Clock, DollarSign, UserCheck, MapPin, Star, ArrowLeft } from "lucide-react"
import Link from "next/link"
import type { User } from "@/lib/auth-context"
import { BackButton } from "@/components/back-button"

export default function SearchPage() {
  const { user } = useAuth()
  const { sendConnectionRequest, getStudentConnections, getTrainerAverageRating } = useConnections()
  const router = useRouter()
  const [searchQuery, setSearchQuery] = useState("")
  const [searchType, setSearchType] = useState<"name" | "city">("name")
  const [searchResults, setSearchResults] = useState<User[]>([])
  const [hasSearched, setHasSearched] = useState(false)

  const myConnections = user && user.userType === "student" ? getStudentConnections(user.id) : []

  const handleSearch = () => {
    setHasSearched(true)
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
    if (!user) {
      router.push("/login")
      return
    }

    if (user.userType !== "student") {
      alert("Apenas alunos podem se conectar com personal trainers")
      return
    }

    sendConnectionRequest(trainer.id, user.id, user.name, user.email)
    alert("Solicitação enviada com sucesso!")
  }

  const hasRequestedTrainer = (trainerId: string) => {
    return myConnections.some((conn) => conn.trainerId === trainerId)
  }

  const getConnectionStatus = (trainerId: string) => {
    const connection = myConnections.find((conn) => conn.trainerId === trainerId)
    return connection?.status
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
          <div className="flex gap-3">
            <BackButton />
            {user ? (
              <Button asChild>
                <Link href={user.userType === "trainer" ? "/dashboard/trainer" : "/dashboard/student"}>
                  Meu Dashboard
                </Link>
              </Button>
            ) : (
              <>
                <Button variant="ghost" asChild>
                  <Link href="/login">Entrar</Link>
                </Button>
                <Button asChild>
                  <Link href="/signup">Cadastrar</Link>
                </Button>
              </>
            )}
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-8">
        {user && (
          <Button variant="ghost" asChild className="mb-6">
            <Link href={user.userType === "trainer" ? "/dashboard/trainer" : "/dashboard/student"}>
              <ArrowLeft className="mr-2 h-4 w-4" />
              Voltar ao Dashboard
            </Link>
          </Button>
        )}

        <div className="mb-8">
          <h2 className="text-3xl font-bold mb-2">Buscar Personal Trainers</h2>
          <p className="text-muted-foreground">Encontre o profissional ideal para seus objetivos</p>
        </div>

        {/* Search Section */}
        <Card className="mb-8">
          <CardHeader>
            <CardTitle>Pesquisar</CardTitle>
            <CardDescription>Busque por nome, especialidade ou cidade</CardDescription>
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
          </CardContent>
        </Card>

        {/* Search Results */}
        {hasSearched && (
          <>
            {searchResults.length > 0 ? (
              <div className="space-y-4">
                <h3 className="text-xl font-semibold">
                  {searchResults.length}{" "}
                  {searchResults.length === 1 ? "resultado encontrado" : "resultados encontrados"}
                </h3>
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

                            {trainer.bio && (
                              <p className="text-sm text-muted-foreground mb-4 line-clamp-3">{trainer.bio}</p>
                            )}

                            <div className="flex items-center gap-2">
                              {user && user.userType === "student" ? (
                                <>
                                  <Button
                                    onClick={() => handleConnect(trainer)}
                                    disabled={hasRequestedTrainer(trainer.id)}
                                    size="sm"
                                  >
                                    {hasRequestedTrainer(trainer.id) ? "Solicitação Enviada" : "Conectar"}
                                  </Button>
                                  {hasRequestedTrainer(trainer.id) && (
                                    <Badge
                                      variant={
                                        getConnectionStatus(trainer.id) === "accepted"
                                          ? "default"
                                          : getConnectionStatus(trainer.id) === "pending"
                                            ? "secondary"
                                            : "outline"
                                      }
                                    >
                                      {getConnectionStatus(trainer.id) === "accepted"
                                        ? "Conectado"
                                        : getConnectionStatus(trainer.id) === "pending"
                                          ? "Aguardando"
                                          : "Rejeitado"}
                                    </Badge>
                                  )}
                                </>
                              ) : (
                                <Button size="sm" asChild>
                                  <Link href="/signup?type=student">Cadastre-se para Conectar</Link>
                                </Button>
                              )}
                            </div>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  )
                })}
              </div>
            ) : (
              <Card>
                <CardContent className="py-12 text-center">
                  <p className="text-muted-foreground">
                    {searchQuery ? "Nenhum personal trainer encontrado com esses critérios" : "Digite algo para buscar"}
                  </p>
                </CardContent>
              </Card>
            )}
          </>
        )}

        {/* Initial State */}
        {!hasSearched && (
          <Card>
            <CardContent className="py-12 text-center">
              <Search className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
              <h3 className="text-lg font-semibold mb-2">Comece sua busca</h3>
              <p className="text-muted-foreground">
                Digite o nome de um personal trainer, uma especialidade ou uma cidade para encontrar profissionais
              </p>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  )
}
