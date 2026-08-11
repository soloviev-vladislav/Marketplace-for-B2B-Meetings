import { describe, expect, it } from "vitest";
import { serializeActiveUntil } from "./bounty-payload";

describe("serializeActiveUntil", () => {
  it("preserves the exact stored timestamp when the admin did not change its date", () => {
    expect(serializeActiveUntil("2026-09-10", "2026-09-10T17:42:13.123Z"))
      .toBe("2026-09-10T17:42:13.123Z");
  });

  it("serializes an intentionally changed date deterministically", () => {
    expect(serializeActiveUntil("2026-09-11", "2026-09-10T17:42:13.123Z"))
      .toBe("2026-09-11T23:59:59.000Z");
  });
});
