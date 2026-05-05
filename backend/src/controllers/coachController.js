import { CoachApplication } from "../models/CoachApplication.js";
import { User } from "../models/User.js";
import { AppError } from "../middlewares/errorHandler.js";

export async function applyForCoach(req, res, next) {
  try {
    if (!req.auth?.userId) {
      throw new AppError("Unauthorized", { statusCode: 401, code: "UNAUTHORIZED" });
    }
    const { bio, specialties } = req.body ?? {};
    const existing = await CoachApplication.findOne({ userId: req.auth.userId });
    if (existing && existing.status === "pending") {
      throw new AppError("Application already pending", {
        statusCode: 409,
        code: "APPLICATION_PENDING",
      });
    }

    const app = await CoachApplication.findOneAndUpdate(
      { userId: req.auth.userId },
      {
        $set: {
          bio: String(bio ?? "").trim(),
          specialties: Array.isArray(specialties)
            ? specialties.map((s) => String(s).trim()).filter(Boolean)
            : [],
          status: "pending",
          decisionNote: "",
          reviewedBy: null,
          reviewedAt: null,
        },
      },
      { upsert: true, new: true }
    );

    res.status(201).json({ application: app });
  } catch (err) {
    next(err);
  }
}

export async function listPublicCoaches(req, res, next) {
  try {
    const coaches = await User.find({ role: "trainer" }).select("email profile");
    res.json({
      coaches: coaches.map((c) => ({
        id: c.id,
        email: c.email,
        name: c.profile?.name ?? null,
      })),
    });
  } catch (err) {
    next(err);
  }
}

export async function listApplications(req, res, next) {
  try {
    const items = await CoachApplication.find({ status: "pending" })
      .sort({ createdAt: 1 })
      .populate("userId", "email profile");
    res.json({ applications: items });
  } catch (err) {
    next(err);
  }
}

export async function decideApplication(req, res, next) {
  try {
    const { id } = req.params;
    const { decision, note } = req.body ?? {};
    if (!["approved", "rejected"].includes(decision)) {
      throw new AppError("decision must be approved or rejected", {
        code: "VALIDATION_ERROR",
      });
    }

    const app = await CoachApplication.findById(id);
    if (!app) {
      throw new AppError("Application not found", { statusCode: 404, code: "NOT_FOUND" });
    }

    app.status = decision;
    app.decisionNote = String(note ?? "").trim();
    app.reviewedBy = req.auth.userId;
    app.reviewedAt = new Date();
    await app.save();

    if (decision === "approved") {
      await User.findByIdAndUpdate(app.userId, { $set: { role: "trainer" } });
    }

    if (decision === "rejected") {
      await User.findByIdAndUpdate(app.userId, { $set: { role: "user" } });
    }

    res.json({ application: app });
  } catch (err) {
    next(err);
  }
}
