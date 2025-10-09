"use client"

import { createContext, useContext, useState, useEffect, type ReactNode } from "react"
import type { User } from "./auth-context"

export interface ConnectionRequest {
  id: string
  studentId: string
  trainerId: string
  status: "pending" | "accepted" | "rejected"
  createdAt: string
  studentName: string
  studentEmail: string
  rating?: number // Added rating field (1-5 stars)
}

interface ConnectionsContextType {
  connections: ConnectionRequest[]
  sendConnectionRequest: (trainerId: string, studentId: string, studentName: string, studentEmail: string) => void
  acceptConnection: (requestId: string) => void
  rejectConnection: (requestId: string) => void
  disconnectConnection: (studentId: string, trainerId: string) => void
  rateTrainer: (studentId: string, trainerId: string, rating: number) => void // Added rating function
  getTrainerConnections: (trainerId: string) => ConnectionRequest[]
  getStudentConnections: (studentId: string) => ConnectionRequest[]
  getConnectedTrainer: (studentId: string) => User | null
  getTrainerAverageRating: (trainerId: string) => number // Added function to get average rating
}

const ConnectionsContext = createContext<ConnectionsContextType | undefined>(undefined)

export function ConnectionsProvider({ children }: { children: ReactNode }) {
  const [connections, setConnections] = useState<ConnectionRequest[]>([])

  useEffect(() => {
    // Load connections from localStorage
    const storedConnections = localStorage.getItem("connections")
    if (storedConnections) {
      setConnections(JSON.parse(storedConnections))
    }
  }, [])

  const saveConnections = (newConnections: ConnectionRequest[]) => {
    setConnections(newConnections)
    localStorage.setItem("connections", JSON.stringify(newConnections))
  }

  const sendConnectionRequest = (trainerId: string, studentId: string, studentName: string, studentEmail: string) => {
    const newRequest: ConnectionRequest = {
      id: Date.now().toString(),
      studentId,
      trainerId,
      status: "pending",
      createdAt: new Date().toISOString(),
      studentName,
      studentEmail,
    }

    saveConnections([...connections, newRequest])
  }

  const acceptConnection = (requestId: string) => {
    const updatedConnections = connections.map((conn) =>
      conn.id === requestId ? { ...conn, status: "accepted" as const } : conn,
    )
    saveConnections(updatedConnections)
  }

  const rejectConnection = (requestId: string) => {
    const updatedConnections = connections.map((conn) =>
      conn.id === requestId ? { ...conn, status: "rejected" as const } : conn,
    )
    saveConnections(updatedConnections)
  }

  const disconnectConnection = (studentId: string, trainerId: string) => {
    const updatedConnections = connections.filter(
      (conn) => !(conn.studentId === studentId && conn.trainerId === trainerId && conn.status === "accepted"),
    )
    saveConnections(updatedConnections)
  }

  const rateTrainer = (studentId: string, trainerId: string, rating: number) => {
    const updatedConnections = connections.map((conn) =>
      conn.studentId === studentId && conn.trainerId === trainerId && conn.status === "accepted"
        ? { ...conn, rating }
        : conn,
    )
    saveConnections(updatedConnections)
  }

  const getTrainerConnections = (trainerId: string) => {
    return connections.filter((conn) => conn.trainerId === trainerId)
  }

  const getStudentConnections = (studentId: string) => {
    return connections.filter((conn) => conn.studentId === studentId)
  }

  const getConnectedTrainer = (studentId: string): User | null => {
    const acceptedConnection = connections.find((conn) => conn.studentId === studentId && conn.status === "accepted")

    if (!acceptedConnection) return null

    // Get trainer from users
    const usersJson = localStorage.getItem("users")
    const users = usersJson ? JSON.parse(usersJson) : []
    const trainer = users.find((u: User) => u.id === acceptedConnection.trainerId)

    return trainer || null
  }

  const getTrainerAverageRating = (trainerId: string): number => {
    const trainerConnections = connections.filter(
      (conn) => conn.trainerId === trainerId && conn.status === "accepted" && conn.rating,
    )

    if (trainerConnections.length === 0) return 0

    const totalRating = trainerConnections.reduce((sum, conn) => sum + (conn.rating || 0), 0)
    return totalRating / trainerConnections.length
  }

  return (
    <ConnectionsContext.Provider
      value={{
        connections,
        sendConnectionRequest,
        acceptConnection,
        rejectConnection,
        disconnectConnection,
        rateTrainer,
        getTrainerConnections,
        getStudentConnections,
        getConnectedTrainer,
        getTrainerAverageRating,
      }}
    >
      {children}
    </ConnectionsContext.Provider>
  )
}

export function useConnections() {
  const context = useContext(ConnectionsContext)
  if (context === undefined) {
    throw new Error("useConnections must be used within a ConnectionsProvider")
  }
  return context
}
