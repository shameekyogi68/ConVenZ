import jwt from "jsonwebtoken";
import User from "../models/userModel.js";

// JWT Secret Key - ideally in .env
const JWT_SECRET = process.env.JWT_SECRET || "convenz_super_secret_key_123!";

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
      const decoded = jwt.verify(token, JWT_SECRET);

      // Find user by decoded ID, minus the sensitive data
      req.user = await User.findOne({ user_id: decoded.userId }).select("-otp -otpExpiry");

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
 */
export const generateToken = (userId) => {
  return jwt.sign({ userId }, JWT_SECRET, {
    expiresIn: "30d", // Token valid for 30 days
  });
};
