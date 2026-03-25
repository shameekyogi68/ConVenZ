import Vendor from "../models/vendorModel.js";
import VendorPresence from "../models/vendorPresenceModel.js";
import { calculateDistance } from "./distanceCalculator.js";

/**
 * Find the best vendor for a booking
 * @param {String} selectedService - Service requested by customer
 * @param {Number} latitude - Customer's latitude
 * @param {Number} longitude - Customer's longitude
 * @param {Number} maxDistance - Maximum distance in km (default: 50km)
 * @returns {Object|null} Best matched vendor with distance info
 */
export const findBestVendor = async (selectedService, latitude, longitude, maxDistance = 50) => {
  try {
    console.log(`\n🔍 === VENDOR MATCHING STARTED ===`);
    console.log(`📍 Customer Location: [${latitude}, ${longitude}]`);
    console.log(`🛠️  Service Requested: ${selectedService}`);
    console.log(`📏 Max Distance: ${maxDistance}km`);

    // Step 1: Find online vendor presences
    const onlinePresences = await VendorPresence.find({ online: true });
    console.log(`🟢 Found ${onlinePresences.length} online vendors`);

    if (onlinePresences.length === 0) {
      console.log('❌ No online vendors available');
      return null;
    }

    // Step 2: Get vendor IDs from online presences
    const onlineVendorIds = onlinePresences.map(p => p.vendorId);

    // Step 3: Find vendors that offer the requested service and are online
    const matchingVendors = await Vendor.find({
      vendor_id: { $in: onlineVendorIds },
      selectedServices: selectedService
    });

    console.log(`🎯 Found ${matchingVendors.length} vendors offering ${selectedService}`);

    if (matchingVendors.length === 0) {
      console.log('❌ No vendors found for this service');
      return null;
    }

    // Step 4: Calculate distances and filter by maxDistance
    const vendorsWithDistance = [];

    for (const vendor of matchingVendors) {
      // Get vendor's current location from presence
      const presence = onlinePresences.find(p => p.vendorId === vendor.vendor_id);
      
      if (!presence || !presence.currentLocation || !presence.currentLocation.coordinates) {
        console.log(`⚠️  Vendor ${vendor.vendor_id} has no location data, skipping`);
        continue;
      }

      const [vendorLon, vendorLat] = presence.currentLocation.coordinates;
      
      const distance = calculateDistance(latitude, longitude, vendorLat, vendorLon);
      
      console.log(`📍 Vendor ${vendor.vendor_id} (${vendor.name}): ${distance}km away`);

      if (distance <= maxDistance) {
        vendorsWithDistance.push({
          vendor,
          presence,
          distance,
          rating: vendor.rating || 0,
          completedBookings: vendor.completedBookings || 0
        });
      }
    }

    console.log(`✅ ${vendorsWithDistance.length} vendors within ${maxDistance}km`);

    if (vendorsWithDistance.length === 0) {
      console.log('❌ No vendors found within distance limit');
      return null;
    }

    // Step 5: Sort by priority (distance, rating, experience)
    vendorsWithDistance.sort((a, b) => {
      // Primary: Distance (closer is better)
      const distanceDiff = a.distance - b.distance;
      if (Math.abs(distanceDiff) > 2) return distanceDiff; // More than 2km difference
      
      // Secondary: Rating (higher is better)
      const ratingDiff = b.rating - a.rating;
      if (Math.abs(ratingDiff) > 0.5) return ratingDiff;
      
      // Tertiary: Experience (more bookings is better)
      return b.completedBookings - a.completedBookings;
    });

    const bestMatch = vendorsWithDistance[0];
    
    console.log(`\n🏆 BEST MATCH FOUND:`);
    console.log(`   Vendor ID: ${bestMatch.vendor.vendor_id}`);
    console.log(`   Name: ${bestMatch.vendor.name}`);
    console.log(`   Distance: ${bestMatch.distance}km`);
    console.log(`   Rating: ${bestMatch.rating}/5`);
    console.log(`   Completed: ${bestMatch.completedBookings} bookings`);
    console.log(`   FCM Tokens: ${bestMatch.vendor.fcmTokens.length}`);
    console.log('='.repeat(50));

    return bestMatch;

  } catch (error) {
    console.error('❌ Vendor matching error:', error.message);
    throw error;
  }
};

/**
 * Find all available vendors for a service (no distance limit)
 * @param {String} selectedService - Service requested
 * @returns {Array} Array of online vendors offering the service
 */
export const findAllAvailableVendors = async (selectedService) => {
  try {
    // Find online vendor presences
    const onlinePresences = await VendorPresence.find({ online: true });
    const onlineVendorIds = onlinePresences.map(p => p.vendorId);

    // Find vendors offering the service
    const vendors = await Vendor.find({
      vendor_id: { $in: onlineVendorIds },
      selectedServices: selectedService
    });

    return vendors;
  } catch (error) {
    console.error('❌ Error finding vendors:', error.message);
    throw error;
  }
};

/**
 * Check if a vendor is available (online and not busy)
 * @param {Number} vendorId - Vendor's ID
 * @returns {Boolean} True if vendor is available
 */
export const isVendorAvailable = async (vendorId) => {
  try {
    const presence = await VendorPresence.findOne({ vendorId });
    return presence && presence.online;
  } catch (error) {
    console.error('❌ Error checking vendor availability:', error.message);
    return false;
  }
};
