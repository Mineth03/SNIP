import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  assertBookingTransition,
  isValidBookingTransition,
} from "../lib/booking/status";

describe("booking status transitions", () => {
  it("allows confirmed → checked_in", () => {
    assert.equal(isValidBookingTransition("confirmed", "checked_in"), true);
  });

  it("blocks completed → confirmed", () => {
    assert.equal(isValidBookingTransition("completed", "confirmed"), false);
  });

  it("allows same-status no-op", () => {
    assert.equal(isValidBookingTransition("in_progress", "in_progress"), true);
  });

  it("throws on invalid assert", () => {
    assert.throws(() => assertBookingTransition("cancelled", "confirmed"));
  });

  it("allows happy-path check-in workflow", () => {
    const path = [
      ["confirmed", "checked_in"],
      ["checked_in", "in_progress"],
      ["in_progress", "completed"],
    ] as const;
    for (const [from, to] of path) {
      assert.equal(isValidBookingTransition(from, to), true);
    }
  });
});
