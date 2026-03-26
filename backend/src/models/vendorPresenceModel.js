import mongoose from "mongoose";

/* ------------------------------------------
   🟢 VENDOR PRESENCE SCHEMA
   Tracks vendor online/offline status
------------------------------------------- */
const vendorPresenceSchema = new mongoose.Schema(
  {
    vendorId: {
      type: Number,
      required: true,
      ref: "Vendor",
      unique: true,
    },
    
    online: {
      type: Boolean,
      default: false,
    },

    lastSeen: {
      type: Date,
      default: Date.now,
    },

    // Current location (can be different from vendor's registered location)
    currentLocation: {
      type: { type: String, default: "Point" },
      coordinates: { type: [Number], default: [0, 0] }, // [longitude, latitude]
    },

    currentAddress: {
      type: String,
      default: "",
    },
  },
  { timestamps: true }
);

// Enable geospatial queries
vendorPresenceSchema.index({ currentLocation: "2dsphere" });

const VendorPresence = mongoose.model("VendorPresence", vendorPresenceSchema);
export default VendorPresence;
