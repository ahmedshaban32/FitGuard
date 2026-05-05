import { Exercise } from "../models/Exercise.js";
import { AppError } from "../middlewares/errorHandler.js";

export async function listExercises(req, res, next) {
  try {
    const filter = { isActive: true };
    if (req.query.type) filter.type = req.query.type;
    const items = await Exercise.find(filter).sort({ name: 1 });
    res.json({ exercises: items });
  } catch (err) {
    next(err);
  }
}

export async function createExercise(req, res, next) {
  try {
    const { name, type, instructions } = req.body ?? {};
    if (!name || !type || !instructions) {
      throw new AppError("name, type and instructions are required", {
        code: "VALIDATION_ERROR",
      });
    }
    const ex = await Exercise.create({ name, type, instructions });
    res.status(201).json({ exercise: ex });
  } catch (err) {
    next(err);
  }
}
