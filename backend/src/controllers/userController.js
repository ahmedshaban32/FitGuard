import { User } from "../models/User.js";
import { PlanAssignment } from "../models/PlanAssignment.js";
import { AppError } from "../middlewares/errorHandler.js";

function assertAuth(req) {
  if (!req.auth?.userId) {
    throw new AppError("Unauthorized", { statusCode: 401, code: "UNAUTHORIZED" });
  }
}

export async function getProfile(req, res, next) {
  try {
    assertAuth(req);
    const user = await User.findById(req.auth.userId);
    if (!user) {
      throw new AppError("User not found", { statusCode: 404, code: "NOT_FOUND" });
    }
    res.json({ profile: user.profile ?? {} });
  } catch (err) {
    next(err);
  }
}

export async function updateProfile(req, res, next) {
  try {
    assertAuth(req);
    const { name, heightCm, weightKg, goal } = req.body ?? {};
    const user = await User.findById(req.auth.userId);
    if (!user) {
      throw new AppError("User not found", { statusCode: 404, code: "NOT_FOUND" });
    }

    user.profile = {
      ...user.profile,
      ...(name !== undefined ? { name: String(name).trim() } : {}),
      ...(heightCm !== undefined ? { heightCm } : {}),
      ...(weightKg !== undefined ? { weightKg } : {}),
      ...(goal !== undefined ? { goal } : {}),
    };

    await user.save();
    res.json({ profile: user.profile });
  } catch (err) {
    next(err);
  }
}

export async function generateAiPlan(req, res, next) {
  try {
    assertAuth(req);
    const user = await User.findById(req.auth.userId);
    if (!user) {
      throw new AppError("User not found", { statusCode: 404, code: "NOT_FOUND" });
    }
    const { heightCm, weightKg, goal } = user.profile ?? {};
    if (!heightCm || !weightKg || !goal) {
      throw new AppError("Profile must include heightCm, weightKg and goal", {
        code: "VALIDATION_ERROR",
      });
    }

    await PlanAssignment.updateMany(
      { userId: user.id, source: "ai", active: true },
      { $set: { active: false } }
    );

    const plan = await PlanAssignment.create({
      userId: user.id,
      assignedBy: user.id,
      source: "ai",
      workoutPlan: [
        `3 full-body sessions/week focused on ${goal}`,
        "Start each session with dynamic warm-up",
      ],
      nutritionPlan: [
        "Prioritize whole foods and hydration",
        `Set calories for ${goal} with weekly check-ins`,
      ],
      notes: "Generated from profile inputs. External AI integration pending.",
      active: true,
    });

    res.status(201).json({ plan });
  } catch (err) {
    next(err);
  }
}
