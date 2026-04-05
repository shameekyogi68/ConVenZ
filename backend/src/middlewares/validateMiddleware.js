import Joi from 'joi';

/**
 * 🛠️ VALIDATION MIDDLEWARE
 * 
 * Pre-validates incoming request bodies against a Joi schema.
 * Prevents invalid data from reaching the controllers.
 */
export const validate = (schema) => (req, res, next) => {
  const { error } = schema.validate(req.body, { abortEarly: false });

  if (error) {
    const errorDetails = error.details.map(detail => detail.message).join(', ');
    // Log count and path only — never log user-supplied values to avoid log injection
    console.log(`❌ VALIDATION_FAILED | ${req.method} ${req.path} | ${error.details.length} error(s)`);

    return res.status(400).json({
      success: false,
      message: "Validation failed",
      errors: errorDetails,
    });
  }

  next();
};

/**
 * 📋 AUTH VALIDATION SCHEMAS
 */
export const authSchemas = {
  register: Joi.object({
    phone: Joi.number().required().min(1000000000).max(999999999999),
    fcmToken: Joi.string().allow(null, '')
  }),
  verifyOtp: Joi.object({
    phone: Joi.number().required(),
    otp: Joi.number().required().min(1000).max(9999)
  })
};

/**
 * 📍 USER VALIDATION SCHEMAS
 */
export const userSchemas = {
  updateProfile: Joi.object({
    name: Joi.string().min(2).max(50),
    gender: Joi.string().valid('Male', 'Female', 'Other'),
    address: Joi.string().allow('', null)
  }),
  updateLocation: Joi.object({
    latitude: Joi.number().required().min(-90).max(90),
    longitude: Joi.number().required().min(-180).max(180),
    address: Joi.string().allow('', null)
  })
};

/**
 * 📅 BOOKING VALIDATION SCHEMAS
 */
export const bookingSchemas = {
  create: Joi.object({
    selectedService: Joi.string().required(),
    jobDescription: Joi.string().required(),
    date: Joi.string().required(),
    time: Joi.string().required(),
    location: Joi.object({
      latitude: Joi.number().required(),
      longitude: Joi.number().required(),
      address: Joi.string().required()
    }).required()
  }),
  statusUpdate: Joi.object({
    bookingId: Joi.alternatives().try(Joi.number(), Joi.string()).required(),
    status: Joi.string()
      .valid('accepted', 'rejected', 'enroute', 'completed', 'cancelled')
      .required(),
    vendorId: Joi.alternatives().try(Joi.number(), Joi.string()).optional(),
    otpStart: Joi.number().integer().min(1000).max(9999).optional(),
    rejectionReason: Joi.string().max(500).optional(),
  }),
};

/**
 * 🔔 NOTIFICATION VALIDATION SCHEMAS
 */
export const notificationSchemas = {
  updateFcmToken: Joi.object({
    fcmToken: Joi.string().min(10).required(),
  }),
};
