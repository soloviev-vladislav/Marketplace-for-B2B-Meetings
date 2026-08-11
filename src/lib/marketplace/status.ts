import type { BountyStatus } from "@/lib/marketplace/types";

export type BountyDisplayStatus = BountyStatus | "EXPIRED";

export function getBountyDisplayStatus(
  status: BountyStatus,
  activeUntil: string,
  now = new Date(),
): BountyDisplayStatus {
  return status === "ACTIVE" && new Date(activeUntil).getTime() <= now.getTime()
    ? "EXPIRED"
    : status;
}

export function canStartNewWork(
  status: BountyStatus,
  activeUntil: string,
  now = new Date(),
) {
  return getBountyDisplayStatus(status, activeUntil, now) === "ACTIVE";
}
