import Link from "next/link";
import { ArrowRight, Building2, CalendarDays, Users } from "lucide-react";
import { formatDate, formatMoney } from "@/lib/marketplace/format";
import type { MarketplaceBounty } from "@/lib/marketplace/types";

export function BountyCard({ bounty }: { bounty: MarketplaceBounty }) {
  const slots = bounty.meeting_limit - bounty.accepted_count;
  return (
    <article className="flex h-full flex-col rounded-2xl border bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md">
      <div className="flex items-start justify-between gap-4"><div><p className="flex items-center gap-1.5 text-sm text-slate-500"><Building2 size={15} />{bounty.brand_name}</p><h2 className="mt-2 text-lg font-semibold leading-snug">{bounty.title}</h2></div><p className="whitespace-nowrap text-xl font-bold tracking-tight text-emerald-700">{formatMoney(bounty.reward_amount)}</p></div>
      <p className="mt-3 line-clamp-3 text-sm leading-6 text-slate-600">{bounty.summary}</p>
      <div className="mt-5 flex flex-wrap gap-2">{bounty.geography.slice(0, 3).map((item) => <Tag key={item}>{item}</Tag>)}{bounty.industries.slice(0, 2).map((item) => <Tag key={item}>{item}</Tag>)}</div>
      <dl className="mt-5 grid gap-2 border-t pt-4 text-sm text-slate-600"><div className="flex items-center gap-2"><Users size={15} /><span>{bounty.allowed_roles.join(", ")}</span></div><div className="flex items-center gap-2"><CalendarDays size={15} /><span>{slots} слотов · до {formatDate(bounty.active_until)}</span></div></dl>
      <Link href={`/bounties/${bounty.slug}`} className="mt-5 flex items-center gap-2 text-sm font-semibold text-slate-900">Открыть bounty <ArrowRight size={15} /></Link>
    </article>
  );
}

export function Tag({ children }: { children: React.ReactNode }) { return <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs text-slate-600">{children}</span>; }
