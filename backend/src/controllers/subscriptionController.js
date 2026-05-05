import { Subscription } from "../models/Subscription.js";
import { User } from "../models/User.js";
import { AppError } from "../middlewares/errorHandler.js";

function nextMonth(date) {
  const d = new Date(date);
  d.setMonth(d.getMonth() + 1);
  return d;
}

export async function getMySubscription(req, res, next) {
  try {
    const item = await Subscription.findOne({
      userId: req.auth.userId,
      status: "active",
      endDate: { $gt: new Date() },
    });
    res.json({ subscription: item });
  } catch (err) {
    next(err);
  }
}

export async function subscribeCoach(req, res, next) {
  try {
    const { coachId } = req.body ?? {};
    if (!coachId) {
      throw new AppError("coachId is required", { code: "VALIDATION_ERROR" });
    }

    const coach = await User.findOne({ _id: coachId, role: "trainer" });
    if (!coach) {
      throw new AppError("Coach not found or not approved", {
        statusCode: 404,
        code: "NOT_FOUND",
      });
    }

    const existing = await Subscription.findOne({
      userId: req.auth.userId,
      status: "active",
      endDate: { $gt: new Date() },
    });

    if (existing && String(existing.coachId) !== String(coachId)) {
      throw new AppError("You already have an active coach subscription", {
        statusCode: 409,
        code: "ACTIVE_SUBSCRIPTION_EXISTS",
      });
    }

    if (existing) {
      res.json({ subscription: existing });
      return;
    }

    const startDate = new Date();
    const sub = await Subscription.create({
      userId: req.auth.userId,
      coachId,
      startDate,
      endDate: nextMonth(startDate),
      status: "active",
    });

    res.status(201).json({ subscription: sub });
  } catch (err) {
    next(err);
  }
}

export async function cancelMySubscription(req, res, next) {
  try {
    const item = await Subscription.findOne({
      userId: req.auth.userId,
      status: "active",
      endDate: { $gt: new Date() },
    });
    if (!item) {
      throw new AppError("No active subscription found", {
        statusCode: 404,
        code: "NOT_FOUND",
      });
    }
    item.status = "cancelled";
    item.cancelledAt = new Date();
    await item.save();
    res.json({ subscription: item });
  } catch (err) {
    next(err);
  }
}
