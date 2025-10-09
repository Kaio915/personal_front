"use client"

import type React from "react"

import { useState, useEffect } from "react"
import { useAuth } from "@/lib/auth-context"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { BackButton } from "@/components/back-button"

export default function EditProfilePage() {
  const { user, updateProfile } = useAuth()
  const router = useRouter()

  const [formData, setFormData] = useState({
    name: "",
    specialty: "",
    experience: "",
    bio: "",
    hourlyRate: "",
    city: "",
  })

  useEffect(() => {
    if (!user || user.userType !== "trainer") {
      router.push("/login")
      return
    }

    setFormData({
      name: user.name || "",
      specialty: user.specialty || "",
      experience: user.experience || "",
      bio: user.bio || "",
      hourlyRate: user.hourlyRate || "",
      city: user.city || "",
    })
  }, [user, router])

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    updateProfile(formData)
    router.push("/dashboard/trainer")
  }

  if (!user || user.userType !== "trainer") {
    return null
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-background to-muted">
      <div className="container mx-auto px-4 py-8">
        <div className="mb-6">
          <BackButton />
        </div>

        <Card className="max-w-2xl mx-auto">
          <CardHeader>
            <CardTitle>Editar Perfil</CardTitle>
            <CardDescription>Atualize suas informações profissionais</CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="name">Nome Completo</Label>
                <Input
                  id="name"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  required
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="specialty">Especialidade</Label>
                <Input
                  id="specialty"
                  value={formData.specialty}
                  onChange={(e) => setFormData({ ...formData, specialty: e.target.value })}
                  placeholder="Ex: Musculação, Funcional, Emagrecimento"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="experience">Experiência</Label>
                <Input
                  id="experience"
                  value={formData.experience}
                  onChange={(e) => setFormData({ ...formData, experience: e.target.value })}
                  placeholder="Ex: 5 anos"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="hourlyRate">Valor por Hora</Label>
                <Input
                  id="hourlyRate"
                  value={formData.hourlyRate}
                  onChange={(e) => setFormData({ ...formData, hourlyRate: e.target.value })}
                  placeholder="Ex: R$ 100"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="bio">Biografia</Label>
                <Textarea
                  id="bio"
                  value={formData.bio}
                  onChange={(e) => setFormData({ ...formData, bio: e.target.value })}
                  placeholder="Conte um pouco sobre você e sua metodologia..."
                  rows={5}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="city">Cidade</Label>
                <Input
                  id="city"
                  value={formData.city}
                  onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                  placeholder="Ex: São Paulo"
                />
              </div>

              <div className="flex gap-3">
                <Button type="submit" className="flex-1">
                  Salvar Alterações
                </Button>
                <Button type="button" variant="outline" onClick={() => router.push("/dashboard/trainer")}>
                  Cancelar
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
