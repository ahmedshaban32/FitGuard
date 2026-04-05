import mongoose from "mongoose";

export const ROLES = ["user", "trainer", "admin"];

const ProfileSchema = new mongoose.Schema(
  {
    name: { type: String, trim: true },
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
