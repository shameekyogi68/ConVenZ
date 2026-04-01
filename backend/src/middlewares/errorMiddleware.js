/**
 * 🛠️ GLOBAL ERROR HANDLER
 * 
 * - In DEVELOPMENT: returns full error message + stack trace
 * - In PRODUCTION:  returns only safe, user-friendly messages
 *                   (no internal details, no stack traces)
 */

// Map HTTP status codes to user-friendly messages
const USER_SAFE_MESSAGES = {
  400: "Invalid request. Please check your input and try again.",
  401: "You need to be logged in to do that.",
  403: "You don't have permission to perform this action.",
  404: "The requested resource was not found.",
  409: "A conflict occurred. This action cannot be completed.",
  422: "The provided data is invalid.",
  429: "Too many requests. Please slow down and try again.",
  500: "Something went wrong on our end. Please try again later.",
  502: "Service temporarily unavailable. Please try again.",
  503: "Service is down for maintenance. Please check back soon.",
};

export const notFound = (req, res, next) => {
  const error = new Error(`Not Found: ${req.originalUrl}`);
  res.status(404);
  next(error);
};

export const errorHandler = (err, req, res, next) => {
  const statusCode = res.statusCode === 200 ? 500 : res.statusCode;
  const isProduction = process.env.NODE_ENV === "production";

  // Always log full error server-side
  console.error(`❌ [ERROR] ${new Date().toISOString()} | ${req.method} ${req.path}`);
  console.error(`   Status: ${statusCode} | Message: ${err.message}`);
  if (!isProduction) {
    console.error(`   Stack: ${err.stack}`);
  }

  // In production: return safe messages only
  const safeMessage =
    isProduction
      ? (USER_SAFE_MESSAGES[statusCode] || USER_SAFE_MESSAGES[500])
      : err.message;

  res.status(statusCode).json({
    success: false,
    message: safeMessage,
    // Only include stack in development
    ...(isProduction ? {} : { stack: err.stack }),
  });
};
