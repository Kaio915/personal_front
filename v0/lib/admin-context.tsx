"use client"

import { createContext, useContext, useState, useEffect, type ReactNode } from "react"
import type { PendingRegistration } from "./auth-context"

interface AdminContextType {
  pendingRegistrations: PendingRegistration[]
  approveRegistration: (id: string) => void
  rejectRegistration: (id: string) => void
  refreshPending: () => void
}

const AdminContext = createContext<AdminContextType | undefined>(undefined)

export function AdminProvider({ children }: { children: ReactNode }) {
  const [pendingRegistrations, setPendingRegistrations] = useState<PendingRegistration[]>([])

  const refreshPending = () => {
    console.log("[v0] Refreshing pending registrations...")
    const pendingJson = localStorage.getItem("pendingRegistrations")
    console.log("[v0] Raw pending data from localStorage:", pendingJson)
    const pending = pendingJson ? JSON.parse(pendingJson) : []
    console.log("[v0] Parsed pending registrations:", pending)
    setPendingRegistrations(pending)
  }

  useEffect(() => {
    refreshPending()
    const handleStorageChange = (e: StorageEvent) => {
      if (e.key === "pendingRegistrations") {
        console.log("[v0] Storage changed, refreshing pending registrations")
        refreshPending()
      }
    }
    window.addEventListener("storage", handleStorageChange)
    return () => window.removeEventListener("storage", handleStorageChange)
  }, [])

  const approveRegistration = (id: string) => {
    console.log("[v0] Approving registration:", id)
    const pendingJson = localStorage.getItem("pendingRegistrations")
    const pending: PendingRegistration[] = pendingJson ? JSON.parse(pendingJson) : []

    const registration = pending.find((p) => p.id === id)
    if (!registration) {
      console.log("[v0] Registration not found:", id)
      return
    }

    // Add to approved users
    const usersJson = localStorage.getItem("users")
    const users = usersJson ? JSON.parse(usersJson) : []

    const approvedUser = {
      ...registration,
      approved: true,
    }
    users.push(approvedUser)
    localStorage.setItem("users", JSON.stringify(users))
    console.log("[v0] User approved and added to users list")

    // Remove from pending
    const updatedPending = pending.filter((p) => p.id !== id)
    localStorage.setItem("pendingRegistrations", JSON.stringify(updatedPending))
    console.log("[v0] Removed from pending registrations")

    refreshPending()
  }

  const rejectRegistration = (id: string) => {
    console.log("[v0] Rejecting registration:", id)
    const pendingJson = localStorage.getItem("pendingRegistrations")
    const pending: PendingRegistration[] = pendingJson ? JSON.parse(pendingJson) : []

    // Remove from pending
    const updatedPending = pending.filter((p) => p.id !== id)
    localStorage.setItem("pendingRegistrations", JSON.stringify(updatedPending))
    console.log("[v0] Removed from pending registrations")

    refreshPending()
  }

  return (
    <AdminContext.Provider value={{ pendingRegistrations, approveRegistration, rejectRegistration, refreshPending }}>
      {children}
    </AdminContext.Provider>
  )
}

export function useAdmin() {
  const context = useContext(AdminContext)
  if (context === undefined) {
    throw new Error("useAdmin must be used within an AdminProvider")
  }
  return context
}
