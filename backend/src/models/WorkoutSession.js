import mongoose from "mongoose";

const mistakeItemSchema = new mongoose.Schema(
  {
    type: { type: String, required: true, trim: true },
    count: { type: Number, required: true, min: 1 },
  },
  { _id: false }
);

const workoutSessionSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    exerciseId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Exercise",
      required: true,
      index: true,
    },
    tracked: { type: Boolean, required: true },
    totalReps: { type: Number, required: true, min: 0 },
    correctReps: { type: Number, required: true, min: 0 },
    wrongReps: { type: Number, required: true, min: 0 },
    mistakes: { type: [mistakeItemSchema], default: [] },
    sessionAt: { type: Date, required: true, default: () => new Date(), index: true },
  },
  { timestamps: true }
);

export const WorkoutSession =
  mongoose.models.WorkoutSession ??
  mongoose.model("WorkoutSession", workoutSessionSchema);
