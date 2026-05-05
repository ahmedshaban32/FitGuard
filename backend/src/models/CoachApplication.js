import mongoose from "mongoose";

const coachApplicationSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      unique: true,
      index: true,
    },
    bio: { type: String, trim: true, maxlength: 500 },
    specialties: [{ type: String, trim: true }],
    status: {
      type: String,
      enum: ["pending", "approved", "rejected"],
      default: "pending",
      index: true,
    },
    decisionNote: { type: String, trim: true, default: "" },
    reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User", default: null },
    reviewedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

export const CoachApplication =
  mongoose.models.CoachApplication ??
  mongoose.model("CoachApplication", coachApplicationSchema);
