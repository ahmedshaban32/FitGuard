import mongoose from "mongoose";

export const ROLES = ["user", "trainer", "admin"];

const ProfileSchema = new mongoose.Schema(
  {
    name: { type: String, trim: true },
    heightCm: { type: Number, min: 80, max: 260, default: null },
    weightKg: { type: Number, min: 20, max: 350, default: null },
    goal: {
      type: String,
      enum: ["fat_loss", "muscle_gain", "mobility", "general_fitness"],
      default: null,
    },
  },
  { _id: false }
);

const userSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      index: true,
    },
    passwordHash: { type: String, required: true, select: false },
    role: { type: String, enum: ROLES, default: "user" },
    profile: { type: ProfileSchema, default: () => ({}) },
    emailVerifiedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

export const User =
  mongoose.models.User ?? mongoose.model("User", userSchema);
