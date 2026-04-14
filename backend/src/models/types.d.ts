import { Document, Types } from "mongoose";

export interface IUser {
  user_id: number;
  phone: number;
  name?: string;
  gender?: "Male" | "Female" | "Other";
  location?: {
    type: "Point";
    coordinates: number[];
  };
  address?: string;
  isOnline: boolean;
  subscription?: Types.ObjectId;
  fcmToken?: string;
  isBlocked: boolean;
  blockReason?: string;
  blockedAt?: Date;
  tokenVersion: number;
  otp?: string;
  otpExpiry?: Date;
  otpAttempts: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface IVendor {
  vendor_id: number;
  phone: number;
  name?: string;
  email?: string;
  selectedServices: string[];
  location?: {
    type: "Point";
    coordinates: number[];
  };
  address?: string;
  fcmTokens: string[];
  rating: number;
  totalBookings: number;
  completedBookings: number;
  totalRating: number;
  subscription?: Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

export interface IExternalVendor {
  vendorId?: string;
  vendorName?: string;
  vendorPhone?: string;
  vendorAddress?: string;
  serviceType?: string;
  assignedAt?: Date;
  lastUpdated?: Date;
}

export interface IBooking {
  booking_id: number;
  userId: number;
  vendorId?: number;
  selectedService: string;
  jobDescription: string;
  date: string;
  time: string;
  location: {
    type: "Point";
    coordinates: number[];
    address: string;
  };
  status: "pending" | "accepted" | "rejected" | "enroute" | "completed" | "cancelled";
  otpStart?: number;
  distance?: number;
  rejectionReason?: string;
  rating?: number;
  review?: string;
  externalVendor?: IExternalVendor;
  createdAt: Date;
  updatedAt: Date;
}

export interface ISubscription {
  userId: number;
  planId: Types.ObjectId;
  currentPack: string;
  price: number;
  startDate: Date;
  expiryDate: Date;
  status: "Active" | "Expired" | "Cancelled";
  createdAt: Date;
  updatedAt: Date;
}

export interface IPlan {
  name: string;
  price: number;
  duration: string;
  features: string[];
  planType: "customer" | "vendor" | "admin";
  active: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export type UserDocument = IUser & Document;
export type UserModel = import("mongoose").Model<UserDocument>;

export type VendorDocument = IVendor & Document;
export type VendorModel = import("mongoose").Model<VendorDocument>;

export type BookingDocument = IBooking & Document;
export type BookingModel = import("mongoose").Model<BookingDocument>;

export type SubscriptionDocument = ISubscription & Document;
export type SubscriptionModel = import("mongoose").Model<SubscriptionDocument>;

export type PlanDocument = IPlan & Document;
export type PlanModel = import("mongoose").Model<PlanDocument>;
