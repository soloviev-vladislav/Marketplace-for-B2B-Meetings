import { notFound } from "next/navigation";
import { AppShell } from "@/components/app-shell";
import { BountyForm } from "@/components/admin/bounty-form";
import { PageHeading } from "@/components/page-heading";
import { requireRole } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";
import type { Business, BountyStatus } from "@/lib/marketplace/types";

type EditBounty = Record<string, unknown> & { id: string; title: string; status: BountyStatus; current_version: number; bounty_icp?: Record<string, unknown>; bounty_materials?: Array<Record<string, unknown>> };

export default async function EditBountyPage({ params }: { params: Promise<{ id: string }> }) {
  const profile = await requireRole("ADMIN");
  const { id } = await params;
  const supabase = await createClient();
  const [{ data: bountyData }, { data: businessesData }] = await Promise.all([
    supabase.from("bounties").select("*,bounty_icp(*),bounty_materials(*)").eq("id", id).single(),
    supabase.from("businesses").select("*").order("brand_name"),
  ]);
  if (!bountyData) notFound();
  const bounty = bountyData as unknown as EditBounty;
  return <AppShell profile={profile}><div className="mx-auto max-w-4xl px-5 py-10"><PageHeading eyebrow={`Admin / Bounties · ${bounty.status}`} title={bounty.title} description={`Текущая опубликованная версия: ${bounty.current_version}.`} /><BountyForm businesses={(businessesData ?? []) as Business[]} bounty={bounty} /></div></AppShell>;
}
