import Link from "next/link";
import { AppShell } from "@/components/app-shell";
import { Button } from "@/components/ui/button";
import { PageHeading } from "@/components/page-heading";
import { requireRole } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";

export default async function AdminDashboard() {
  const profile = await requireRole("ADMIN");
  const supabase = await createClient();
  const [businesses, active, drafts, sdrs] = await Promise.all([
    supabase.from("businesses").select("id", { count: "exact", head: true }),
    supabase.from("bounties").select("id", { count: "exact", head: true }).eq("status", "ACTIVE"),
    supabase.from("bounties").select("id", { count: "exact", head: true }).eq("status", "DRAFT"),
    supabase.from("profiles").select("id", { count: "exact", head: true }).eq("role", "SDR"),
  ]);
  const cards = [["Businesses", businesses.count ?? 0], ["Active bounties", active.count ?? 0], ["Draft bounties", drafts.count ?? 0], ["SDRs", sdrs.count ?? 0]];
  return <AppShell profile={profile}><div className="mx-auto max-w-6xl px-5 py-10"><PageHeading eyebrow="Admin" title="Dashboard" description="Только фактические данные Sprint 1, без fake analytics." />
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">{cards.map(([label, value]) => <div key={label} className="rounded-2xl border bg-white p-5 shadow-sm"><p className="text-sm text-slate-500">{label}</p><p className="mt-2 text-3xl font-semibold">{value}</p></div>)}</div>
    <section className="mt-8 rounded-2xl border bg-white p-6 shadow-sm"><h2 className="font-semibold">Быстрые действия</h2><div className="mt-5 flex flex-wrap gap-3"><Button asChild><Link href="/admin/businesses/new">Создать бизнес</Link></Button><Button asChild><Link href="/admin/bounties/new">Создать bounty</Link></Button><Button asChild variant="outline"><Link href="/bounties">Посмотреть marketplace</Link></Button></div></section>
  </div></AppShell>;
}
