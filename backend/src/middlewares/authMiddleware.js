import jwt from "jsonwebtoken";
import User from "../models/userModel.js";

// JWT Secret Key - must be set in environment variables
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  console.error("❌ FATAL: JWT_SECRET environment variable is not set. Server cannot start securely.");
  process.exit(1);
}

/**
 * Middleware to protect routes using JWT
 */
export const protect = async (req, res, next) => {
  let token;

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith("Bearer")
  ) {
    try {
      // Extract token from Bearer <token>
      token = req.headers.authorization.split(" ")[1];

      // Decode and verify token
      /** @type {any} */
      const decoded = jwt.verify(token, JWT_SECRET);

      if (typeof decoded === "string") {
        return res.status(401).json({ success: false, message: "Invalid token format" });
      }

      // otp and otpExpiry have select:false in the schema — excluded automatically
      req.user = await User.findOne({ user_id: decoded.userId });

      if (req.user && decoded.tokenVersion !== req.user.tokenVersion) {
        return res.status(401).json({ success: false, message: "Token revoked" });
      }

      if (!req.user) {
        return res.status(401).json({ success: false, message: "User not found, token invalid" });
      }

      if (req.user.isBlocked) {
        return res.status(403).json({ success: false, message: "User is blocked by admin" });
      }

      next();
    } catch (error) {
      console.error(`❌ JWT_AUTH_ERROR | Token failed: ${error.message}`);
      return res.status(401).json({ success: false, message: "Not authorized, token failed" });
    }
  }

  if (!token) {
    return res.status(401).json({ success: false, message: "Not authorized, no token provided" });
  }
};

/**
 * Helper to generate JWT Token
 * @param {string | number} userId
 * @param {number} tokenVersion
 */
export const generateToken = (userId, tokenVersion = 0) => {
  return jwt.sign({ userId, tokenVersion }, JWT_SECRET, {
    expiresIn: /** @type {any} */ (process.env.SESSION_EXPIRY || "30d"),
  });
};
