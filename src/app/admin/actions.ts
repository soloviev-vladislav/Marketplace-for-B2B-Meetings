"use server";

import { randomUUID } from "node:crypto";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { requireRole } from "@/lib/auth/session";
import { serializeActiveUntil } from "@/lib/marketplace/bounty-payload";
import { createClient } from "@/lib/supabase/server";
import { businessSchema, bountySchema } from "@/lib/validations/marketplace";

export type FormState = { error?: string } | undefined;

function values(formData: FormData, keys: string[]) {
  return Object.fromEntries(keys.map((key) => [key, formData.get(key) ?? ""]));
}

export async function saveBusiness(
  _: FormState,
  formData: FormData,
): Promise<FormState> {
  await requireRole("ADMIN");
  const parsed = businessSchema.safeParse(
    values(formData, [
      "legal_name",
      "brand_name",
      "inn",
      "website",
      "domain",
      "description",
      "verification_status",
    ]),
  );
  if (!parsed.success) return { error: parsed.error.issues[0]?.message };

  const id = formData.get("id");
  const supabase = await createClient();
  const { data, error } = id
    ? await supabase.rpc("admin_update_business", {
        target_id: id,
        payload: parsed.data,
      })
    : await supabase.rpc("admin_create_business", { payload: parsed.data });

  if (error)
    return {
      error: error.message.includes("unique")
        ? "Бизнес с таким ИНН уже существует"
        : "Не удалось сохранить бизнес",
    };
  const destination = id || data;
  revalidatePath("/admin/businesses");
  redirect(`/admin/businesses/${destination}?status=saved`);
}

export async function saveBounty(
  _: FormState,
  formData: FormData,
): Promise<FormState> {
  await requireRole("ADMIN");
  const requestedAction = formData.get("action");
  const action =
    requestedAction === "PUBLISH" || requestedAction === "PAUSE"
      ? requestedAction
      : "SAVE";
  const id = formData.get("id");
  if (action === "PAUSE") {
    const supabase = await createClient();
    const { data, error } = await supabase.rpc("admin_save_bounty", {
      target_id: id || null,
      payload: {},
      action,
    });
    if (error) return { error: "Не удалось поставить bounty на паузу." };
    revalidatePath("/admin/bounties");
    revalidatePath("/bounties");
    redirect(`/admin/bounties/${data}?status=pause`);
  }
  const parsed = bountySchema.safeParse(
    values(formData, [
      "business_id",
      "title",
      "slug",
      "summary",
      "reward_rubles",
      "platform_fee_rubles",
      "meeting_limit",
      "active_until",
      "original_active_until",
      "geography",
      "industries",
      "excluded_industries",
      "min_revenue",
      "max_revenue",
      "min_employees",
      "max_employees",
      "allowed_roles",
      "excluded_company_inns",
      "hard_rules",
      "soft_notes",
      "product_description",
      "pains",
      "value_propositions",
      "sales_website",
      "outreach_notes",
      "material_label",
      "material_url",
      "minimum_duration_minutes",
      "meeting_format",
      "existing_crm_rule",
      "acceptance_notes",
    ]),
  );
  if (!parsed.success) return { error: parsed.error.issues[0]?.message };

  const slug =
    parsed.data.slug && /^[a-z0-9-]+$/.test(parsed.data.slug)
      ? parsed.data.slug
      : `bounty-${randomUUID().slice(0, 8)}`;
  const materials = [
    {
      label: "Боли и триггеры",
      content: parsed.data.pains,
      external_url: "",
      material_type: "PAINS",
      sort_order: 10,
    },
    {
      label: "Ценностные предложения",
      content: parsed.data.value_propositions,
      external_url: "",
      material_type: "VALUE_PROPOSITIONS",
      sort_order: 20,
    },
    {
      label: "Рекомендации по аутричу",
      content: parsed.data.outreach_notes,
      external_url: "",
      material_type: "OUTREACH_NOTES",
      sort_order: 30,
    },
    {
      label: parsed.data.material_label || "Материал",
      content: "",
      external_url: parsed.data.material_url,
      material_type: "LINK",
      sort_order: 40,
    },
  ];
  const payload = {
    ...parsed.data,
    slug,
    reward_amount: parsed.data.reward_rubles,
    platform_fee_amount: parsed.data.platform_fee_rubles,
    active_until: serializeActiveUntil(
      parsed.data.active_until,
      String(formData.get("original_active_until") ?? "") || undefined,
    ),
    max_revenue: parsed.data.max_revenue === "" ? "" : parsed.data.max_revenue,
    min_employees:
      parsed.data.min_employees === "" ? "" : parsed.data.min_employees,
    max_employees:
      parsed.data.max_employees === "" ? "" : parsed.data.max_employees,
    materials,
  };

  const supabase = await createClient();
  const { data, error } = await supabase.rpc("admin_save_bounty", {
    target_id: id || null,
    payload,
    action,
  });
  if (error) {
    if (error.message.includes("BUSINESS_NOT_VERIFIED"))
      return {
        error: "Опубликовать bounty можно только для подтверждённого бизнеса.",
      };
    if (error.message.includes("ACTIVE_UNTIL_IN_PAST"))
      return { error: "Для публикации укажите будущую дату окончания." };
    if (error.message.includes("unique"))
      return { error: "Не удалось создать уникальный slug" };
    return {
      error: "Не удалось сохранить bounty. Проверьте заполненные поля.",
    };
  }

  revalidatePath("/admin/bounties");
  revalidatePath("/bounties");
  redirect(`/admin/bounties/${data}?status=${action.toLowerCase()}`);
}
