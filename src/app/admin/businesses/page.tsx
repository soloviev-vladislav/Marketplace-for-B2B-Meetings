import Link from "next/link";
import { AppShell } from "@/components/app-shell";
import { Button } from "@/components/ui/button";
import { PageHeading } from "@/components/page-heading";
import { requireRole } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";
import type { Business } from "@/lib/marketplace/types";

export default async function BusinessesPage() {
  const profile = await requireRole("ADMIN");
  const supabase = await createClient();
  const { data } = await supabase.from("businesses").select("*").order("created_at", { ascending: false });
  const businesses = (data ?? []) as Business[];
  return <AppShell profile={profile}><div className="mx-auto max-w-6xl px-5 py-10"><PageHeading eyebrow="Admin" title="Businesses" description="Карточки заказчиков, созданные вручную." actions={<Button asChild><Link href="/admin/businesses/new">Создать бизнес</Link></Button>} />
    <div className="overflow-hidden rounded-2xl border bg-white shadow-sm">{businesses.length ? businesses.map((business) => <Link key={business.id} href={`/admin/businesses/${business.id}`} className="grid gap-2 border-b p-5 last:border-0 hover:bg-slate-50 sm:grid-cols-[1fr_1fr_auto]"><div><p className="font-medium">{business.brand_name}</p><p className="text-sm text-slate-500">{business.legal_name}</p></div><div className="text-sm text-slate-600">ИНН {business.inn}<br />{business.domain}</div><Status value={business.verification_status} /></Link>) : <p className="p-10 text-center text-sm text-slate-500">Бизнесов пока нет.</p>}</div>
  </div></AppShell>;
}

function Status({ value }: { value: string }) { return <span className="h-fit rounded-full bg-slate-100 px-3 py-1 text-xs font-medium">{value}</span>; }
