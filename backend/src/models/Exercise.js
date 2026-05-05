import mongoose from "mongoose";

const exerciseSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true, index: true },
    type: { type: String, enum: ["tracked", "guided"], required: true, index: true },
    instructions: { type: String, required: true, trim: true },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

export const Exercise =
  mongoose.models.Exercise ?? mongoose.model("Exercise", exerciseSchema);
