export class AppError extends Error {
  constructor(message, { statusCode = 400, code = "APP_ERROR" } = {}) {
    super(message);
    this.name = "AppError";
    this.statusCode = statusCode;
    this.code = code;
  }
}

export function errorHandler(err, req, res, next) {
  if (res.headersSent) {
    next(err);
    return;
  }

  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      error: { code: err.code, message: err.message },
    });
    return;
  }

  const status = err.statusCode ?? err.status ?? 500;
  const message =
    process.env.NODE_ENV === "production" && status === 500
      ? "Internal server error"
      : err.message ?? "Internal server error";

  res.status(status >= 400 ? status : 500).json({
    error: { code: "INTERNAL_ERROR", message },
  });
}
