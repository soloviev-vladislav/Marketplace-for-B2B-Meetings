import Link from "next/link";
import { AppShell } from "@/components/app-shell";
import { PageHeading } from "@/components/page-heading";
import { ProspectStatusBadge } from "@/components/prospects/prospect-status-badge";
import { Select } from "@/components/ui/select";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { formatDate } from "@/lib/marketplace/format";
import { requireRole } from "@/lib/auth/session";
import type { AdminProspect, ProspectStatus } from "@/lib/prospects/types";
import { createClient } from "@/lib/supabase/server";

type Filters = { status?: string; bounty?: string; page?: string };
type BountyOption = { id: string; title: string };
const PAGE_SIZE = 50;

function pageHref(filters: Filters, page: number) {
  const params = new URLSearchParams();
  if (filters.status) params.set("status", filters.status);
  if (filters.bounty) params.set("bounty", filters.bounty);
  if (page > 1) params.set("page", String(page));
  const query = params.toString();
  return query ? `/admin/prospects?${query}` : "/admin/prospects";
}

export default async function AdminProspectsPage({ searchParams }: { searchParams: Promise<Filters> }) {
  const profile = await requireRole("ADMIN");
  const filters = await searchParams;
  const requestedPage = Number.parseInt(filters.page ?? "1", 10);
  const page = Number.isSafeInteger(requestedPage) && requestedPage > 0 ? requestedPage : 1;
  const from = (page - 1) * PAGE_SIZE;
  const supabase = await createClient();
  let prospectsQuery = supabase
    .from("prospects")
    .select("*,bounties(title,slug),sdr:profiles!prospects_sdr_profile_id_fkey(display_name,email)", { count: "exact" })
    .order("created_at", { ascending: false })
    .order("id", { ascending: false })
    .range(from, from + PAGE_SIZE - 1);
  if (["PENDING", "APPROVED", "REJECTED", "EXPIRED"].includes(filters.status ?? "")) prospectsQuery = prospectsQuery.eq("status", filters.status!);
  if (filters.bounty) prospectsQuery = prospectsQuery.eq("bounty_id", filters.bounty);
  const [{ data, count }, { data: bountyData }] = await Promise.all([
    prospectsQuery,
    supabase.from("bounties").select("id,title").order("title"),
  ]);
  const prospects = (data ?? []) as unknown as AdminProspect[];
  const bounties = (bountyData ?? []) as BountyOption[];
  const totalPages = Math.max(1, Math.ceil((count ?? 0) / PAGE_SIZE));

  return <AppShell profile={profile}><div className="mx-auto max-w-6xl px-5 py-10">
    <PageHeading eyebrow="Admin" title="Prospects" description="Очередь проверки зарегистрированных компаний и контактов." />
    <form className="mb-7 grid gap-3 rounded-2xl border bg-white p-4 shadow-sm sm:grid-cols-[1fr_2fr_auto]">
      <div><Label htmlFor="status" className="sr-only">Статус</Label><Select id="status" name="status" defaultValue={filters.status}><option value="">Все статусы</option><option value="PENDING">PENDING</option><option value="APPROVED">APPROVED</option><option value="REJECTED">REJECTED</option><option value="EXPIRED">EXPIRED</option></Select></div>
      <div><Label htmlFor="bounty" className="sr-only">Bounty</Label><Select id="bounty" name="bounty" defaultValue={filters.bounty}><option value="">Все bounty</option>{bounties.map((bounty) => <option key={bounty.id} value={bounty.id}>{bounty.title}</option>)}</Select></div>
      <Button variant="outline">Применить</Button>
    </form>
    {prospects.length ? <div className="overflow-hidden rounded-2xl border bg-white shadow-sm">{prospects.map((prospect) => <Link key={prospect.id} href={`/admin/prospects/${prospect.id}`} className="grid gap-3 border-b p-5 last:border-0 hover:bg-slate-50 md:grid-cols-[1.2fr_1fr_1fr_auto]"><div><p className="font-medium">{prospect.company_name}</p><p className="text-sm text-slate-500">ИНН {prospect.company_inn}</p></div><div className="text-sm"><p>{prospect.contact_name}</p><p className="text-slate-500">{prospect.contact_title}</p></div><div className="text-sm"><p>{prospect.bounties?.title}</p><p className="text-slate-500">{prospect.sdr?.display_name} · {formatDate(prospect.created_at)}</p></div><ProspectStatusBadge status={prospect.status as ProspectStatus} /></Link>)}</div> : <div className="rounded-2xl border border-dashed bg-white p-12 text-center text-sm text-slate-500">Prospects по выбранным фильтрам не найдены.</div>}
    {totalPages > 1 && <nav aria-label="Пагинация prospects" className="mt-6 flex items-center justify-between"><Button asChild variant="outline" size="sm" className={page <= 1 ? "pointer-events-none opacity-50" : undefined}><Link href={pageHref(filters, page - 1)} aria-disabled={page <= 1}>← Назад</Link></Button><p className="text-sm text-slate-500">Страница {page} из {totalPages}</p><Button asChild variant="outline" size="sm" className={page >= totalPages ? "pointer-events-none opacity-50" : undefined}><Link href={pageHref(filters, page + 1)} aria-disabled={page >= totalPages}>Вперёд →</Link></Button></nav>}
  </div></AppShell>;
}
