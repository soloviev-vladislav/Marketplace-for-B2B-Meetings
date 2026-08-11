export function serializeActiveUntil(dateValue: string, originalTimestamp?: string) {
  if (originalTimestamp && originalTimestamp.slice(0, 10) === dateValue) {
    return originalTimestamp;
  }
  return new Date(`${dateValue}T23:59:59.000Z`).toISOString();
}
