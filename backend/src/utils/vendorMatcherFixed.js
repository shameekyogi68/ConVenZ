import mongoose from "mongoose";
import { calculateDistance } from "./distanceCalculator.js";

/**
 * Find the best vendor for a booking (Works with existing vendor schema)
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

    // Get collections directly
    const vendorsCollection = mongoose.connection.db.collection('vendors');
    const presencesCollection = mongoose.connection.db.collection('vendorpresences');

    // Step 1: Find online vendor presences
    const onlinePresences = await presencesCollection.find({ online: true }).toArray();
    console.log(`🟢 Found ${onlinePresences.length} online vendors`);

    if (onlinePresences.length === 0) {
      console.log('❌ No online vendors available');
      return null;
    }

    // Step 2: Get vendor IDs from online presences
    const onlineVendorIds = onlinePresences.map(p => p.vendorId);

    // Step 3: Find vendors that offer the requested service and are online
    const matchingVendors = await vendorsCollection.find({
      $or: [
        { vendorId: { $in: onlineVendorIds } },
        { _id: { $in: onlineVendorIds.map(id => {
          try {
            return new mongoose.Types.ObjectId(id);
          } catch (e) {
            return id;
          }
        }) } }
      ],
      selectedServices: selectedService
    }).toArray();

    console.log(`🎯 Found ${matchingVendors.length} vendors offering ${selectedService}`);

    if (matchingVendors.length === 0) {
      console.log('❌ No vendors found for this service');
      return null;
    }

    // Step 4: Calculate distances and filter by maxDistance
    const vendorsWithDistance = [];

    for (const vendor of matchingVendors) {
      const vendorId = vendor.vendorId || vendor._id.toString();
      
      // Get vendor's current location from presence
      const presence = onlinePresences.find(p => p.vendorId === vendorId);
      
      if (!presence || !presence.currentLocation || !presence.currentLocation.coordinates) {
        console.log(`⚠️  Vendor ${vendorId} has no location data, skipping`);
        continue;
      }

      const [vendorLon, vendorLat] = presence.currentLocation.coordinates;
      
      const distance = calculateDistance(latitude, longitude, vendorLat, vendorLon);
      
      console.log(`📍 Vendor ${vendor.vendorName || vendor.mobile}: ${distance}km away`);

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
    const vendorId = bestMatch.vendor.vendorId || bestMatch.vendor._id.toString();
    
    console.log(`\n🏆 BEST MATCH FOUND:`);
    console.log(`   Vendor ID: ${vendorId}`);
    console.log(`   Name: ${bestMatch.vendor.vendorName || bestMatch.vendor.mobile}`);
    console.log(`   Distance: ${bestMatch.distance}km`);
    console.log(`   Rating: ${bestMatch.rating}/5`);
    console.log(`   Completed: ${bestMatch.completedBookings} bookings`);
    console.log(`   FCM Tokens: ${bestMatch.vendor.fcmTokens?.length || 0}`);
    console.log('='.repeat(50));

    // Return in expected format
    return {
      vendor: {
        vendor_id: vendorId,
        vendorId: vendorId,
        name: bestMatch.vendor.vendorName || bestMatch.vendor.businessName,
        phone: bestMatch.vendor.mobile,
        fcmTokens: bestMatch.vendor.fcmTokens || [],
        rating: bestMatch.rating,
        completedBookings: bestMatch.completedBookings
      },
      distance: bestMatch.distance,
      presence: bestMatch.presence
    };

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
    const vendorsCollection = mongoose.connection.db.collection('vendors');
    const presencesCollection = mongoose.connection.db.collection('vendorpresences');
    
    // Find online vendor presences
    const onlinePresences = await presencesCollection.find({ online: true }).toArray();
    const onlineVendorIds = onlinePresences.map(p => p.vendorId);

    // Find vendors offering the service
    const vendors = await vendorsCollection.find({
      $or: [
        { vendorId: { $in: onlineVendorIds } },
        { _id: { $in: onlineVendorIds.map(id => {
          try {
            return new mongoose.Types.ObjectId(id);
          } catch (e) {
            return id;
          }
        }) } }
      ],
      selectedServices: selectedService
    }).toArray();

    return vendors;
  } catch (error) {
    console.error('❌ Error finding vendors:', error.message);
    throw error;
  }
};

/**
 * Check if a vendor is available (online and not busy)
 * @param {String} vendorId - Vendor's ID
 * @returns {Boolean} True if vendor is available
 */
export const isVendorAvailable = async (vendorId) => {
  try {
    const presencesCollection = mongoose.connection.db.collection('vendorpresences');
    const presence = await presencesCollection.findOne({ vendorId });
    return presence && presence.online;
  } catch (error) {
    console.error('❌ Error checking vendor availability:', error.message);
    return false;
  }
};
