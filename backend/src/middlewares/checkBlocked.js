import User from "../models/userModel.js";

/* ------------------------------------------------------------
   🚫 CHECK IF USER IS BLOCKED
   
   This middleware checks if a user is blocked before allowing
   any action (booking, profile updates, etc.)
------------------------------------------------------------ */
export const checkUserBlocked = async (req, res, next) => {
  try {
    // Extract userId from token (if protected), otherwise body/params/phone
    const userId = req.user?.user_id || req.body.userId || req.params.userId;
    const phone = req.body.phone;
    
    if (!userId && !phone) {
      // If no userId or phone, skip check (for routes that don't require it)
      return next();
    }

    // Find user by userId or phone
    let user;
    if (userId) {
      user = await User.findOne({ user_id: userId });
    } else if (phone) {
      user = await User.findOne({ phone: phone });
    }
    
    if (!user) {
      return next();
    }

    if (user.isBlocked === true) {
      console.log(`🚫 BLOCKED_ATTEMPT | User: ${user.user_id} | Reason: ${user.blockReason || 'none'}`);
      return res.status(403).json({
        success: false,
        message: "Your account has been blocked by admin. Please contact support.",
        blocked: true,
        blockReason: user.blockReason || "Your account is currently suspended",
        blockedAt: user.blockedAt,
        supportContact: "Contact admin for assistance",
      });
    }

    next();
  } catch (error) {
    console.error('❌ Error in checkUserBlocked middleware:', error.message);
    return res.status(500).json({
      success: false,
      message: "Error checking user status",
    });
  }
};

/* ------------------------------------------------------------
   🔒 BLOCK USER (Admin Only)
------------------------------------------------------------ */
export const blockUser = async (req, res) => {
  try {
    const { userId, blockReason } = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required"
      });
    }

    const user = await User.findOne({ user_id: userId });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found"
      });
    }

    // Block the user
    user.isBlocked = true;
    user.blockReason = blockReason || "Account suspended by admin";
    user.blockedAt = new Date();
    await user.save();

    console.log(`🚫 USER_BLOCKED | User: ${user.user_id} | Reason: ${user.blockReason}`);

    return res.status(200).json({
      success: true,
      message: "User blocked successfully",
      data: {
        userId: user.user_id,
        name: user.name,
        phone: user.phone,
        isBlocked: user.isBlocked,
        blockReason: user.blockReason,
        blockedAt: user.blockedAt
      }
    });

  } catch (error) {
    console.error('❌ Error blocking user:', error.message);
    return res.status(500).json({ success: false, message: "Error blocking user" });
  }
};

/* ------------------------------------------------------------
   🔓 UNBLOCK USER (Admin Only)
------------------------------------------------------------ */
export const unblockUser = async (req, res) => {
  try {
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required"
      });
    }

    const user = await User.findOne({ user_id: userId });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found"
      });
    }

    // Unblock the user
    user.isBlocked = false;
    user.blockReason = null;
    user.blockedAt = null;
    await user.save();

    console.log(`✅ USER_UNBLOCKED | User: ${user.user_id}`);

    return res.status(200).json({
      success: true,
      message: "User unblocked successfully",
      data: {
        userId: user.user_id,
        name: user.name,
        phone: user.phone,
        isBlocked: user.isBlocked
      }
    });

  } catch (error) {
    console.error('❌ Error unblocking user:', error.message);
    return res.status(500).json({ success: false, message: "Error unblocking user" });
  }
};

/* ------------------------------------------------------------
   📋 CHECK USER BLOCK STATUS
------------------------------------------------------------ */
export const checkBlockStatus = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findOne({ user_id: userId });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found"
      });
    }

    return res.status(200).json({
      success: true,
      data: {
        userId: user.user_id,
        name: user.name,
        phone: user.phone,
        isBlocked: user.isBlocked || false,
        blockReason: user.blockReason,
        blockedAt: user.blockedAt
      }
    });

  } catch (error) {
    console.error('❌ Error checking block status:', error.message);
    return res.status(500).json({ success: false, message: "Error checking block status" });
  }
};
