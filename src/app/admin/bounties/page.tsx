import Link from "next/link";
import { AppShell } from "@/components/app-shell";
import { Button } from "@/components/ui/button";
import { PageHeading } from "@/components/page-heading";
import { formatDate, formatMoney } from "@/lib/marketplace/format";
import { requireRole } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";

type AdminBountyRow = { id: string; title: string; status: string; reward_amount: number; active_until: string; current_version: number; businesses: { brand_name: string } | null };

export default async function AdminBountiesPage() {
  const profile = await requireRole("ADMIN");
  const supabase = await createClient();
  const { data } = await supabase.from("bounties").select("id,title,status,reward_amount,active_until,current_version,businesses(brand_name)").order("created_at", { ascending: false });
  const bounties = (data ?? []) as unknown as AdminBountyRow[];
  return <AppShell profile={profile}><div className="mx-auto max-w-6xl px-5 py-10"><PageHeading eyebrow="Admin" title="Bounties" description="Draft, публикация и пауза bounty." actions={<Button asChild><Link href="/admin/bounties/new">Создать bounty</Link></Button>} />
    <div className="overflow-hidden rounded-2xl border bg-white shadow-sm">{bounties.length ? bounties.map((bounty) => <Link key={bounty.id} href={`/admin/bounties/${bounty.id}`} className="grid gap-3 border-b p-5 last:border-0 hover:bg-slate-50 sm:grid-cols-[1fr_auto_auto]"><div><p className="font-medium">{bounty.title}</p><p className="text-sm text-slate-500">{bounty.businesses?.brand_name} · версия {bounty.current_version}</p></div><div className="text-sm text-slate-600">{formatMoney(bounty.reward_amount)}<br />до {formatDate(bounty.active_until)}</div><span className="h-fit rounded-full bg-slate-100 px-3 py-1 text-xs font-medium">{bounty.status}</span></Link>) : <p className="p-10 text-center text-sm text-slate-500">Bounty пока нет.</p>}</div>
  </div></AppShell>;
}
