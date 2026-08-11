import Link from "next/link";
import { AppShell } from "@/components/app-shell";
import { Button } from "@/components/ui/button";
import { PageHeading } from "@/components/page-heading";
import { requireRole } from "@/lib/auth/session";

export default async function SdrDashboard() {
  const profile = await requireRole("SDR");
  return <AppShell profile={profile}><div className="mx-auto max-w-6xl px-5 py-10"><PageHeading eyebrow="SDR" title={`Добро пожаловать, ${profile.display_name}`} description="Найдите bounty с подходящим ICP или продолжите работу с выбранными задачами." /><div className="grid gap-5 md:grid-cols-2"><section className="rounded-2xl border bg-white p-7 shadow-sm"><h2 className="text-lg font-semibold">Marketplace</h2><p className="mt-2 text-sm leading-6 text-slate-500">Активные bounty, reward и критерии квалифицированной встречи.</p><Button asChild className="mt-5"><Link href="/bounties">Открыть Marketplace</Link></Button></section><section className="rounded-2xl border bg-white p-7 shadow-sm"><h2 className="text-lg font-semibold">Мои bounty</h2><p className="mt-2 text-sm leading-6 text-slate-500">Задачи, которые вы уже взяли, и полный sales brief.</p><Button asChild variant="outline" className="mt-5"><Link href="/sdr/workspace">Открыть workspace</Link></Button></section></div></div></AppShell>;
}
