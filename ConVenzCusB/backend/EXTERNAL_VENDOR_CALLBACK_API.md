# External Vendor Callback API Documentation

## 🔄 Endpoint: Receive Vendor Updates

Your backend can now receive vendor assignment updates from external vendor servers.

### **Endpoint Details**

```
POST https://convenzcusb-backend.onrender.com/api/external/vendor-update
```

### **Authentication**

Required Header:
```
x-vendor-secret: vendor-secret-key-2024
```

⚠️ **IMPORTANT**: Add this to your Render environment variables:
```
VENDOR_SECRET=vendor-secret-key-2024
```
(Change to your own secure secret key)

---

### **Request Body**

```json
{
  "vendorId": "V12345",
  "vendorName": "John's Plumbing Services",
  "vendorPhone": "9876543210",
  "vendorAddress": "123 Main Street, Bangalore",
  "serviceType": "Plumbing",
  "assignedOrderId": "11",
  "status": "accepted"
}
```

### **Required Fields**

| Field | Type | Description |
|-------|------|-------------|
| `vendorId` | string | Unique vendor identifier |
| `vendorName` | string | Full name of vendor |
| `vendorPhone` | string | Vendor contact number |
| `vendorAddress` | string | Vendor location/address |
| `serviceType` | string | Service type (Plumbing, Cleaning, etc) |
| `assignedOrderId` | string | The booking ID they accepted |
| `status` | string | One of: accepted, rejected, enroute, completed, cancelled |

---

### **Status Values**

| Status | Description | Customer Notification |
|--------|-------------|----------------------|
| `accepted` | Vendor accepted the job | "✅ Vendor Assigned!" |
| `rejected` | Vendor declined the job | "❌ Vendor Declined" |
| `enroute` | Vendor is on the way | "🚗 Vendor On The Way" |
| `completed` | Service completed | "🎉 Service Completed" |
| `cancelled` | Service cancelled | "⚠️ Service Cancelled" |

---

### **Success Response**

```json
{
  "ok": true,
  "message": "Vendor update received",
  "data": {
    "bookingId": 11,
    "status": "accepted",
    "vendorName": "John's Plumbing Services",
    "updatedAt": "2025-12-04T10:30:00.000Z"
  }
}
```

### **Error Responses**

**401 Unauthorized** - Missing or invalid x-vendor-secret:
```json
{
  "ok": false,
  "error": "Unauthorized",
  "details": "Invalid or missing x-vendor-secret header"
}
```

**400 Bad Request** - Missing required fields:
```json
{
  "ok": false,
  "error": "Missing required fields",
  "details": "Required fields missing: vendorName, status"
}
```

**400 Bad Request** - Invalid status:
```json
{
  "ok": false,
  "error": "Invalid status",
  "details": "Status must be one of: accepted, rejected, enroute, completed, cancelled"
}
```

**404 Not Found** - Booking doesn't exist:
```json
{
  "ok": false,
  "error": "Booking not found",
  "details": "No booking found with ID: 999"
}
```

---

### **What Happens When Called**

1. ✅ Validates authentication (x-vendor-secret)
2. ✅ Validates all required fields
3. ✅ Finds the booking by assignedOrderId
4. ✅ Updates booking with external vendor details
5. ✅ Changes booking status
6. ✅ Sends push notification to customer
7. ✅ Returns success response

---

### **Example: cURL Request**

```bash
curl -X POST https://convenzcusb-backend.onrender.com/api/external/vendor-update \
  -H "Content-Type: application/json" \
  -H "x-vendor-secret: vendor-secret-key-2024" \
  -d '{
    "vendorId": "V12345",
    "vendorName": "Johns Plumbing",
    "vendorPhone": "9876543210",
    "vendorAddress": "123 Main St",
    "serviceType": "Plumbing",
    "assignedOrderId": "11",
    "status": "accepted"
  }'
```

---

### **Example: JavaScript/Node.js**

```javascript
const response = await fetch(
  'https://convenzcusb-backend.onrender.com/api/external/vendor-update',
  {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-vendor-secret': 'vendor-secret-key-2024'
    },
    body: JSON.stringify({
      vendorId: 'V12345',
      vendorName: 'Johns Plumbing',
      vendorPhone: '9876543210',
      vendorAddress: '123 Main St',
      serviceType: 'Plumbing',
      assignedOrderId: '11',
      status: 'accepted'
    })
  }
);

const data = await response.json();
console.log(data);
```

---

### **Database Changes**

Booking document will be updated with:
```json
{
  "status": "accepted",
  "externalVendor": {
    "vendorId": "V12345",
    "vendorName": "Johns Plumbing",
    "vendorPhone": "9876543210",
    "vendorAddress": "123 Main St",
    "serviceType": "Plumbing",
    "assignedAt": "2025-12-04T10:30:00.000Z",
    "lastUpdated": "2025-12-04T10:30:00.000Z"
  }
}
```

---

### **Security Notes**

1. **Always use HTTPS** in production
2. **Change VENDOR_SECRET** to a strong, unique value
3. **Rotate the secret** periodically
4. **Log all incoming requests** for audit trail
5. **Rate limit** the endpoint if needed

---

### **Testing**

Test the endpoint using Postman or cURL with the example requests above.

**Check Render logs** to see:
- Incoming vendor updates
- Booking status changes
- Customer notifications sent
- Any errors or validation issues

---

## ✅ Integration Complete!

External vendor servers can now:
1. Receive customer orders from your backend ✅
2. Send vendor assignment updates back to your backend ✅

**Bidirectional communication established!** 🎉
