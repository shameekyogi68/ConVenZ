/**
 * @typedef {import('mongoose').Document} Document
 */

/**
 * @typedef {Object} IPlan
 * @property {string} name
 * @property {number} price
 * @property {string} duration
 * @property {string[]} [features]
 * @property {"customer" | "vendor" | "admin"} planType
 * @property {boolean} active
 */

/** @typedef {IPlan & Document} PlanDocument */
/** @typedef {import('mongoose').Model<PlanDocument>} PlanModel */

/**
 * @typedef {Object} ISubscription
 * @property {number} userId
 * @property {import('mongoose').Types.ObjectId} planId
 * @property {string} currentPack
 * @property {number} price
 * @property {Date} expiryDate
 * @property {"Active" | "Expired" | "Cancelled"} status
 */

/** @typedef {ISubscription & Document} SubscriptionDocument */
/** @typedef {import('mongoose').Model<SubscriptionDocument>} SubscriptionModel */

export {};
