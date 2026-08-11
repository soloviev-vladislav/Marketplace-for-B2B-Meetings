"use client";

import {
  cloneElement,
  isValidElement,
  useActionState,
  type ReactElement,
} from "react";
import { saveBounty, type FormState } from "@/app/admin/actions";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import type { Business, BountyStatus } from "@/lib/marketplace/types";

type EditBounty = Record<string, unknown> & {
  id: string;
  status: BountyStatus;
  bounty_icp?: Record<string, unknown>;
  bounty_materials?: Array<Record<string, unknown>>;
};

const text = (value: unknown) =>
  typeof value === "string" || typeof value === "number" ? String(value) : "";
const list = (value: unknown) => (Array.isArray(value) ? value.join(", ") : "");
const rubles = (value: unknown) =>
  value == null ? "" : String(Number(value) / 100);

export function BountyForm({
  businesses,
  bounty,
}: {
  businesses: Business[];
  bounty?: EditBounty;
}) {
  const [state, action, pending] = useActionState(
    saveBounty,
    undefined as FormState,
  );
  const icp = bounty?.bounty_icp ?? {};
  const materials = bounty?.bounty_materials ?? [];
  const material = (kind: string) =>
    materials.find((item) => item.material_type === kind);
  const status = bounty?.status ?? "DRAFT";
  const isActive = status === "ACTIVE";

  return (
    <form action={action} className="space-y-8">
      {bounty && (
        <>
          <input type="hidden" name="id" value={bounty.id} />
          <input type="hidden" name="slug" value={text(bounty.slug)} />
        </>
      )}
      <Section
        title="Commercial"
        description="Вознаграждение хранится в базе в копейках."
      >
        <div className="grid gap-5 sm:grid-cols-2">
          <Field label="Business">
            <Select
              name="business_id"
              defaultValue={text(bounty?.business_id)}
              required
            >
              <option value="">Выберите business</option>
              {businesses.map((business) => (
                <option key={business.id} value={business.id}>
                  {business.brand_name} · {business.verification_status}
                </option>
              ))}
            </Select>
          </Field>
          <Field label="Название">
            <Input name="title" defaultValue={text(bounty?.title)} required />
          </Field>
          <div className="sm:col-span-2">
            <Field label="Краткое описание">
              <Textarea
                name="summary"
                defaultValue={text(bounty?.summary)}
                required
              />
            </Field>
          </div>
          <Field label="Reward SDR, ₽">
            <Input
              name="reward_rubles"
              inputMode="decimal"
              defaultValue={rubles(bounty?.reward_amount)}
              required
            />
          </Field>
          <Field label="Platform fee, ₽">
            <Input
              name="platform_fee_rubles"
              inputMode="decimal"
              defaultValue={rubles(bounty?.platform_fee_amount)}
              required
            />
          </Field>
          <Field label="Лимит встреч">
            <Input
              name="meeting_limit"
              type="number"
              min="1"
              defaultValue={text(bounty?.meeting_limit) || "10"}
              required
            />
          </Field>
          <Field label="Активен до">
            <Input
              name="active_until"
              type="date"
              defaultValue={text(bounty?.active_until).slice(0, 10)}
              required
            />
          </Field>
        </div>
      </Section>

      <Section
        title="ICP — hard criteria"
        description="Эти поля объективно определяют квалификацию и версионируются при публикации."
      >
        <div className="grid gap-5 sm:grid-cols-2">
          <Field label="География, через запятую">
            <Input
              name="geography"
              defaultValue={list(icp.geography)}
              required
            />
          </Field>
          <Field label="Индустрии">
            <Input
              name="industries"
              defaultValue={list(icp.industries)}
              required
            />
          </Field>
          <Field label="Исключённые индустрии">
            <Input
              name="excluded_industries"
              defaultValue={list(icp.excluded_industries)}
            />
          </Field>
          <Field label="Роли принимающих решения">
            <Input
              name="allowed_roles"
              defaultValue={list(icp.allowed_roles)}
              required
            />
          </Field>
          <Field label="Минимальная выручка, ₽">
            <Input
              name="min_revenue"
              type="number"
              min="0"
              defaultValue={text(icp.min_revenue) || "0"}
              required
            />
          </Field>
          <Field label="Максимальная выручка, ₽">
            <Input
              name="max_revenue"
              type="number"
              min="0"
              defaultValue={text(icp.max_revenue)}
            />
          </Field>
          <Field label="Минимум сотрудников">
            <Input
              name="min_employees"
              type="number"
              min="0"
              defaultValue={text(icp.min_employees)}
            />
          </Field>
          <Field label="Максимум сотрудников">
            <Input
              name="max_employees"
              type="number"
              min="0"
              defaultValue={text(icp.max_employees)}
            />
          </Field>
          <div className="sm:col-span-2">
            <Field label="Исключённые ИНН — скрыто до Take">
              <Textarea
                name="excluded_company_inns"
                defaultValue={list(icp.excluded_company_inns)}
              />
            </Field>
          </div>
          <div className="sm:col-span-2">
            <Field label="Дополнительные hard rules">
              <Textarea name="hard_rules" defaultValue={text(icp.hard_rules)} />
            </Field>
          </div>
        </div>
      </Section>

      <Section
        title="Soft notes"
        description="Подсказки для SDR, которые не являются основанием отказа."
      >
        <Field label="Soft notes">
          <Textarea name="soft_notes" defaultValue={text(icp.soft_notes)} />
        </Field>
      </Section>

      <Section
        title="Sales context"
        description="Полный brief открывается SDR только после Take."
      >
        <div className="space-y-5">
          <Field label="Краткое публичное описание продукта">
            <Textarea
              name="product_description"
              defaultValue={text(bounty?.product_description)}
              required
            />
          </Field>
          <Field label="Боли и триггеры">
            <Textarea
              name="pains"
              defaultValue={text(material("PAINS")?.content)}
            />
          </Field>
          <Field label="Ценностные предложения">
            <Textarea
              name="value_propositions"
              defaultValue={text(material("VALUE_PROPOSITIONS")?.content)}
            />
          </Field>
          <Field label="Website продукта">
            <Input
              name="sales_website"
              type="url"
              defaultValue={text(bounty?.sales_website)}
              required
            />
          </Field>
          <Field label="Outreach notes">
            <Textarea
              name="outreach_notes"
              defaultValue={text(material("OUTREACH_NOTES")?.content)}
            />
          </Field>
          <div className="grid gap-5 sm:grid-cols-2">
            <Field label="Название материала">
              <Input
                name="material_label"
                defaultValue={text(material("LINK")?.label)}
              />
            </Field>
            <Field label="Ссылка на материал">
              <Input
                name="material_url"
                type="url"
                defaultValue={text(material("LINK")?.external_url)}
              />
            </Field>
          </div>
        </div>
      </Section>

      <Section
        title="Meeting acceptance"
        description="Только текстовые правила Sprint 1; meeting workflow не создаётся."
      >
        <div className="grid gap-5 sm:grid-cols-2">
          <Field label="Минимальная длительность, минут">
            <Input
              name="minimum_duration_minutes"
              type="number"
              min="1"
              defaultValue={text(bounty?.minimum_duration_minutes) || "30"}
              required
            />
          </Field>
          <Field label="Формат">
            <Select
              name="meeting_format"
              defaultValue={text(bounty?.meeting_format) || "ONLINE"}
            >
              <option value="ONLINE">Online</option>
              <option value="OFFLINE">Offline</option>
              <option value="BOTH">Online или offline</option>
            </Select>
          </Field>
          <div className="sm:col-span-2">
            <Field label="Existing CRM rule">
              <Textarea
                name="existing_crm_rule"
                defaultValue={
                  text(bounty?.existing_crm_rule) ||
                  "Активная opportunity или содержательная коммуникация за последние 90 дней."
                }
                required
              />
            </Field>
          </div>
          <div className="sm:col-span-2">
            <Field label="Дополнительные acceptance notes">
              <Textarea
                name="acceptance_notes"
                defaultValue={text(bounty?.acceptance_notes)}
              />
            </Field>
          </div>
        </div>
      </Section>

      {isActive && (
        <p className="rounded-lg bg-amber-50 p-3 text-sm text-amber-800">
          Изменение versioned content ACTIVE bounty создаст новую immutable version.
        </p>
      )}
      <p className="rounded-lg bg-slate-100 p-3 text-sm text-slate-700">
        Черновик можно сохранить для бизнеса в любом статусе. Опубликовать bounty можно только для подтверждённого бизнеса.
      </p>
      {state?.error && (
        <p
          role="alert"
          className="rounded-lg bg-red-50 p-3 text-sm text-red-700"
        >
          {state.error}
        </p>
      )}
      <div className="flex flex-wrap gap-3">
        {status === "DRAFT" && (
          <>
            <Button name="action" value="SAVE" variant="outline" disabled={pending}>
              {pending ? "Сохранение…" : "Сохранить черновик"}
            </Button>
            <Button name="action" value="PUBLISH" disabled={pending}>
              Опубликовать
            </Button>
          </>
        )}
        {status === "ACTIVE" && (
          <>
            <Button name="action" value="SAVE" variant="outline" disabled={pending}>
              {pending ? "Сохранение…" : "Сохранить изменения"}
            </Button>
            <Button name="action" value="PAUSE" variant="outline" disabled={pending}>
              Поставить на паузу
            </Button>
          </>
        )}
        {status === "PAUSED" && (
          <>
            <Button name="action" value="SAVE" variant="outline" disabled={pending}>
              {pending ? "Сохранение…" : "Сохранить изменения"}
            </Button>
            <Button name="action" value="PUBLISH" disabled={pending}>
              Возобновить
            </Button>
          </>
        )}
        {status === "MODERATION" && (
          <>
            <Button name="action" value="SAVE" variant="outline" disabled={pending}>
              {pending ? "Сохранение…" : "Сохранить изменения"}
            </Button>
            <Button name="action" value="PUBLISH" disabled={pending}>
              Опубликовать
            </Button>
          </>
        )}
        {(status === "COMPLETED" || status === "REJECTED" || status === "ARCHIVED") && (
          <p className="text-sm text-slate-500">
            Для bounty в статусе {status} действия недоступны.
          </p>
        )}
      </div>
    </form>
  );
}

function Section({
  title,
  description,
  children,
}: {
  title: string;
  description: string;
  children: React.ReactNode;
}) {
  return (
    <section className="rounded-2xl border bg-white p-6 shadow-sm">
      <h2 className="text-lg font-semibold">{title}</h2>
      <p className="mt-1 mb-6 text-sm text-slate-500">{description}</p>
      {children}
    </section>
  );
}

function Field({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  const control = isValidElement<{ id?: string; name?: string }>(children)
    ? children as ReactElement<{ id?: string; name?: string }>
    : null;
  const controlId = control?.props.id ?? control?.props.name;

  return (
    <div className="space-y-2">
      <Label htmlFor={controlId}>{label}</Label>
      {control && controlId ? cloneElement(control, { id: controlId }) : children}
    </div>
  );
}
