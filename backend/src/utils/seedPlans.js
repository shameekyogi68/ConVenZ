import Plan from "../models/planModel.js";
import logger from "./logger.js";

/**
 * Ensure at least 3 active customer plans exist.
 * Idempotent: runs safely on every startup.
 *
 * This is to prevent empty subscription screens in production.
 */
export async function seedDefaultPlansIfEmpty() {
  try {
    const existingActiveCustomerPlans = await Plan.countDocuments({
      active: true,
      planType: "customer",
    });

    if (existingActiveCustomerPlans >= 3) {
      return;
    }

    // Only seed when there are no active customer plans at all.
    if (existingActiveCustomerPlans > 0) {
      logger.info({
        event: "PLANS_SEED_SKIPPED",
        reason: "some_active_customer_plans_exist",
        count: existingActiveCustomerPlans,
      });
      return;
    }

    const plans = [
      {
        name: "Basic Plan",
        price: 199,
        duration: "1 month",
        features: ["Basic access", "Email support"],
        planType: "customer",
        active: true,
      },
      {
        name: "Pro Plan",
        price: 499,
        duration: "3 months",
        features: ["Unlimited bookings", "Priority support"],
        planType: "customer",
        active: true,
      },
      {
        name: "Premium Plan",
        price: 999,
        duration: "1 year",
        features: ["24/7 support", "Premium vendor matching", "Best offers"],
        planType: "customer",
        active: true,
      },
    ];

    await Plan.insertMany(plans, { ordered: true });

    logger.info({
      event: "PLANS_SEEDED",
      planType: "customer",
      count: plans.length,
    });
  } catch (err) {
    // Never crash the server for seeding.
    logger.error({ err }, "PLANS_SEED_FAILED");
  }
}

