"use client"

import { createContext, useContext, useState, useEffect, type ReactNode } from "react"

export type UserType = "trainer" | "student" | "admin"

export interface User {
  id: string
  email: string
  name: string
  userType: UserType
  approved?: boolean // Added approval status for trainers and students
  // Trainer specific fields
  specialty?: string
  cref?: string
  experience?: string
  bio?: string
  hourlyRate?: string
  city?: string
  // Student specific fields
  goals?: string
  fitnessLevel?: string
}

export interface PendingRegistration extends User {
  password: string
  registrationDate: string
}

interface AuthContextType {
  user: User | null
  login: (email: string, password: string) => Promise<boolean>
  signup: (userData: Omit<User, "id"> & { password: string }) => Promise<boolean>
  logout: () => void
  updateProfile: (userData: Partial<User>) => void
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)

  useEffect(() => {
    const usersJson = localStorage.getItem("users")
    const users = usersJson ? JSON.parse(usersJson) : []

    const adminExists = users.some((u: any) => u.userType === "admin")
    if (!adminExists) {
      const adminUser = {
        id: "admin-1",
        email: "admin@fitconnect.com",
        password: "admin123",
        name: "Administrador",
        userType: "admin",
        approved: true,
      }
      users.push(adminUser)
      localStorage.setItem("users", JSON.stringify(users))
    }

    // Load user from localStorage on mount
    const storedUser = localStorage.getItem("currentUser")
    if (storedUser) {
      setUser(JSON.parse(storedUser))
    }
  }, [])

  const signup = async (userData: Omit<User, "id"> & { password: string }) => {
    try {
      console.log("[v0] Starting signup process for:", userData.email)
      const pendingJson = localStorage.getItem("pendingRegistrations")
      const pendingRegistrations = pendingJson ? JSON.parse(pendingJson) : []
      console.log("[v0] Current pending registrations:", pendingRegistrations)

      const usersJson = localStorage.getItem("users")
      const users = usersJson ? JSON.parse(usersJson) : []

      if (
        users.some((u: any) => u.email === userData.email) ||
        pendingRegistrations.some((p: any) => p.email === userData.email)
      ) {
        console.log("[v0] Email already exists")
        return false
      }

      const pendingRegistration: PendingRegistration = {
        ...userData,
        id: Date.now().toString(),
        approved: false,
        registrationDate: new Date().toISOString(),
      }

      pendingRegistrations.push(pendingRegistration)
      localStorage.setItem("pendingRegistrations", JSON.stringify(pendingRegistrations))
      console.log("[v0] Pending registration created:", pendingRegistration)
      console.log("[v0] Updated pending registrations saved to localStorage")

      return true
    } catch (error) {
      console.error("Signup error:", error)
      return false
    }
  }

  const login = async (email: string, password: string) => {
    try {
      const usersJson = localStorage.getItem("users")
      const users = usersJson ? JSON.parse(usersJson) : []

      const foundUser = users.find((u: any) => u.email === email && u.password === password)

      if (foundUser) {
        if (foundUser.userType !== "admin" && !foundUser.approved) {
          return false
        }

        const { password, ...userWithoutPassword } = foundUser
        setUser(userWithoutPassword)
        localStorage.setItem("currentUser", JSON.stringify(userWithoutPassword))
        return true
      }

      return false
    } catch (error) {
      console.error("Login error:", error)
      return false
    }
  }

  const logout = () => {
    setUser(null)
    localStorage.removeItem("currentUser")
  }

  const updateProfile = (userData: Partial<User>) => {
    if (!user) return

    const updatedUser = { ...user, ...userData }
    setUser(updatedUser)
    localStorage.setItem("currentUser", JSON.stringify(updatedUser))

    const usersJson = localStorage.getItem("users")
    const users = usersJson ? JSON.parse(usersJson) : []
    const userIndex = users.findIndex((u: any) => u.id === user.id)
    if (userIndex !== -1) {
      users[userIndex] = { ...users[userIndex], ...userData }
      localStorage.setItem("users", JSON.stringify(users))
    }
  }

  return <AuthContext.Provider value={{ user, login, signup, logout, updateProfile }}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider")
  }
  return context
}
