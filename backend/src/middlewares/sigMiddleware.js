import crypto from "crypto";
import logger from "../utils/logger.js";

const API_SIGNING_SECRET = process.env.API_SIGNING_SECRET || 'convenz_default_secret_key_2024_@!';
const MAX_TIMESTAMP_DIFF = 5 * 60 * 1000; // 5 minutes in milliseconds

/**
 * Middleware to verify HMAC-SHA256 request signature
 */
export const verifySignature = (req, res, next) => {
  // Skip signature verification in development if explicitly disabled
  if (process.env.SKIP_SIG_VERIFY === "true") {
    return next();
  }

  const signature = req.headers["x-signature"];
  const timestamp = req.headers["x-timestamp"];

  if (!signature || !timestamp) {
    logger.error("🚨 SIGNATURE_ERROR | Missing signature or timestamp headers");
    return res.status(403).json({
      success: false,
      message: "Security violation: Missing request signature",
    });
  }

  // 1. Verify timestamp to prevent replay attacks
  const now = Date.now();
  const requestTime = parseInt(timestamp);
  const diff = Math.abs(now - requestTime);

  if (isNaN(requestTime) || diff > MAX_TIMESTAMP_DIFF) {
    logger.error(`🚨 SIGNATURE_ERROR | Replay attack suspected or clock drift. Diff: ${diff}ms`);
    return res.status(403).json({
      success: false,
      message: "Security violation: Request expired or clock drift",
    });
  }

  // 2. Re-generate signature and compare
  try {
    const method = req.method.toUpperCase();
    
    // In Express, the path for the route is in req.path or req.originalUrl
    // We used options.path in Flutter (which is the endpoint suffix like /user/register)
    // However, in ApiService.post(endpoint, data), options.path IS the full path if we use absolute URL
    // Actually, in ApiService.dart:
    // final dataToSign = '${options.method.toUpperCase()}|${options.path}|$timestamp|$bodyString';
    // options.path here depends on how Dio is configured.
    // If baseUrl is set, options.path is the relative path.
    
    // Let's check how options.path is resolved in Dio.
    // Usually, it's the relative path passed to .post()
    
    // In backend, req.path is usually the relative path from the mount point.
    // req.originalUrl is the full path including /api/v1
    
    // We need to match exactly what the frontend sends.
    // In ApiService.dart:
    // static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    //   return postUrl(endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint', data);
    // }
    // And postUrl calls _client.post(absoluteUrl, data: data).
    // So options.path in Dio interceptor WILL BE the absolute URL because it's passed as such.
    
    // Wait, if options.path is the absolute URL, we need to handle that in the backend.
    
    const bodyString = req.body && Object.keys(req.body).length > 0 
      ? JSON.stringify(req.body) 
      : "";
    
    // Cloud-safe signature: Use the relative path instead of the full absolute URL
    // to avoid protocol (http vs https) or host mismatches on proxy layers.
    const path = req.originalUrl;
    
    const dataToSign = `${method}|${path}|${timestamp}|${bodyString}`;
    
    const expectedSignature = crypto
      .createHmac("sha256", API_SIGNING_SECRET)
      .update(dataToSign)
      .digest("hex");

    if (signature !== expectedSignature) {
      logger.error(`🚨 SIGNATURE_ERROR | Mismatch! Expected sig for: ${dataToSign}`);
      return res.status(403).json({
        success: false,
        message: "Security violation: Invalid request signature",
      });
    }

    next();
  } catch (error) {
    logger.error(`🚨 SIGNATURE_ERROR | Verification failed: ${error.message}`);
    return res.status(500).json({
      success: false,
      message: "Internal security error",
    });
  }
};
