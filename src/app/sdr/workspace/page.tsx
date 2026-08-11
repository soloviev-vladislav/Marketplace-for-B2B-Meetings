import Link from "next/link";
import { AppShell } from "@/components/app-shell";
import { Button } from "@/components/ui/button";
import { PageHeading } from "@/components/page-heading";
import { BountyStatusBadge } from "@/components/bounty-status-badge";
import { formatDate, formatMoney } from "@/lib/marketplace/format";
import { requireRole } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";
import type { WorkspaceBounty } from "@/lib/marketplace/types";
import type { SdrProspect } from "@/lib/prospects/types";

export default async function WorkspacePage() {
  const profile = await requireRole("SDR");
  const supabase = await createClient();
  const [{ data }, { data: prospectData }] = await Promise.all([
    supabase.rpc("sdr_workspace"),
    supabase.rpc("sdr_prospects"),
  ]);
  const bounties = (data ?? []) as WorkspaceBounty[];
  const prospects = (prospectData ?? []) as SdrProspect[];
  const prospectCounts = prospects.reduce<Record<string, number>>((counts, prospect) => {
    counts[prospect.bounty_id] = (counts[prospect.bounty_id] ?? 0) + 1;
    return counts;
  }, {});
  return (
    <AppShell profile={profile}>
      <div className="mx-auto max-w-6xl px-5 py-10">
        <PageHeading
          eyebrow="SDR workspace"
          title="Мои bounty"
          description="Bounty, которые вы взяли в работу. Take не резервирует компании и не уменьшает quota."
          actions={
            <Button asChild variant="outline">
              <Link href="/bounties">Открыть Marketplace</Link>
            </Button>
          }
        />
        {bounties.length ? (
          <div className="space-y-4">
            {bounties.map((bounty) => (
              <article
                key={bounty.id}
                className="rounded-2xl border bg-white p-6 shadow-sm"
              >
                <div className="flex flex-wrap items-start justify-between gap-4">
                  <div>
                    <div className="flex flex-wrap items-center gap-2">
                      <p className="text-sm text-slate-500">
                        {bounty.brand_name}
                      </p>
                      <BountyStatusBadge status={bounty.is_expired ? "EXPIRED" : bounty.status} />
                    </div>
                    <h2 className="mt-2 text-lg font-semibold">
                      {bounty.title}
                    </h2>
                    <p className="mt-2 text-sm text-slate-600">
                      {bounty.geography.join(", ")} ·{" "}
                      {bounty.industries.join(", ")} ·{" "}
                      {bounty.allowed_roles.join(", ")}
                    </p>
                  {bounty.is_expired && (
                    <p className="mt-3 text-sm font-medium text-orange-700">
                      Срок действия bounty истёк. Не начинайте новую работу.
                    </p>
                  )}
                  {bounty.status === "PAUSED" && (
                      <p className="mt-3 text-sm font-medium text-amber-700">
                        Новая работа по bounty временно остановлена.
                      </p>
                    )}
                    {(bounty.status === "COMPLETED" ||
                      bounty.status === "ARCHIVED") && (
                      <p className="mt-3 text-sm text-slate-500">
                        Bounty доступен в истории только для чтения.
                      </p>
                    )}
                  </div>
                  <p className="text-xl font-bold text-emerald-700">
                    {formatMoney(bounty.reward_amount)}
                  </p>
                </div>
                <div className="mt-5 flex flex-wrap items-center justify-between gap-4 border-t pt-4">
                  <div className="flex gap-5 text-xs text-slate-500">
                    <span>Взят {formatDate(bounty.taken_at)}</span>
                    <span>Prospects: {prospectCounts[bounty.id] ?? 0}</span>
                    <span>Meetings: 0</span>
                    <span>Earnings: 0 ₽</span>
                  </div>
                  <div className="flex flex-wrap items-center gap-3">
                    {bounty.status === "ACTIVE" && !bounty.is_expired && (
                      <Button asChild size="sm">
                        <Link href={`/sdr/prospects/new?bountyId=${bounty.id}`}>Добавить prospect</Link>
                      </Button>
                    )}
                    <Link href={`/bounties/${bounty.slug}`} className="text-sm font-semibold">Открыть brief →</Link>
                  </div>
                </div>
              </article>
            ))}
          </div>
        ) : (
          <div className="rounded-2xl border border-dashed bg-white p-12 text-center">
            <h2 className="font-semibold">Workspace пуст</h2>
            <p className="mt-2 text-sm text-slate-500">
              Выберите первый bounty в Marketplace.
            </p>
            <Button asChild className="mt-5">
              <Link href="/bounties">Перейти в Marketplace</Link>
            </Button>
          </div>
        )}
      </div>
    </AppShell>
  );
}
