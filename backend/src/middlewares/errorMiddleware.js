/**
 * 🛠️ GLOBAL ERROR HANDLER
 * 
 * Standardizes all API error responses. 
 * Converts any caught error into a clean JSON response with proper status codes.
 */
export const notFound = (req, res, next) => {
  const error = new Error(`Not Found - ${req.originalUrl}`);
  res.status(404);
  next(error);
};

export const errorHandler = (err, req, res, next) => {
  const statusCode = res.statusCode === 200 ? 500 : res.statusCode;
  
  console.error(`❌ ERROR_LOG | ${new Date().toISOString()} | Method: ${req.method} | Path: ${req.path}`);
  console.error(`   Message: ${err.message}`);
  if (process.env.NODE_ENV !== 'production') {
    console.error(`   Stack: ${err.stack}`);
  }

  res.status(statusCode).json({
    success: false,
    message: err.message,
    stack: process.env.NODE_ENV === "production" ? null : err.stack,
  });
};
