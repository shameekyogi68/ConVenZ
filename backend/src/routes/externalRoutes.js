import express from "express";
import { receiveVendorUpdate } from "../controllers/externalVendorController.js";

const router = express.Router();

/* ------------------------------------------
   🔄 EXTERNAL VENDOR CALLBACK ROUTES
   
   Receives updates from external vendor servers
------------------------------------------- */

// Vendor assignment update callback
router.post("/vendor-update", receiveVendorUpdate);

export default router;
