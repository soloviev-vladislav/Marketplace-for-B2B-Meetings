import { describe, expect, it } from "vitest";
import { normalizeCompanyDomain, normalizeCompanyInn } from "./normalize";

describe("normalizeCompanyDomain", () => {
  it.each([
    ["example.com", "example.com"],
    ["www.example.com", "example.com"],
    ["https://example.com", "example.com"],
    ["https://www.example.com/about", "example.com"],
    [" HTTP://WWW.Example.COM:80/path?q=1 ", "example.com"],
    ["https://example.com:443/path#part", "example.com"],
    ["example.com.", "example.com"],
  ])("canonicalizes %s", (input, expected) => {
    expect(normalizeCompanyDomain(input)).toBe(expected);
  });

  it.each([
    "", "   ", "not a valid domain", "bad..example.com", "user@example.com",
    "ftp://example.com", "example.com:8080", "-bad.example.com", "bad-.example.com",
    "localhost", "пример.рф", "example.c",
  ])("rejects malformed or unsupported domain %s", (input) => {
    expect(normalizeCompanyDomain(input)).toBeNull();
  });
});

describe("normalizeCompanyInn", () => {
  it.each([
    ["7707083893", "7707083893"],
    [" 77-070 838-93 ", "7707083893"],
    ["500100732259", "500100732259"],
    [" 5001-0073 2259 ", "500100732259"],
  ])("accepts and canonicalizes valid INN %s", (input, expected) => {
    expect(normalizeCompanyInn(input)).toBe(expected);
  });

  it.each([
    "", "-", "ABC", "77AB-12", "1", "0000000000", "000000000000",
    "7712345678", "500100732258",
    "1234567890123456789012345678901234567890", "7707.083893",
  ])("rejects invalid INN %s", (input) => {
    expect(normalizeCompanyInn(input)).toBeNull();
  });
});
