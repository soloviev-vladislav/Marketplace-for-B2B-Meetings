import Link from "next/link";
import { notFound } from "next/navigation";
import { AppShell } from "@/components/app-shell";
import { PageHeading } from "@/components/page-heading";
import { ProspectForm } from "@/components/prospects/prospect-form";
import { requireRole } from "@/lib/auth/session";
import type { WorkspaceBounty } from "@/lib/marketplace/types";
import { createClient } from "@/lib/supabase/server";

export default async function NewProspectPage({ searchParams }: { searchParams: Promise<{ bountyId?: string }> }) {
  const profile = await requireRole("SDR");
  const { bountyId } = await searchParams;
  if (!bountyId) notFound();
  const supabase = await createClient();
  const { data } = await supabase.rpc("sdr_workspace");
  const bounty = ((data ?? []) as WorkspaceBounty[]).find((item) => item.id === bountyId);
  if (!bounty) notFound();
  const available = bounty.status === "ACTIVE" && !bounty.is_expired;
  return <AppShell profile={profile}><div className="mx-auto max-w-3xl px-5 py-10"><Link href="/sdr/workspace" className="text-sm text-slate-500 hover:text-slate-900">← Мои bounty</Link><div className="mt-5"><PageHeading eyebrow="Новый prospect" title={bounty.title} description="Ownership в российском MVP определяется по обязательному нормализованному ИНН." /></div>{available ? <section className="rounded-2xl border bg-white p-6 shadow-sm"><ProspectForm bountyId={bounty.id} /></section> : <div className="rounded-2xl border border-amber-200 bg-amber-50 p-6 text-amber-900"><h2 className="font-semibold">Регистрация недоступна</h2><p className="mt-2 text-sm">Bounty не принимает новую работу. Ранее созданные prospects остаются в истории.</p></div>}</div></AppShell>;
}
