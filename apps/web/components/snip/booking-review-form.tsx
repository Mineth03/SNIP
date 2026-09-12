"use client";

import { useEffect, useState } from "react";
import { Star, CheckCircle, MessageSquare } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Textarea } from "@/components/ui/textarea";
import { createClient } from "@/lib/supabase/client";
import type { Review } from "@/types/database";

interface BookingReviewFormProps {
  bookingId: string;
  salonName?: string;
  barberName?: string;
  onReviewed?: () => void;
}

export function BookingReviewForm({
  bookingId,
  salonName = "the salon",
  barberName,
  onReviewed,
}: BookingReviewFormProps) {
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [existingReview, setExistingReview] = useState<Review | null>(null);
  const [rating, setRating] = useState<number>(5);
  const [hoverRating, setHoverRating] = useState<number>(0);
  const [comment, setComment] = useState<string>("");
  const [isEditing, setIsEditing] = useState(false);

  useEffect(() => {
    async function loadReview() {
      const supabase = createClient();
      const { data, error } = await supabase
        .from("reviews")
        .select("*")
        .eq("booking_id", bookingId)
        .maybeSingle();

      if (!error && data) {
        setExistingReview(data as Review);
        setRating(data.rating);
        setComment(data.comment ?? "");
      }
      setLoading(false);
    }

    void loadReview();
  }, [bookingId]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (rating < 1 || rating > 5) {
      toast.error("Please select a rating between 1 and 5 stars");
      return;
    }

    setSubmitting(true);
    try {
      const supabase = createClient();
      const { data, error } = await supabase.rpc("submit_booking_review", {
        p_booking_id: bookingId,
        p_rating: rating,
        p_comment: comment.trim() || null,
      });

      if (error) throw error;

      toast.success(
        existingReview ? "Review updated!" : "Thank you for reviewing your visit!"
      );
      setExistingReview({
        id: (data as { review_id?: string })?.review_id ?? "new",
        booking_id: bookingId,
        salon_id: "",
        barber_id: null,
        customer_id: "",
        rating,
        comment: comment.trim() || null,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      });
      setIsEditing(false);
      onReviewed?.();
    } catch (err) {
      toast.error(
        err instanceof Error ? err.message : "Failed to submit review"
      );
    } finally {
      setSubmitting(false);
    }
  }

  if (loading) {
    return (
      <div className="py-4 text-center text-xs text-snip-muted">
        Loading review status...
      </div>
    );
  }

  if (existingReview && !isEditing) {
    return (
      <Card className="rounded-2xl border border-emerald-100 bg-emerald-50/50 p-5 shadow-snip-sm">
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-2">
            <CheckCircle className="h-5 w-5 text-emerald-600" />
            <span className="text-sm font-bold text-snip-charcoal">
              Your Review for {salonName}
            </span>
          </div>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setIsEditing(true)}
            className="text-xs text-snip-teal hover:underline"
          >
            Edit
          </Button>
        </div>

        <div className="mt-3 flex items-center gap-1">
          {[1, 2, 3, 4, 5].map((star) => (
            <Star
              key={star}
              className={`h-4 w-4 ${
                star <= existingReview.rating
                  ? "fill-amber-400 text-amber-400"
                  : "text-snip-border"
              }`}
            />
          ))}
          <span className="ml-1.5 text-xs font-semibold text-snip-charcoal">
            {existingReview.rating}.0
          </span>
        </div>

        {existingReview.comment ? (
          <p className="mt-2 text-xs italic text-snip-muted bg-white/70 p-2.5 rounded-xl border border-emerald-100/60">
            &ldquo;{existingReview.comment}&rdquo;
          </p>
        ) : null}
      </Card>
    );
  }

  return (
    <Card className="rounded-2xl border border-snip-teal/30 bg-snip-teal/5 p-5 shadow-snip-sm text-left">
      <div className="flex items-center gap-2">
        <MessageSquare className="h-4 w-4 text-snip-teal" />
        <h4 className="text-sm font-bold text-snip-charcoal">
          How was your experience at {salonName}?
        </h4>
      </div>
      <p className="mt-1 text-xs text-snip-muted">
        {barberName
          ? `Your feedback helps ${barberName} and other clients on SNIP.`
          : "Your feedback helps other clients and improves service quality."}
      </p>

      <form onSubmit={handleSubmit} className="mt-4 space-y-3">
        {/* Interactive Star Rating */}
        <div>
          <label className="block text-xs font-semibold text-snip-charcoal mb-1">
            Tap to rate
          </label>
          <div className="flex items-center gap-1">
            {[1, 2, 3, 4, 5].map((star) => {
              const active = hoverRating ? star <= hoverRating : star <= rating;
              return (
                <button
                  key={star}
                  type="button"
                  onClick={() => setRating(star)}
                  onMouseEnter={() => setHoverRating(star)}
                  onMouseLeave={() => setHoverRating(0)}
                  className="p-1 transition-transform hover:scale-125 focus:outline-none"
                  aria-label={`Rate ${star} stars`}
                >
                  <Star
                    className={`h-6 w-6 transition-colors ${
                      active
                        ? "fill-amber-400 text-amber-400"
                        : "text-slate-300"
                    }`}
                  />
                </button>
              );
            })}
            <span className="ml-2 text-xs font-bold text-snip-charcoal">
              {hoverRating || rating} / 5
            </span>
          </div>
        </div>

        <div>
          <label
            htmlFor="comment"
            className="block text-xs font-semibold text-snip-charcoal mb-1"
          >
            Review comment (optional)
          </label>
          <Textarea
            id="comment"
            value={comment}
            onChange={(e) => setComment(e.target.value)}
            placeholder="Share your thoughts about the cut, vibe, punctuality..."
            rows={2}
            className="bg-white text-xs"
          />
        </div>

        <div className="flex items-center gap-2 pt-1">
          <Button
            type="submit"
            size="sm"
            disabled={submitting}
            className="rounded-full px-5 text-xs font-semibold"
          >
            {submitting ? "Submitting..." : existingReview ? "Update Review" : "Submit Review"}
          </Button>
          {isEditing && (
            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={() => setIsEditing(false)}
              className="text-xs"
            >
              Cancel
            </Button>
          )}
        </div>
      </form>
    </Card>
  );
}
