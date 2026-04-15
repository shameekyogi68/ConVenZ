# ConVenZ Vendor Integration Guide (Customer ↔ Vendor)

This document defines the **contract** between:

- **Customer Backend (you)**: ConVenZ Customer backend
- **Vendor Backend (them)**: Vendor partner backend (assigns vendors + updates status)

Goal: **fast, reliable, zero-ambiguity integration** for production.

---

## 1) Environments

### Customer Backend (Production)
- **Base URL**: `https://convenz.onrender.com/api/v1`

### Vendor Backend (Production)
- **Base URL**: _(vendor must provide)_ e.g. `https://vendor.example.com/vendor-api/v1`

---

## 2) Authentication & Security (Recommended)

### 2.1 Server-to-Server secret (required)
Use a shared secret for all server-to-server calls (webhooks).

- Customer backend stores: `VENDOR_SERVER_SECRET`
- Vendor backend stores: `CUSTOMER_SERVER_SECRET`

**Headers**
- Customer → Vendor: `x-customer-server-secret: <CUSTOMER_SERVER_SECRET>`
- Vendor → Customer: `x-server-secret: <SERVER_SECRET>`

> Never share JWT secrets, MongoDB URI, Firebase service account JSON, or admin secrets with the vendor team.

### 2.2 App request signing (FYI)
Mobile apps calling the Customer backend include:
- `X-Timestamp` (epoch millis)
- `X-Signature` (HMAC-SHA256 of `METHOD|PATH|TIMESTAMP|BODY_JSON`)

Vendor backend does **not** need app signing. Vendor backend uses server-to-server secret headers instead.

---

## 3) Data model (Shared identifiers)

### 3.1 Booking ID
All cross-system updates must include:
- `bookingId` (string or number; treat as opaque identifier)

### 3.2 Vendor ID
Vendor backend is the source-of-truth for:
- `vendorId`

Customer backend stores vendor ID to relate subsequent status updates.

---

## 4) Status lifecycle (Source of truth)

Vendor backend must treat the following as canonical booking statuses:

- `accepted`
- `rejected`
- `enroute`
- `completed`
- `cancelled`

Rules:
- `accepted` or `rejected` must be sent quickly (SLA target < 5s after vendor decision).
- `enroute` should be sent when vendor starts traveling.
- `completed` when job is complete.
- `cancelled` if vendor/customer cancels.

---

## 5) Webhooks / API Endpoints

### 5.1 Vendor → Customer: status update (REQUIRED)
Vendor backend calls the Customer backend whenever a booking status changes.

**Endpoint (Customer backend)**
- `POST /api/v1/user/booking/status-update`

**Headers**
- `Content-Type: application/json`
- `x-server-secret: <SERVER_SECRET>`
- `x-idempotency-key: <uuid>` (recommended; see section 7)

**Body**
```json
{
  "bookingId": "123",
  "status": "accepted",
  "vendorId": "V001",
  "otpStart": 1234,
  "rejectionReason": "Optional reason for rejection"
}
```

Notes:
- `otpStart` is optional. Use if you want OTP-based job start verification.
- `rejectionReason` required only when `status="rejected"` (recommended).

**Success response**
```json
{
  "success": true,
  "message": "Status updated"
}
```

**Error responses**
- `401`: bad/missing `x-server-secret`
- `400`: validation errors
- `500`: server error (should be retried by vendor backend)

---

### 5.2 Customer → Vendor: create/dispatch a job (RECOMMENDED)
When a customer creates a booking, the Customer backend notifies Vendor backend for assignment.

**Endpoint (Vendor backend)**
- `POST /jobs/create`  _(vendor must implement)_

**Headers**
- `Content-Type: application/json`
- `x-customer-server-secret: <CUSTOMER_SERVER_SECRET>`
- `x-idempotency-key: <uuid>` (recommended)

**Body (minimum recommended)**
```json
{
  "bookingId": "123",
  "serviceType": "Cleaning",
  "jobDescription": "Deep cleaning 2BHK",
  "scheduledAt": "2026-04-15T10:30:00Z",
  "location": {
    "lat": 19.076,
    "lng": 72.8777,
    "address": "Kurla West, Mumbai - 400070, Maharashtra, India"
  },
  "customer": {
    "userId": "9",
    "name": "Optional",
    "phoneMasked": "+91 12****7890"
  }
}
```

**Success response (vendor → customer)**
```json
{
  "success": true,
  "vendorId": "V001",
  "etaMins": 25
}
```

**Failure response**
```json
{
  "success": false,
  "message": "No vendors available right now"
}
```

---

## 6) Performance requirements (Fast request/response)

To avoid user-facing delays:

### Timeouts
- Customer → Vendor webhook timeout: **3–5 seconds**
- Vendor → Customer status update timeout: **3–5 seconds**

### Retries (on network/5xx)
- Retry up to **3 times**
- Backoff: **0.5s, 1.5s, 3s**
- Do **not** retry on `401/403` (auth issue) or `400/422` (bad payload).

### Response payload size
- Keep JSON bodies small (< 10KB).
- Do not embed images or large arrays.

---

## 7) Idempotency (Prevents duplicate updates)

Both systems should support **idempotency keys**:

- Client sends: `x-idempotency-key: <uuid>`
- Server stores the key + response for a short TTL (e.g., 5 minutes)
- If same key is received again, return the same response without re-processing.

This is critical because retries are expected in production.

---

## 8) Observability (Logs that make debugging easy)

### Customer backend
- Returns `x-request-id` on every response.
- Logs request events with that id (Render logs).

### Vendor backend (must implement)
Vendor should log for every webhook call:
- timestamp
- bookingId
- status
- HTTP status code returned
- latency ms
- idempotency key
- request-id (if returned)

---

## 9) Required items vendor must deliver

1) **Vendor backend base URL**
2) `CUSTOMER_SERVER_SECRET` value (shared securely once)
3) Implement vendor endpoint:
   - `POST /jobs/create`
4) Implement outbound webhook to customer:
   - `POST https://convenz.onrender.com/api/v1/user/booking/status-update`
5) Provide a test vendorId + test flow

---

## 10) What the Customer system will send to vendor (summary)

- bookingId
- serviceType
- jobDescription
- scheduledAt
- customer location (lat/lng/address)
- masked customer identifier info (no sensitive secrets)

---

## 11) What vendor will send to Customer (summary)

- bookingId
- status transitions (accepted/rejected/enroute/completed/cancelled)
- vendorId (once assigned)
- otpStart (optional)
- rejectionReason (optional)

---

## 12) Quick test commands (for vendor devs)

### Status update (vendor → customer) example
```bash
curl -X POST "https://convenz.onrender.com/api/v1/user/booking/status-update" \
  -H "Content-Type: application/json" \
  -H "x-server-secret: <SERVER_SECRET>" \
  -H "x-idempotency-key: 2d0f3cda-4ee7-4f0a-9b34-4c6c3c3f0b50" \
  -d '{"bookingId":"123","status":"accepted","vendorId":"V001"}'
```

---

## 13) Change control

Any changes to:
- status values
- required fields
- auth headers
- endpoint paths

Must be communicated and versioned to prevent production breaks.

