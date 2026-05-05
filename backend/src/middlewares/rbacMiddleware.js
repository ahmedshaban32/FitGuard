import { AppError } from "./errorHandler.js";

export function requireRole(...roles) {
  return (req, res, next) => {
    const role = req.auth?.role;
    if (!role || !roles.includes(role)) {
      next(
        new AppError("Forbidden", {
          statusCode: 403,
          code: "FORBIDDEN",
        })
      );
      return;
    }
    next();
  };
}
