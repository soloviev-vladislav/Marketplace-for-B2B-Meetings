import { notFound } from "next/navigation";
import { AppShell } from "@/components/app-shell";
import { BusinessForm } from "@/components/admin/business-form";
import { PageHeading } from "@/components/page-heading";
import { requireRole } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";
import type { Business } from "@/lib/marketplace/types";

export default async function BusinessPage({ params }: { params: Promise<{ id: string }> }) {
  const profile = await requireRole("ADMIN");
  const { id } = await params;
  const supabase = await createClient();
  const { data } = await supabase.from("businesses").select("*").eq("id", id).single();
  if (!data) notFound();
  const business = data as Business;
  return <AppShell profile={profile}><div className="mx-auto max-w-3xl px-5 py-10"><PageHeading eyebrow="Admin / Businesses" title={business.brand_name} description="Изменения verification status применяются сразу." /><section className="rounded-2xl border bg-white p-6 shadow-sm"><BusinessForm business={business} /></section></div></AppShell>;
}
