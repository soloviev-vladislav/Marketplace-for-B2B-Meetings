import { redirect } from "next/navigation";
import { AppShell } from "@/components/app-shell";
import { BountyCard } from "@/components/bounty-card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { PageHeading } from "@/components/page-heading";
import { getSessionProfile } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";
import type { MarketplaceBounty } from "@/lib/marketplace/types";

type Filters = { reward?: string; industry?: string; geography?: string; role?: string; error?: string };

export default async function MarketplacePage({ searchParams }: { searchParams: Promise<Filters> }) {
  const profile = await getSessionProfile();
  if (!profile) redirect("/login");
  if (profile.role === "BUSINESS") redirect("/business/dashboard");
  const filters = await searchParams;
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("marketplace_bounties");
  const minimumReward = Number(filters.reward || 0) * 100;
  const contains = (items: string[], query?: string) => !query || items.some((item) => item.toLocaleLowerCase("ru").includes(query.toLocaleLowerCase("ru")));
  const bounties = ((data ?? []) as MarketplaceBounty[]).filter((bounty) =>
    bounty.reward_amount >= minimumReward && contains(bounty.industries, filters.industry) && contains(bounty.geography, filters.geography) && contains(bounty.allowed_roles, filters.role),
  );

  return <AppShell profile={profile}><div className="mx-auto max-w-6xl px-5 py-10"><PageHeading eyebrow="Marketplace" title="Оплачиваемые B2B-встречи" description="Выберите подходящий ICP и получите полный sales brief после Take." />
    <form className="mb-8 grid gap-3 rounded-2xl border bg-white p-4 shadow-sm md:grid-cols-5"><div><Label className="sr-only" htmlFor="reward">Минимальный reward</Label><Input id="reward" name="reward" type="number" min="0" defaultValue={filters.reward} placeholder="Reward от, ₽" /></div><div><Label className="sr-only" htmlFor="industry">Индустрия</Label><Input id="industry" name="industry" defaultValue={filters.industry} placeholder="Индустрия" /></div><div><Label className="sr-only" htmlFor="geography">География</Label><Input id="geography" name="geography" defaultValue={filters.geography} placeholder="География" /></div><div><Label className="sr-only" htmlFor="role">Роль принимающего решение</Label><Input id="role" name="role" defaultValue={filters.role} placeholder="Роль ЛПР" /></div><Button type="submit" variant="outline">Применить</Button></form>
    {(error || filters.error) && <p className="mb-6 rounded-lg bg-red-50 p-3 text-sm text-red-700">Не удалось выполнить действие. Обновите страницу.</p>}
    {bounties.length ? <div className="grid gap-5 md:grid-cols-2">{bounties.map((bounty) => <BountyCard key={bounty.id} bounty={bounty} />)}</div> : <div className="rounded-2xl border border-dashed bg-white p-12 text-center text-slate-500">Активных bounty по выбранным фильтрам нет.</div>}
  </div></AppShell>;
}
