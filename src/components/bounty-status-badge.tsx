import type { BountyDisplayStatus } from "@/lib/marketplace/status";
import { cn } from "@/lib/utils";

const labels: Record<BountyDisplayStatus, string> = {
  ACTIVE: "Активен",
  PAUSED: "На паузе",
  COMPLETED: "Завершён",
  ARCHIVED: "Архив",
  DRAFT: "Черновик",
  MODERATION: "На модерации",
  REJECTED: "Отклонён",
  EXPIRED: "Срок истёк",
};

const styles: Record<BountyDisplayStatus, string> = {
  ACTIVE: "bg-emerald-50 text-emerald-700",
  PAUSED: "bg-amber-50 text-amber-800",
  COMPLETED: "bg-blue-50 text-blue-700",
  ARCHIVED: "bg-slate-100 text-slate-600",
  DRAFT: "bg-slate-100 text-slate-600",
  MODERATION: "bg-violet-50 text-violet-700",
  REJECTED: "bg-red-50 text-red-700",
  EXPIRED: "bg-orange-50 text-orange-800",
};

export function BountyStatusBadge({ status }: { status: BountyDisplayStatus }) {
  return (
    <span
      className={cn(
        "inline-flex rounded-full px-2.5 py-1 text-xs font-semibold",
        styles[status],
      )}
    >
      {labels[status]}
    </span>
  );
}
