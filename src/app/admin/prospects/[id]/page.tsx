import Link from "next/link";
import { notFound } from "next/navigation";
import { AppShell } from "@/components/app-shell";
import { PageHeading } from "@/components/page-heading";
import { ReviewForm } from "@/components/prospects/review-form";
import { ProspectStatusBadge } from "@/components/prospects/prospect-status-badge";
import { requireRole } from "@/lib/auth/session";
import type { AdminProspect } from "@/lib/prospects/types";
import { createClient } from "@/lib/supabase/server";

export default async function AdminProspectPage({ params, searchParams }: { params: Promise<{ id: string }>; searchParams: Promise<{ status?: string }> }) {
  const profile = await requireRole("ADMIN");
  const [{ id }, query] = await Promise.all([params, searchParams]);
  const supabase = await createClient();
  const { data } = await supabase.from("prospects").select("*,bounties(title,slug),sdr:profiles!prospects_sdr_profile_id_fkey(display_name,email)").eq("id", id).single();
  if (!data) notFound();
  const prospect = data as unknown as AdminProspect;
  return <AppShell profile={profile}><div className="mx-auto max-w-4xl px-5 py-10"><Link href="/admin/prospects" className="text-sm text-slate-500 hover:text-slate-900">← Prospects</Link>{query.status === "reviewed" && <p className="mt-5 rounded-xl bg-emerald-50 p-4 text-sm text-emerald-800">Решение сохранено.</p>}<div className="mt-5"><PageHeading eyebrow="Admin / Prospect" title={prospect.company_name} actions={<ProspectStatusBadge status={prospect.status} />} /></div><div className="grid gap-6 md:grid-cols-2"><Section title="Компания"><Item label="ИНН" value={prospect.company_inn ?? "—"} /><Item label="Domain" value={prospect.company_domain ?? "—"} /><Item label="Bounty" value={prospect.bounties?.title ?? "—"} /></Section><Section title="Контакт"><Item label="Имя" value={prospect.contact_name} /><Item label="Должность" value={prospect.contact_title} /><Item label="Email" value={prospect.contact_email} /><Item label="Телефон" value={prospect.contact_phone ?? "—"} /><Item label="Telegram" value={prospect.contact_telegram ?? "—"} /></Section><Section title="SDR"><Item label="Профиль" value={prospect.sdr?.display_name ?? "—"} /><Item label="Email" value={prospect.sdr?.email ?? "—"} /></Section><Section title="Review">{prospect.status === "PENDING" ? <ReviewForm prospectId={prospect.id} /> : <div><p className="text-sm text-slate-500">Prospect уже рассмотрен.</p>{prospect.rejection_reason && <p className="mt-3 rounded-lg bg-red-50 p-3 text-sm text-red-700">{prospect.rejection_reason}</p>}</div>}</Section></div></div></AppShell>;
}

function Section({ title, children }: { title: string; children: React.ReactNode }) { return <section className="rounded-2xl border bg-white p-6 shadow-sm"><h2 className="mb-5 text-lg font-semibold">{title}</h2>{children}</section>; }
function Item({ label, value }: { label: string; value: string }) { return <div className="mb-3 last:mb-0"><p className="text-xs uppercase tracking-wide text-slate-400">{label}</p><p className="mt-1 text-sm text-slate-700">{value}</p></div>; }
