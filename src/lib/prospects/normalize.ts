const INN_10_WEIGHTS = [2, 4, 10, 3, 5, 9, 4, 6, 8] as const;
const INN_12_FIRST_WEIGHTS = [7, 2, 4, 10, 3, 5, 9, 4, 6, 8] as const;
const INN_12_SECOND_WEIGHTS = [3, 7, 2, 4, 10, 3, 5, 9, 4, 6, 8] as const;

function checksumDigit(digits: number[], weights: readonly number[]) {
  return weights.reduce((sum, weight, index) => sum + weight * digits[index], 0) % 11 % 10;
}

export function normalizeCompanyInn(value: string) {
  const normalized = value.trim().replace(/[\s-]/g, "");
  if (!/^\d{10}(?:\d{2})?$/.test(normalized)) return null;
  if (/^0+$/.test(normalized)) return null;

  const digits = Array.from(normalized, Number);
  if (digits.length === 10) {
    return checksumDigit(digits, INN_10_WEIGHTS) === digits[9] ? normalized : null;
  }

  const firstValid = checksumDigit(digits, INN_12_FIRST_WEIGHTS) === digits[10];
  const secondValid = checksumDigit(digits, INN_12_SECOND_WEIGHTS) === digits[11];
  return firstValid && secondValid ? normalized : null;
}

export function normalizeCompanyDomain(value: string) {
  let normalized = value.trim().toLowerCase();
  if (!normalized) return null;

  if (normalized.includes("://")) {
    if (!/^https?:\/\//.test(normalized)) return null;
    normalized = normalized.replace(/^https?:\/\//, "");
  }

  normalized = normalized.split(/[/?#]/, 1)[0] ?? "";
  if (/[^\x00-\x7f]/.test(normalized) || normalized.includes("@")) return null;
  normalized = normalized.replace(/^www\./, "").replace(/\.$/, "");
  normalized = normalized.replace(/:(80|443)$/, "");

  if (!normalized || normalized.length > 253 || normalized.includes(":")) return null;
  const labels = normalized.split(".");
  if (labels.length < 2) return null;
  if (labels.some((label) => !/^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$/.test(label))) return null;
  if (!/^[a-z]{2,63}$/.test(labels.at(-1) ?? "")) return null;
  return normalized;
}
