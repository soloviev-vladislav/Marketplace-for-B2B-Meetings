import { AppShell } from "@/components/app-shell";
import { BountyForm } from "@/components/admin/bounty-form";
import { PageHeading } from "@/components/page-heading";
import { requireRole } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";
import type { Business } from "@/lib/marketplace/types";

export default async function NewBountyPage() {
  const profile = await requireRole("ADMIN");
  const supabase = await createClient();
  const { data } = await supabase.from("businesses").select("*").order("brand_name");
  return <AppShell profile={profile}><div className="mx-auto max-w-4xl px-5 py-10"><PageHeading eyebrow="Admin / Bounties" title="Новый bounty" description="Одна структурированная форма. Hard criteria отделены от soft notes." />{data?.length ? <BountyForm businesses={data as Business[]} /> : <div className="rounded-2xl border bg-white p-10 text-center text-slate-600">Сначала создайте business.</div>}</div></AppShell>;
}
