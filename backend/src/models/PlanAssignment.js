import mongoose from "mongoose";

const planAssignmentSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    assignedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    source: {
      type: String,
      enum: ["ai", "coach"],
      required: true,
      index: true,
    },
    workoutPlan: [{ type: String, trim: true }],
    nutritionPlan: [{ type: String, trim: true }],
    notes: { type: String, trim: true, default: "" },
    active: { type: Boolean, default: true, index: true },
  },
  { timestamps: true }
);

export const PlanAssignment =
  mongoose.models.PlanAssignment ??
  mongoose.model("PlanAssignment", planAssignmentSchema);
