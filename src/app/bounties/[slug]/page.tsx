import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { Archive, CheckCircle2, ClockAlert, LockKeyhole, PauseCircle } from "lucide-react";
import { takeBounty } from "@/app/bounties/actions";
import { AppShell } from "@/components/app-shell";
import { Tag } from "@/components/bounty-card";
import { Button } from "@/components/ui/button";
import { BountyStatusBadge } from "@/components/bounty-status-badge";
import { formatDate, formatMoney } from "@/lib/marketplace/format";
import { getSessionProfile } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";
import type { BountyDetail } from "@/lib/marketplace/types";

export default async function BountyDetailsPage({
  params,
  searchParams,
}: {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ status?: string }>;
}) {
  const profile = await getSessionProfile();
  if (!profile) redirect("/login");
  if (profile.role === "BUSINESS") redirect("/business/dashboard");
  const [{ slug }, query] = await Promise.all([params, searchParams]);
  const supabase = await createClient();
  const { data } = await supabase.rpc("marketplace_bounty_detail", {
    target_slug: slug,
  });
  if (!data) notFound();
  const detail = data as BountyDetail;
  const { bounty, business, icp } = detail;
  const backHref =
    profile.role === "ADMIN"
      ? "/admin/bounties"
      : bounty.status === "ACTIVE" && !bounty.is_expired
        ? "/bounties"
        : "/sdr/workspace";
  const backLabel =
    profile.role === "ADMIN"
      ? "Admin bounties"
      : bounty.status === "ACTIVE" && !bounty.is_expired
        ? "Marketplace"
        : "Мои bounty";
  return (
    <AppShell profile={profile}>
      <div className="mx-auto max-w-5xl px-5 py-10">
      {query.status === "taken" && (
          <p className="mb-6 flex items-center gap-2 rounded-xl bg-emerald-50 p-4 text-sm text-emerald-800">
            <CheckCircle2 size={18} />
            Bounty добавлен в workspace. Полный brief открыт.
          </p>
      )}
      {bounty.is_expired && (
        <div className="mb-6 flex items-start gap-3 rounded-xl border border-orange-200 bg-orange-50 p-4 text-sm text-orange-900">
          <ClockAlert className="mt-0.5 shrink-0" size={19} />
          <div><p className="font-semibold">Срок истёк</p><p className="mt-1">Срок действия bounty истёк. Не начинайте новую работу.</p></div>
        </div>
      )}
        {bounty.status === "PAUSED" && (
          <div className="mb-6 flex items-start gap-3 rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900">
            <PauseCircle className="mt-0.5 shrink-0" size={19} />
            <div>
              <p className="font-semibold">Bounty на паузе</p>
              <p className="mt-1">
                Заказчик временно приостановил bounty. Не начинайте новую работу
                до возобновления.
              </p>
            </div>
          </div>
        )}
        {(bounty.status === "COMPLETED" || bounty.status === "ARCHIVED") && (
          <div className="mb-6 flex items-start gap-3 rounded-xl border border-slate-200 bg-slate-100 p-4 text-sm text-slate-700">
            <Archive className="mt-0.5 shrink-0" size={19} />
            <div>
              <p className="font-semibold">Исторический bounty</p>
              <p className="mt-1">
                Bounty больше не принимает новую работу. Reward и полученный
                brief доступны только для чтения.
              </p>
            </div>
          </div>
        )}
        <Link
          href={backHref}
          className="text-sm text-slate-500 hover:text-slate-900"
        >
          ← {backLabel}
        </Link>
        <div className="mt-5 grid gap-7 lg:grid-cols-[1fr_300px]">
          <div className="space-y-6">
            <section className="rounded-2xl border bg-white p-7 shadow-sm">
              <div className="flex flex-wrap items-center gap-3">
                <p className="text-sm font-medium text-slate-500">
                  {business.brand_name}
                </p>
                    <BountyStatusBadge status={bounty.is_expired ? "EXPIRED" : bounty.status} />
              </div>
              <h1 className="mt-2 text-3xl font-semibold tracking-tight">
                {bounty.title}
              </h1>
              <p className="mt-4 leading-7 text-slate-600">{bounty.summary}</p>
              <div className="mt-5 flex flex-wrap gap-2">
                {icp.geography.map((item) => (
                  <Tag key={item}>{item}</Tag>
                ))}
                {icp.industries.map((item) => (
                  <Tag key={item}>{item}</Tag>
                ))}
              </div>
            </section>
            <Section title="Кого ищем">
              <Info label="Роли" value={icp.allowed_roles.join(", ")} />
              <Info
                label="Размер компании"
                value={`${icp.min_employees ?? "—"}–${icp.max_employees ?? "∞"} сотрудников`}
              />
              <Info
                label="Выручка"
                value={`от ${new Intl.NumberFormat("ru-RU").format(icp.min_revenue)} ₽${icp.max_revenue ? ` до ${new Intl.NumberFormat("ru-RU").format(icp.max_revenue)} ₽` : ""}`}
              />
              {icp.hard_rules && (
                <Info
                  label="Дополнительные hard criteria"
                  value={icp.hard_rules}
                />
              )}
            </Section>
            <Section title="Что считается оплачиваемой встречей">
              <Info
                label="Длительность"
                value={`Минимум ${bounty.minimum_duration_minutes} минут`}
              />
              <Info label="Формат" value={bounty.meeting_format} />
              <Info label="Existing CRM" value={bounty.existing_crm_rule} />
              {bounty.acceptance_notes && (
                <Info label="Дополнительно" value={bounty.acceptance_notes} />
              )}
            </Section>
            <Section title="О продукте">
              <p className="leading-7 text-slate-600">
                {bounty.product_description}
              </p>
            </Section>
            <Section title="Business">
              <p className="font-medium">{business.brand_name}</p>
              <p className="mt-2 text-sm leading-6 text-slate-600">
                {business.description}
              </p>
              <a
                href={business.website}
                target="_blank"
                rel="noreferrer"
                className="mt-3 inline-block text-sm font-medium underline"
              >
                {business.domain}
              </a>
            </Section>
            {detail.has_taken || profile.role === "ADMIN" ? (
              <Section title="Полный sales brief">
                <div className="space-y-5">
                  {icp.soft_notes && (
                    <div>
                      <h3 className="text-sm font-semibold">Soft notes</h3>
                      <p className="mt-1 whitespace-pre-wrap text-sm leading-6 text-slate-600">
                        {icp.soft_notes}
                      </p>
                    </div>
                  )}
                  <div>
                    <h3 className="text-sm font-semibold">Сайт продукта</h3>
                    <a
                      className="mt-1 inline-block text-sm font-medium underline"
                      href={bounty.sales_website}
                      target="_blank"
                      rel="noreferrer"
                    >
                      {bounty.sales_website}
                    </a>
                  </div>
                  {detail.materials.map((material) => (
                    <div key={`${material.material_type}-${material.label}`}>
                      <h3 className="text-sm font-semibold">
                        {material.label}
                      </h3>
                      {material.content && (
                        <p className="mt-1 whitespace-pre-wrap text-sm leading-6 text-slate-600">
                          {material.content}
                        </p>
                      )}
                      {material.external_url && (
                        <a
                          className="mt-1 inline-block text-sm font-medium underline"
                          href={material.external_url}
                          target="_blank"
                          rel="noreferrer"
                        >
                          Открыть материал
                        </a>
                      )}
                    </div>
                  ))}
                </div>
              </Section>
            ) : (
              <section className="rounded-2xl border border-dashed bg-slate-50 p-7 text-center">
                <LockKeyhole className="mx-auto text-slate-500" />
                <h2 className="mt-3 font-semibold">Полный brief закрыт</h2>
                <p className="mt-2 text-sm text-slate-500">
                  Возьмите bounty в работу, чтобы увидеть pains, value
                  propositions, outreach notes и материалы.
                </p>
              </section>
            )}
          </div>
          <aside>
            <div className="sticky top-5 rounded-2xl border bg-white p-6 shadow-sm">
              <p className="text-sm text-slate-500">
                Reward за принятую встречу
              </p>
              <p className="mt-2 text-3xl font-bold text-emerald-700">
                {formatMoney(bounty.reward_amount)}
              </p>
              <dl className="mt-5 space-y-3 border-t pt-5 text-sm">
                <Info
                  label="Свободно слотов"
                  value={String(bounty.meeting_limit - bounty.accepted_count)}
                />
                <Info
                  label="Активен до"
                  value={formatDate(bounty.active_until)}
                />
              </dl>
              {profile.role === "SDR" &&
                (detail.has_taken ? (
                  <Button className="mt-6 w-full" asChild>
                    <Link href="/sdr/workspace">В workspace</Link>
                  </Button>
                ) : (
                  <form action={takeBounty} className="mt-6">
                    <input type="hidden" name="bountyId" value={bounty.id} />
                    <input type="hidden" name="slug" value={bounty.slug} />
                    <Button className="w-full">Взять в работу</Button>
                  </form>
                ))}
            </div>
          </aside>
        </div>
      </div>
    </AppShell>
  );
}

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="rounded-2xl border bg-white p-7 shadow-sm">
      <h2 className="mb-5 text-xl font-semibold">{title}</h2>
      {children}
    </section>
  );
}
function Info({ label, value }: { label: string; value: string }) {
  return (
    <div className="mb-3 last:mb-0">
      <p className="text-xs font-medium uppercase tracking-wide text-slate-400">
        {label}
      </p>
      <p className="mt-1 text-sm leading-6 text-slate-700">{value}</p>
    </div>
  );
}
