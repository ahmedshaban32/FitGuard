import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { User } from "../models/User.js";
import { env } from "../config.js";
import { AppError } from "../middlewares/errorHandler.js";

const SALT_ROUNDS = 10;

function normalizeEmail(email) {
  return String(email ?? "").trim().toLowerCase();
}

function normalizeRole(role) {
  const r = String(role ?? "user").toLowerCase();
  if (r === "trainer") return "trainer";
  if (r === "admin") {
    throw new AppError("Cannot self-register as admin", {
      statusCode: 403,
      code: "FORBIDDEN_ROLE",
    });
  }
  return "user";
}

function publicUser(doc) {
  return {
    id: doc.id,
    email: doc.email,
    role: doc.role,
    profile: doc.profile
      ? {
          name: doc.profile.name ?? null,
          heightCm: doc.profile.heightCm ?? null,
          weightKg: doc.profile.weightKg ?? null,
          goal: doc.profile.goal ?? null,
        }
      : {},
  };
}

export async function register(req, res, next) {
  try {
    const { email, password, role, name } = req.body ?? {};
    const em = normalizeEmail(email);

    if (!em) {
      throw new AppError("Email is required", { code: "VALIDATION_ERROR" });
    }
    if (!password || password.length < 8) {
      throw new AppError("Password must be at least 8 characters", {
        code: "VALIDATION_ERROR",
      });
    }

    const taken = await User.exists({ email: em });
    if (taken) {
      throw new AppError("Email already registered", {
        statusCode: 409,
        code: "EMAIL_TAKEN",
      });
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
    const userRole = normalizeRole(role);
    const profile = name?.trim() ? { name: name.trim() } : {};

    const doc = await User.create({
      email: em,
      passwordHash,
      role: userRole,
      profile,
    });

    res.status(201).json({ user: publicUser(doc) });
  } catch (err) {
    next(err);
  }
}

export async function login(req, res, next) {
  try {
    const { email, password } = req.body ?? {};
    const em = normalizeEmail(email);

    if (!em || !password) {
      throw new AppError("Email and password are required", {
        code: "VALIDATION_ERROR",
      });
    }

    const doc = await User.findOne({ email: em }).select("+passwordHash");
    if (!doc) {
      throw new AppError("Invalid email or password", {
        statusCode: 401,
        code: "INVALID_CREDENTIALS",
      });
    }

    const ok = await bcrypt.compare(password, doc.passwordHash);
    if (!ok) {
      throw new AppError("Invalid email or password", {
        statusCode: 401,
        code: "INVALID_CREDENTIALS",
      });
    }

    const token = jwt.sign(
      { sub: doc.id, role: doc.role },
      env.jwtSecret,
      { expiresIn: env.jwtExpiresIn }
    );

    res.json({ token, user: publicUser(doc) });
  } catch (err) {
    next(err);
  }
}

export async function me(req, res, next) {
  try {
    if (!req.auth?.userId) {
      throw new AppError("Unauthorized", { statusCode: 401, code: "UNAUTHORIZED" });
    }

    const doc = await User.findById(req.auth.userId);
    if (!doc) {
      throw new AppError("User not found", { statusCode: 404, code: "NOT_FOUND" });
    }

    res.json({
      user: {
        ...publicUser(doc),
        emailVerifiedAt: doc.emailVerifiedAt,
      },
    });
  } catch (err) {
    next(err);
  }
}
