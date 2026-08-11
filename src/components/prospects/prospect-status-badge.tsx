import type { ProspectStatus } from "@/lib/prospects/types";
import { cn } from "@/lib/utils";

const labels: Record<ProspectStatus, string> = { PENDING: "На проверке", APPROVED: "Одобрен", REJECTED: "Отклонён", EXPIRED: "Истёк" };
const styles: Record<ProspectStatus, string> = { PENDING: "bg-amber-50 text-amber-800", APPROVED: "bg-emerald-50 text-emerald-700", REJECTED: "bg-red-50 text-red-700", EXPIRED: "bg-slate-100 text-slate-700" };

export function ProspectStatusBadge({ status }: { status: ProspectStatus }) {
  return <span className={cn("inline-flex rounded-full px-2.5 py-1 text-xs font-semibold", styles[status])}>{labels[status]}</span>;
}
