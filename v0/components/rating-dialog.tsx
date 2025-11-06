"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Star } from "lucide-react"

interface RatingDialogProps {
  trainerName: string
  currentRating?: number
  onRate: (rating: number) => void
}

export function RatingDialog({ trainerName, currentRating, onRate }: RatingDialogProps) {
  const [rating, setRating] = useState(currentRating || 0)
  const [hoveredRating, setHoveredRating] = useState(0)
  const [open, setOpen] = useState(false)

  const handleSubmit = () => {
    if (rating > 0) {
      onRate(rating)
      setOpen(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button variant="outline" size="sm">
          <Star className="mr-2 h-4 w-4" />
          {currentRating ? "Alterar Avaliação" : "Avaliar"}
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Avaliar {trainerName}</DialogTitle>
          <DialogDescription>Dê uma nota de 1 a 5 estrelas para o seu personal trainer</DialogDescription>
        </DialogHeader>
        <div className="flex justify-center gap-2 py-6">
          {[1, 2, 3, 4, 5].map((star) => (
            <button
              key={star}
              type="button"
              onClick={() => setRating(star)}
              onMouseEnter={() => setHoveredRating(star)}
              onMouseLeave={() => setHoveredRating(0)}
              className="transition-transform hover:scale-110"
            >
              <Star
                className={`h-10 w-10 ${
                  star <= (hoveredRating || rating) ? "fill-yellow-400 text-yellow-400" : "text-gray-300"
                }`}
              />
            </button>
          ))}
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => setOpen(false)}>
            Cancelar
          </Button>
          <Button onClick={handleSubmit} disabled={rating === 0}>
            Confirmar Avaliação
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
