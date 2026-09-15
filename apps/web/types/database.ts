export type UserRole = "customer" | "salon_owner" | "barber" | "admin";

export type SalonVerificationStatus =
  | "draft"
  | "pending_verification"
  | "verified"
  | "rejected"
  | "suspended";

export type BookingStatus =
  | "pending"
  | "confirmed"
  | "checked_in"
  | "in_progress"
  | "completed"
  | "cancelled"
  | "no_show";

export type ServiceCategory =
  | "hair"
  | "beard"
  | "nails"
  | "facial"
  | "massage"
  | "color"
  | "other";

export type NotificationType =
  | "booking_created"
  | "booking_confirmed"
  | "booking_cancelled"
  | "booking_reminder"
  | "booking_status"
  | "salon_submitted"
  | "salon_approved"
  | "salon_rejected"
  | "salon_changes_requested"
  | "staff_invitation"
  | "system";

export type VerificationDecision =
  | "submitted"
  | "approved"
  | "rejected"
  | "changes_requested";

export type DayOfWeek =
  | "monday"
  | "tuesday"
  | "wednesday"
  | "thursday"
  | "friday"
  | "saturday"
  | "sunday";

export type OpeningHours = Partial<
  Record<DayOfWeek, { open?: string; close?: string; closed?: boolean }>
>;

