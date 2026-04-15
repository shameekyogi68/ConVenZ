# 🔌 ConVenZ External Vendor Integration Guide

Welcome to the ConVenZ integration protocol. This document outlines how external vendor systems communicate with the **ConVenZ Customer Backend**. 

Follow this guide to ensure seamless synchronization of service requests and real-time status updates.

---

## 🏗️ 1. Architecture Overview

The integration follows a bidirectional communication model:

1.  **Outbound:** ConVenZ sends a `New Job` request to your server when a customer places an order.
2.  **Inbound (Callbacks):** Your server sends a `Status Update` back to ConVenZ as the vendor progresses with the job.

---

## 📡 2. Outbound: New Job Request
**Request from ConVenZ → Your Server**

When a booking is created, ConVenZ sends a `POST` request to your configured endpoint.

-   **Method:** `POST`
-   **Endpoint:** (Configured in your integration settings)
-   **Payload Structure:**

```json
{
  "bookingId": 10045,            // Unique ConVenZ Booking ID
  "customerId": 42,               // ConVenZ User ID
  "customerName": "John Doe",
  "customerPhone": "9999888877",
  "service": "Plumbing",         // Requested Service Category
  "description": "Leaky tap",     // Customer's job description
  "location": {
    "latitude": 12.9716,
    "longitude": 77.5946,
    "address": "123 Main St, Bangalore"
  }
}
```

---

## 🔄 3. Inbound: Vendor Status Callback
**Request from Your Server → ConVenZ**

Use this endpoint to update ConVenZ when a vendor is assigned or when the job status changes.

-   **Endpoint:** `https://convenz.onrender.com/api/v1/external/vendor-update`
-   **Method:** `POST`
-   **Authentication Header:** 
    -   Key: `x-vendor-secret`
    -   Value: `YOUR_SECRET_KEY` (Provided by ConVenZ)

### 📥 Payload Structure

| Field | Type | Description |
| :--- | :--- | :--- |
| `assignedOrderId` | `int` | **Required.** The `bookingId` received in the initial request. |
| `status` | `string` | **Required.** The new status (see allowed list below). |
| `vendorName` | `string` | **Required.** Name of the assigned vendor. |
| `vendorId` | `string` | ID of the vendor in your system. |
| `vendorPhone` | `string` | Contact number of the vendor. |
| `vendorAddress`| `string` | Current location/base of the vendor. |
| `serviceType` | `string` | The specific sub-service being performed. |

### 🚦 Allowed Statuses & Flow
ConVenZ enforces a strict state machine. Updates that violate this flow will return a `400 Bad Request`.

1.  **`accepted`**: A vendor has been found and confirmed.
2.  **`enroute`**: The vendor is traveling to the customer's location.
3.  **`completed`**: The job is finished successfully.
4.  **`rejected`**: No vendors are available (closes the order).
5.  **`cancelled`**: The job was aborted by the vendor system.

---

## 🔐 4. Security Requirements

1.  **Secret Header:** All callbacks to ConVenZ **must** include the `x-vendor-secret` header. Requests without it or with incorrect keys will be rejected with a `401 Unauthorized`.
2.  **HTTPS:** All communication must occur over TLS 1.2 or higher.
3.  **Timeout:** Your server should respond to the initial `New Job` request within **10 seconds**.

---

## 🛠️ 5. Example Callback Implementation (Node.js)

```javascript
const axios = require('axios');

async function updateConvenzStatus(bookingId, status, vendorDetails) {
  try {
    const response = await axios.post('https://convenz.onrender.com/api/v1/external/vendor-update', {
      assignedOrderId: bookingId,
      status: status, // e.g., "accepted"
      vendorName: vendorDetails.name,
      vendorPhone: vendorDetails.phone,
      vendorId: vendorDetails.id
    }, {
      headers: {
        'x-vendor-secret': 'YOUR_CONVENZ_SECRET_KEY'
      }
    });

    console.log('✅ Update successful:', response.data);
  } catch (error) {
    console.error('❌ Update failed:', error.response.data);
  }
}
```

---

## ❓ 6. Error Reference

| Code | Meaning | Action |
| :--- | :--- | :--- |
| `200` | OK | Update successful. |
| `401` | Unauthorized | Check your `x-vendor-secret` header. |
| `404` | Not Found | `assignedOrderId` does not match any active booking. |
| `400` | Bad Request | Invalid status transition or missing fields. |
| `500`| Server Error | Internal ConVenZ error. Retry after 5 mins. |
