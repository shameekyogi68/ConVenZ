import { calculateExpiry } from "../src/controllers/subscriptionController.js";

describe("Subscription Expiry Calculation Tests", () => {
  let originalDate;

  beforeAll(() => {
    // Mock the global Date object to test time-specific bugs (e.g. leap years, end of month)
    originalDate = global.Date;
  });

  afterAll(() => {
    global.Date = originalDate;
  });

  const mockDate = (isoString) => {
    const FakeDate = class extends Date {
      constructor(...args) {
        if (args.length === 0) {
          super(isoString);
        } else {
          super(...args);
        }
      }
    };
    global.Date = FakeDate;
  };

  test("January 31st + 1 Month = Last day of February", () => {
    mockDate("2026-01-31T10:00:00.000Z"); // Non-leap year
    const expiry = calculateExpiry("1 month");
    expect(expiry.toISOString().startsWith("2026-02-28")).toBeTruthy();
    expect(expiry.getMonth()).toBe(1); // 1 = February
  });

  test("Leap Year: January 31st + 1 Month = February 29th", () => {
    mockDate("2024-01-31T10:00:00.000Z"); // Leap year
    const expiry = calculateExpiry("1 month");
    expect(expiry.toISOString().startsWith("2024-02-29")).toBeTruthy();
    expect(expiry.getMonth()).toBe(1);
  });

  test("March 31st + 1 Month = April 30th", () => {
    mockDate("2026-03-31T10:00:00.000Z");
    const expiry = calculateExpiry("1 month");
    expect(expiry.toISOString().startsWith("2026-04-30")).toBeTruthy();
  });

  test("February 29th + 1 Year = February 28th (next year)", () => {
    mockDate("2024-02-29T10:00:00.000Z");
    const expiry = calculateExpiry("1 year");
    expect(expiry.toISOString().startsWith("2025-02-28")).toBeTruthy();
  });

  test("Standard 7 days offset", () => {
    mockDate("2024-01-01T10:00:00.000Z");
    const expiry = calculateExpiry("7 days");
    expect(expiry.toISOString().startsWith("2024-01-08")).toBeTruthy();
  });
});