export interface Profile {
  id: string;
  role: UserRole;
  active_role?: UserRole;
  active_barber_salon_id?: string | null;
  full_name: string;
  email: string;
  phone: string | null;
  avatar_url: string | null;
  city: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Salon {
  id: string;
  owner_id: string;
  name: string;
  slug: string;
  description: string | null;
  email: string | null;
  phone: string | null;
  address: string | null;
  city: string | null;
  latitude: number | null;
  longitude: number | null;
  logo_url: string | null;
  cover_url: string | null;
  verification_status: SalonVerificationStatus;
  rejection_reason: string | null;
  is_active: boolean;
  opening_hours: OpeningHours;
  avg_rating: number;
  review_count: number;
  distance_km?: number | null;
  created_at: string;
  updated_at: string;
}

export interface SalonMember {
  id: string;
  salon_id: string;
  profile_id: string;
  member_role: Extract<UserRole, "salon_owner" | "barber">;
  is_active: boolean;
  invited_email: string | null;
  invitation_token: string | null;
  invitation_accepted_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface Service {
  id: string;
  salon_id: string;
  name: string;
  description: string | null;
  category: ServiceCategory;
  price: number;
  duration_minutes: number;
  image_url: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Barber {
  id: string;
  salon_id: string;
  profile_id: string | null;
  display_name: string;
  bio: string | null;
  avatar_url: string | null;
  specializations: string[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface BarberService {
  id: string;
  barber_id: string;
  service_id: string;
  created_at: string;
}

export interface BarberSchedule {
  id: string;
  barber_id: string;
  day_of_week: DayOfWeek;
  start_time: string;
  end_time: string;
  is_working: boolean;
  created_at: string;
  updated_at: string;
}

export interface BarberBreak {
  id: string;
  barber_id: string;
  day_of_week: DayOfWeek;
  start_time: string;
  end_time: string;
  created_at: string;
}

export interface BarberTimeOff {
  id: string;
  barber_id: string;
  start_datetime: string;
  end_datetime: string;
  reason: string | null;
  created_at: string;
}

export interface BarberPortfolio {
  id: string;
  barber_id: string;
  image_url: string;
  caption: string | null;
  sort_order: number;
  created_at: string;
}

export interface SalonGallery {
  id: string;
  salon_id: string;
  image_url: string;
  caption: string | null;
  sort_order: number;
  created_at: string;
}

export interface Booking {
  id: string;
  customer_id: string;
  salon_id: string;
  service_id: string;
  barber_id: string;
  appointment_start: string;
  appointment_end: string;
  price: number;
  status: BookingStatus;
  customer_notes: string | null;
  qr_token: string;
  is_walk_in: boolean;
  cancelled_at: string | null;
  cancellation_reason: string | null;
  created_at: string;
  updated_at: string;
}

export interface BookingStatusHistory {
  id: string;
  booking_id: string;
  from_status: BookingStatus | null;
  to_status: BookingStatus;
  changed_by: string | null;
  note: string | null;
  created_at: string;
}

export interface Favorite {
  id: string;
  user_id: string;
  salon_id: string;
  created_at: string;
}

export interface Review {
  id: string;
  booking_id: string;
  salon_id: string;
  barber_id: string | null;
  customer_id: string;
  rating: number;
  comment: string | null;
  created_at: string;
  updated_at: string;
}

export type UserActivityType =
  | "view_salon"
  | "view_service"
  | "search"
  | "favorite_salon"
  | "book_appointment"
  | "review_salon";

export interface UserActivity {
  id: string;
  user_id: string;
  activity_type: UserActivityType;
  salon_id: string | null;
  service_id: string | null;
  category: ServiceCategory | null;
  metadata: Record<string, unknown>;
  created_at: string;
}

export interface RecommendedSalon extends Salon {
  recommendation_score: number;
  recommendation_reason: string;
  matched_category: string | null;
}

export interface UserRecentActivity {
  id: string;
  activity_type: UserActivityType;
  salon_id: string | null;
  salon_name: string | null;
  salon_slug: string | null;
  salon_cover_url: string | null;
  service_id: string | null;
  service_name: string | null;
  category: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
}

export interface Notification {
  id: string;
  user_id: string;
  title: string;
  message: string;
  type: NotificationType;
  is_read: boolean;
  metadata: Record<string, unknown>;
  created_at: string;
}

export interface SalonVerificationRequest {
  id: string;
  salon_id: string;
  submitted_by: string;
  reviewed_by: string | null;
  decision: VerificationDecision;
  notes: string | null;
  reason: string | null;
  created_at: string;
  reviewed_at: string | null;
}

export interface AvailableSlot {
  barber_id: string;
  barber_name: string;
  slot_start: string;
  slot_end: string;
}

export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: Profile;
        Insert: Partial<Profile> &
          Pick<Profile, "id" | "full_name" | "email">;
        Update: Partial<Profile>;
      };
      salons: {
        Row: Salon;
        Insert: Partial<Salon> & Pick<Salon, "owner_id" | "name">;
        Update: Partial<Salon>;
      };
      salon_members: {
        Row: SalonMember;
        Insert: Partial<SalonMember> &
          Pick<SalonMember, "salon_id" | "profile_id" | "member_role">;
        Update: Partial<SalonMember>;
      };
      services: {
        Row: Service;
        Insert: Partial<Service> &
          Pick<Service, "salon_id" | "name" | "price" | "duration_minutes">;
        Update: Partial<Service>;
      };
      barbers: {
        Row: Barber;
        Insert: Partial<Barber> & Pick<Barber, "salon_id" | "display_name">;
        Update: Partial<Barber>;
      };
      barber_services: {
        Row: BarberService;
        Insert: Partial<BarberService> &
          Pick<BarberService, "barber_id" | "service_id">;
        Update: Partial<BarberService>;
      };
      barber_schedules: {
        Row: BarberSchedule;
        Insert: Partial<BarberSchedule> &
          Pick<
            BarberSchedule,
            "barber_id" | "day_of_week" | "start_time" | "end_time"
          >;
        Update: Partial<BarberSchedule>;
      };
      barber_breaks: {
        Row: BarberBreak;
        Insert: Partial<BarberBreak> &
          Pick<
            BarberBreak,
            "barber_id" | "day_of_week" | "start_time" | "end_time"
          >;
        Update: Partial<BarberBreak>;
      };
      barber_time_off: {
        Row: BarberTimeOff;
        Insert: Partial<BarberTimeOff> &
          Pick<BarberTimeOff, "barber_id" | "start_datetime" | "end_datetime">;
        Update: Partial<BarberTimeOff>;
      };
      barber_portfolio: {
        Row: BarberPortfolio;
        Insert: Partial<BarberPortfolio> &
          Pick<BarberPortfolio, "barber_id" | "image_url">;
        Update: Partial<BarberPortfolio>;
      };
      salon_gallery: {
        Row: SalonGallery;
        Insert: Partial<SalonGallery> &
          Pick<SalonGallery, "salon_id" | "image_url">;
        Update: Partial<SalonGallery>;
      };
      bookings: {
        Row: Booking;
        Insert: Partial<Booking> &
          Pick<
            Booking,
            | "customer_id"
            | "salon_id"
            | "service_id"
            | "barber_id"
            | "appointment_start"
            | "appointment_end"
            | "price"
          >;
        Update: Partial<Booking>;
      };
      booking_status_history: {
        Row: BookingStatusHistory;
        Insert: Partial<BookingStatusHistory> &
          Pick<BookingStatusHistory, "booking_id" | "to_status">;
        Update: Partial<BookingStatusHistory>;
      };
      favorites: {
        Row: Favorite;
        Insert: Partial<Favorite> & Pick<Favorite, "user_id" | "salon_id">;
        Update: Partial<Favorite>;
      };
      reviews: {
        Row: Review;
        Insert: Partial<Review> &
          Pick<Review, "booking_id" | "salon_id" | "customer_id" | "rating">;
        Update: Partial<Review>;
      };
      notifications: {
        Row: Notification;
        Insert: Partial<Notification> &
          Pick<Notification, "user_id" | "title" | "message" | "type">;
        Update: Partial<Notification>;
      };
      salon_verification_requests: {
        Row: SalonVerificationRequest;
        Insert: Partial<SalonVerificationRequest> &
          Pick<
            SalonVerificationRequest,
            "salon_id" | "submitted_by" | "decision"
          >;
        Update: Partial<SalonVerificationRequest>;
      };
      user_activities: {
        Row: UserActivity;
        Insert: Partial<UserActivity> &
          Pick<UserActivity, "user_id" | "activity_type">;
        Update: Partial<UserActivity>;
      };
    };
    Enums: {
      user_role: UserRole;
      salon_verification_status: SalonVerificationStatus;
      booking_status: BookingStatus;
      service_category: ServiceCategory;
      notification_type: NotificationType;
      verification_decision: VerificationDecision;
      day_of_week: DayOfWeek;
    };
    Functions: {
      get_available_slots: {
        Args: {
          p_salon_id: string;
          p_service_id: string;
          p_barber_id?: string | null;
          p_date?: string;
          p_slot_interval_minutes?: number;
          p_buffer_minutes?: number;
        };
        Returns: AvailableSlot[];
      };
      create_booking: {
        Args: {
          p_salon_id: string;
          p_service_id: string;
          p_appointment_start: string;
          p_barber_id?: string | null;
          p_customer_id?: string | null;
          p_customer_notes?: string | null;
          p_is_walk_in?: boolean;
        };
        Returns: Booking;
      };
      check_in_with_qr: {
        Args: { p_qr_token: string };
        Returns: Booking;
      };
      transition_booking_status: {
        Args: {
          p_booking_id: string;
          p_to_status: BookingStatus;
          p_note?: string | null;
        };
        Returns: Booking;
      };
      submit_booking_review: {
        Args: {
          p_booking_id: string;
          p_rating: number;
          p_comment?: string | null;
        };
        Returns: {
          review_id: string;
          booking_id: string;
          salon_id: string;
          rating: number;
          success: boolean;
        };
      };
      search_salons: {
        Args: {
          p_query?: string | null;
          p_city?: string | null;
          p_category?: ServiceCategory | null;
          p_verified_only?: boolean;
          p_limit?: number;
          p_offset?: number;
        };
        Returns: Salon[];
      };
      get_nearby_salons: {
        Args: {
          p_latitude: number;
          p_longitude: number;
          p_radius_km?: number;
          p_category?: ServiceCategory | null;
          p_limit?: number;
          p_offset?: number;
        };
        Returns: Salon[];
      };
      log_user_activity: {
        Args: {
          p_activity_type: UserActivityType;
          p_salon_id?: string | null;
          p_service_id?: string | null;
          p_category?: ServiceCategory | null;
          p_metadata?: Record<string, unknown>;
        };
        Returns: string | null;
      };
      get_personalized_recommendations: {
        Args: {
          p_user_id?: string | null;
          p_latitude?: number | null;
          p_longitude?: number | null;
          p_limit?: number;
        };
        Returns: RecommendedSalon[];
      };
      get_user_recent_activity: {
        Args: {
          p_user_id?: string | null;
          p_limit?: number;
        };
        Returns: UserRecentActivity[];
      };
    };
  };
};
