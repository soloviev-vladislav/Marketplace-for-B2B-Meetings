import { describe, expect, it } from "vitest";
import { canStartNewWork, getBountyDisplayStatus } from "./status";

const now = new Date("2026-08-11T12:00:00.000Z");

describe("bounty derived status", () => {
  it("derives EXPIRED only for ACTIVE bounties whose deadline has passed", () => {
    expect(getBountyDisplayStatus("ACTIVE", "2026-08-11T11:59:59.000Z", now)).toBe("EXPIRED");
    expect(getBountyDisplayStatus("ACTIVE", "2026-08-11T12:00:00.000Z", now)).toBe("EXPIRED");
    expect(getBountyDisplayStatus("ACTIVE", "2026-08-11T12:00:01.000Z", now)).toBe("ACTIVE");
    expect(getBountyDisplayStatus("PAUSED", "2026-08-10T00:00:00.000Z", now)).toBe("PAUSED");
  });

  it("allows new work only while the bounty is effectively active", () => {
    expect(canStartNewWork("ACTIVE", "2026-08-12T00:00:00.000Z", now)).toBe(true);
    expect(canStartNewWork("ACTIVE", "2026-08-11T12:00:00.000Z", now)).toBe(false);
    expect(canStartNewWork("PAUSED", "2026-08-12T00:00:00.000Z", now)).toBe(false);
  });
});
