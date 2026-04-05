import Vendor from "../models/vendorModel.js";
import VendorPresence from "../models/vendorPresenceModel.js";
import { calculateDistance } from "./distanceCalculator.js";

/**
 * Find the best vendor for a booking.
 * Uses Mongoose models so compound indexes and field definitions are respected.
 *
 * @param {String} selectedService - Service requested by customer
 * @param {Number} latitude        - Customer's latitude
 * @param {Number} longitude       - Customer's longitude
 * @param {Number} maxDistance     - Maximum search radius in km (default: 50)
 * @returns {Object|null} Best matched vendor with distance info, or null if none found
 */
export const findBestVendor = async (selectedService, latitude, longitude, maxDistance = 50) => {
  // Fetch all online presences — filtered by the { online: 1 } index
  const onlinePresences = await VendorPresence.find({ online: true }).lean();
  if (!onlinePresences.length) return null;

  const onlineVendorIds = onlinePresences.map((p) => p.vendorId);

  // Uses the compound { selectedServices, location: "2dsphere" } index
  const matchingVendors = await Vendor.find({
    vendor_id: { $in: onlineVendorIds },
    selectedServices: selectedService,
  }).lean();

  if (!matchingVendors.length) return null;

  // O(1) presence lookup
  const presenceMap = new Map(onlinePresences.map((p) => [p.vendorId, p]));

  const vendorsWithDistance = [];
  for (const vendor of matchingVendors) {
    const presence = presenceMap.get(vendor.vendor_id);
    if (!presence?.currentLocation?.coordinates?.length) continue;

    const [vendorLon, vendorLat] = presence.currentLocation.coordinates;
    const distance = calculateDistance(latitude, longitude, vendorLat, vendorLon);

    if (distance <= maxDistance) {
      vendorsWithDistance.push({
        vendor,
        presence,
        distance,
        rating: vendor.rating || 0,
        completedBookings: vendor.completedBookings || 0,
      });
    }
  }

  if (!vendorsWithDistance.length) return null;

  // Sort: closest first; break ties by rating, then experience
  vendorsWithDistance.sort((a, b) => {
    const distanceDiff = a.distance - b.distance;
    if (Math.abs(distanceDiff) > 2) return distanceDiff;
    const ratingDiff = b.rating - a.rating;
    if (Math.abs(ratingDiff) > 0.5) return ratingDiff;
    return b.completedBookings - a.completedBookings;
  });

  const best = vendorsWithDistance[0];
  return {
    vendor: {
      vendor_id: best.vendor.vendor_id,
      vendorId: best.vendor.vendor_id,
      name: best.vendor.name,
      phone: best.vendor.phone,
      fcmTokens: best.vendor.fcmTokens || [],
      rating: best.rating,
      completedBookings: best.completedBookings,
    },
    distance: best.distance,
    presence: best.presence,
  };
};

/**
 * Find all online vendors offering a given service (no distance filter).
 */
export const findAllAvailableVendors = async (selectedService) => {
  const onlinePresences = await VendorPresence.find({ online: true }, { vendorId: 1 }).lean();
  const onlineVendorIds = onlinePresences.map((p) => p.vendorId);
  return Vendor.find({
    vendor_id: { $in: onlineVendorIds },
    selectedServices: selectedService,
  }).lean();
};

/**
 * Check if a specific vendor is currently online.
 */
export const isVendorAvailable = async (vendorId) => {
  try {
    const presence = await VendorPresence.findOne({ vendorId }, { online: 1 }).lean();
    return !!presence?.online;
  } catch {
    return false;
  }
};
