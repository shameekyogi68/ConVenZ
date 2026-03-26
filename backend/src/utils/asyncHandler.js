/**
 * ✨ ELITE ASYNC WRAPPER
 * Standardizes async error catching for all routes.
 */
const asyncHandler = (fn) => (req, res, next) => {
  return Promise.resolve(fn(req, res, next)).catch(next);
};

export default asyncHandler;
