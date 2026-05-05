import { Exercise } from "../models/Exercise.js";
import { WorkoutSession } from "../models/WorkoutSession.js";
import { AppError } from "../middlewares/errorHandler.js";

export async function createWorkoutSession(req, res, next) {
  try {
    const { exerciseId, totalReps, correctReps, wrongReps, mistakes } = req.body ?? {};
    if (!exerciseId) {
      throw new AppError("exerciseId is required", { code: "VALIDATION_ERROR" });
    }

    const exercise = await Exercise.findById(exerciseId);
    if (!exercise) {
      throw new AppError("Exercise not found", { statusCode: 404, code: "NOT_FOUND" });
    }

    if ((Number(correctReps) || 0) + (Number(wrongReps) || 0) !== Number(totalReps)) {
      throw new AppError("correctReps + wrongReps must equal totalReps", {
        code: "VALIDATION_ERROR",
      });
    }

    const session = await WorkoutSession.create({
      userId: req.auth.userId,
      exerciseId,
      tracked: exercise.type === "tracked",
      totalReps,
      correctReps,
      wrongReps,
      mistakes: Array.isArray(mistakes) ? mistakes : [],
      sessionAt: new Date(),
    });

    res.status(201).json({ session });
  } catch (err) {
    next(err);
  }
}

export async function getMyProgress(req, res, next) {
  try {
    const sessions = await WorkoutSession.find({ userId: req.auth.userId })
      .populate("exerciseId", "name type")
      .sort({ sessionAt: -1 })
      .limit(100);

    const summary = sessions.reduce(
      (acc, s) => {
        acc.totalReps += s.totalReps;
        acc.correctReps += s.correctReps;
        acc.wrongReps += s.wrongReps;
        return acc;
      },
      { totalReps: 0, correctReps: 0, wrongReps: 0 }
    );
    const accuracy =
      summary.totalReps > 0 ? Number((summary.correctReps / summary.totalReps).toFixed(3)) : 0;

    res.json({
      summary: { ...summary, accuracy },
      sessions,
    });
  } catch (err) {
    next(err);
  }
}
