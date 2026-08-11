import Link from "next/link";
import { AppShell } from "@/components/app-shell";
import { PageHeading } from "@/components/page-heading";
import { ProspectStatusBadge } from "@/components/prospects/prospect-status-badge";
import { formatDate } from "@/lib/marketplace/format";
import { requireRole } from "@/lib/auth/session";
import type { SdrProspect } from "@/lib/prospects/types";
import { createClient } from "@/lib/supabase/server";

export default async function SdrProspectsPage({ searchParams }: { searchParams: Promise<{ status?: string }> }) {
  const profile = await requireRole("SDR");
  const query = await searchParams;
  const supabase = await createClient();
  const { data } = await supabase.rpc("sdr_prospects");
  const prospects = (data ?? []) as SdrProspect[];
  return <AppShell profile={profile}><div className="mx-auto max-w-6xl px-5 py-10"><PageHeading eyebrow="SDR workspace" title="Мои prospects" description="Только ваши регистрации и результаты проверки." />
    {query.status === "created" && <p className="mb-6 rounded-xl bg-emerald-50 p-4 text-sm text-emerald-800">Prospect зарегистрирован и отправлен на проверку.</p>}
    {prospects.length ? <div className="space-y-4">{prospects.map((prospect) => <article key={prospect.id} className="rounded-2xl border bg-white p-6 shadow-sm"><div className="flex flex-wrap items-start justify-between gap-4"><div><p className="text-sm text-slate-500"><Link href={`/bounties/${prospect.bounty_slug}`} className="hover:text-slate-900">{prospect.bounty_title}</Link></p><h2 className="mt-1 text-lg font-semibold">{prospect.company_name}</h2><p className="mt-2 text-sm text-slate-600">{prospect.company_inn ? `ИНН ${prospect.company_inn}` : prospect.company_domain}</p></div><ProspectStatusBadge status={prospect.status} /></div><div className="mt-5 grid gap-3 border-t pt-4 text-sm sm:grid-cols-2"><div><p className="text-xs uppercase tracking-wide text-slate-400">Контакт</p><p className="mt-1 font-medium">{prospect.contact_name} · {prospect.contact_title}</p><p className="text-slate-500">{prospect.contact_email}</p></div><div><p className="text-xs uppercase tracking-wide text-slate-400">Зарегистрирован</p><p className="mt-1">{formatDate(prospect.created_at)}</p></div></div>{prospect.status === "REJECTED" && prospect.rejection_reason && <p className="mt-4 rounded-lg bg-red-50 p-3 text-sm text-red-700"><span className="font-semibold">Причина:</span> {prospect.rejection_reason}</p>}</article>)}</div> : <div className="rounded-2xl border border-dashed bg-white p-12 text-center"><h2 className="font-semibold">Prospects пока нет</h2><p className="mt-2 text-sm text-slate-500">Откройте взятый bounty и зарегистрируйте первую компанию.</p><Link href="/sdr/workspace" className="mt-4 inline-block text-sm font-semibold">Перейти к bounty →</Link></div>}
  </div></AppShell>;
}
