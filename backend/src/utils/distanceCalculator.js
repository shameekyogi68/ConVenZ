/**
 * Calculate distance between two geographic coordinates using Haversine formula
 * @param {Number} lat1 - Latitude of first point
 * @param {Number} lon1 - Longitude of first point
 * @param {Number} lat2 - Latitude of second point
 * @param {Number} lon2 - Longitude of second point
 * @returns {Number} Distance in kilometers (rounded to 2 decimals)
 */
export const calculateDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371; // Earth's radius in kilometers
  
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c;
  
  return Math.round(distance * 100) / 100; // Round to 2 decimals
};

/**
 * Convert degrees to radians
 */
const toRad = (degrees) => {
  return degrees * (Math.PI / 180);
};

/**
 * Find nearest location from an array of locations
 * @param {Number} userLat - User's latitude
 * @param {Number} userLon - User's longitude
 * @param {Array} locations - Array of objects with latitude and longitude
 * @returns {Object} Nearest location with distance property added
 */
export const findNearest = (userLat, userLon, locations) => {
  if (!locations || locations.length === 0) return null;
  
  let nearest = null;
  let minDistance = Infinity;
  
  locations.forEach(location => {
    const distance = calculateDistance(
      userLat, 
      userLon, 
      location.latitude, 
      location.longitude
    );
    
    if (distance < minDistance) {
      minDistance = distance;
      nearest = { ...location, distance };
    }
  });
  
  return nearest;
};

/**
 * Sort locations by distance from a point
 * @param {Number} userLat - User's latitude
 * @param {Number} userLon - User's longitude
 * @param {Array} locations - Array of objects with latitude and longitude
 * @returns {Array} Sorted array with distance property added to each location
 */
export const sortByDistance = (userLat, userLon, locations) => {
  if (!locations || locations.length === 0) return [];
  
  return locations
    .map(location => ({
      ...location,
      distance: calculateDistance(
        userLat, 
        userLon, 
        location.latitude, 
        location.longitude
      )
    }))
    .sort((a, b) => a.distance - b.distance);
};
