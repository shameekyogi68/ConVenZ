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
    selectedService: Joi.string().valid(
      'Cleaning', 'Plumbing', 'Electrician', 'Painting', 
      'Moving', 'AC Repair', 'Sofa Cleaning', 'Car Wash'
    ).required(),
    jobDescription: Joi.string().required(),
    date: Joi.string().pattern(/^\d{4}-\d{2}-\d{2}$/).required().messages({
      'string.pattern.base': 'Date must be in YYYY-MM-DD format'
    }),
    time: Joi.string().pattern(/^\d{2}:\d{2}(:\d{2})?$/).required().messages({
      'string.pattern.base': 'Time must be in HH:MM or HH:MM:SS format'
    }),
    location: Joi.object({
      latitude: Joi.number().min(-90).max(90).required(),
      longitude: Joi.number().min(-180).max(180).required(),
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
  review: Joi.object({
    rating: Joi.number().min(1).max(5).required(),
    reviewText: Joi.string().max(1000).optional().allow('')
  }),
  verifyOtp: Joi.object({
    otp: Joi.number().integer().min(1000).max(9999).required(),
  }),
  mockProgress: Joi.object({
    status: Joi.string().valid("enroute", "completed").required(),
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

/**
 * 🎟️ SUBSCRIPTION VALIDATION SCHEMAS
 */
export const subscriptionSchemas = {
  createPlan: Joi.object({
    name: Joi.string().required().max(100),
    price: Joi.number().required().min(0),
    duration: Joi.string().required().max(50),
    features: Joi.array().items(Joi.string()).optional(),
    planType: Joi.string().valid("customer", "vendor", "admin").optional(),
  }),
  purchase: Joi.object({
    planId: Joi.string().required(),
  }),
};

