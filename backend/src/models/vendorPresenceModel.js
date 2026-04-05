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
      type: { type: String, enum: ["Point"], default: "Point" },
      // [longitude (-180–180), latitude (-90–90)]
      coordinates: { type: [Number], default: [0, 0] },
    },

    currentAddress: {
      type: String,
      trim: true,
      default: "",
    },
  },
  { timestamps: true }
);

vendorPresenceSchema.index({ online: 1 });              // Hot path: scheduler + vendor matcher filter by online=true
vendorPresenceSchema.index({ currentLocation: "2dsphere" }); // Geospatial queries

const VendorPresence = mongoose.model("VendorPresence", vendorPresenceSchema);
export default VendorPresence;
