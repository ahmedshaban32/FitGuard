import { User, ROLES } from "../models/User.js";
import { CoachApplication } from "../models/CoachApplication.js";
import { Subscription } from "../models/Subscription.js";
import { Exercise } from "../models/Exercise.js";
import { WorkoutSession } from "../models/WorkoutSession.js";
import { AppError } from "../middlewares/errorHandler.js";

function toPublicUser(user) {
  return {
    id: user.id,
    email: user.email,
    role: user.role,
    profile: user.profile,
    createdAt: user.createdAt,
  };
}

export async function getDashboard(req, res, next) {
  try {
    const [users, trainers, activeSubscriptions, pendingCoachApplications, exercises, sessions] =
      await Promise.all([
        User.countDocuments({}),
        User.countDocuments({ role: "trainer" }),
        Subscription.countDocuments({ status: "active", endDate: { $gt: new Date() } }),
        CoachApplication.countDocuments({ status: "pending" }),
        Exercise.countDocuments({ isActive: true }),
        WorkoutSession.countDocuments({}),
      ]);

    res.json({
      metrics: {
        users,
        trainers,
        activeSubscriptions,
        pendingCoachApplications,
        activeExercises: exercises,
        loggedSessions: sessions,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function listUsers(req, res, next) {
  try {
    const page = Math.max(Number(req.query.page ?? 1), 1);
    const limit = Math.min(Math.max(Number(req.query.limit ?? 20), 1), 100);
    const skip = (page - 1) * limit;
    const role = req.query.role ? String(req.query.role) : null;
    const search = req.query.search ? String(req.query.search).trim() : "";

    const query = {};
    if (role) {
      if (!ROLES.includes(role)) {
        throw new AppError("Invalid role filter", { code: "VALIDATION_ERROR" });
      }
      query.role = role;
    }
    if (search) {
      query.email = { $regex: search, $options: "i" };
    }

    const [items, total] = await Promise.all([
      User.find(query).sort({ createdAt: -1 }).skip(skip).limit(limit),
      User.countDocuments(query),
    ]);

    res.json({
      users: items.map(toPublicUser),
      pagination: { page, limit, total, pages: Math.ceil(total / limit) || 1 },
    });
  } catch (err) {
    next(err);
  }
}

export async function getUserById(req, res, next) {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      throw new AppError("User not found", { statusCode: 404, code: "NOT_FOUND" });
    }
    res.json({ user: toPublicUser(user) });
  } catch (err) {
    next(err);
  }
}

export async function updateUserRole(req, res, next) {
  try {
    const { role } = req.body ?? {};
    if (!ROLES.includes(role)) {
      throw new AppError(`role must be one of: ${ROLES.join(", ")}`, {
        code: "VALIDATION_ERROR",
      });
    }
    const user = await User.findById(req.params.id);
    if (!user) {
      throw new AppError("User not found", { statusCode: 404, code: "NOT_FOUND" });
    }
    user.role = role;
    await user.save();
    res.json({ user: toPublicUser(user) });
  } catch (err) {
    next(err);
  }
}
