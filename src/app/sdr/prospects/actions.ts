"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { requireRole } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";
import { prospectSchema } from "@/lib/validations/prospect";

export type ProspectFormValues = Record<string, string>;
export type ProspectFormState = {
  error?: string;
  fieldErrors?: Record<string, string[]>;
  values: ProspectFormValues;
};

const fields = [
  "bounty_id", "company_name", "company_inn", "company_domain", "contact_name",
  "contact_title", "contact_email", "contact_phone", "contact_telegram", "source_url",
] as const;

export async function registerProspect(
  previousState: ProspectFormState,
  formData: FormData,
): Promise<ProspectFormState> {
  await requireRole("SDR");
  const values = Object.fromEntries(fields.map((field) => [field, String(formData.get(field) ?? "")]));
  const parsed = prospectSchema.safeParse(values);
  if (!parsed.success) {
    return { values, fieldErrors: parsed.error.flatten().fieldErrors };
  }

  const supabase = await createClient();
  const { error } = await supabase.rpc("register_prospect", {
    target_bounty_id: parsed.data.bounty_id,
    payload: parsed.data,
  });
  if (error) {
    const messages: Record<string, string> = {
      PROSPECT_DUPLICATE: "Эта компания уже зарегистрирована в этом bounty.",
      COMPANY_NOT_ELIGIBLE: "Эта компания не подходит для данного bounty.",
      BOUNTY_NOT_TAKEN: "Сначала возьмите bounty в работу.",
      BOUNTY_NOT_AVAILABLE: "Bounty сейчас недоступен для новой работы.",
      COMPANY_INN_INVALID: "Укажите корректный ИНН компании.",
      COMPANY_DOMAIN_INVALID: "Введите корректный domain.",
      BOUNTY_QUOTA_REACHED: "Лимит встреч по этому bounty уже достигнут.",
      PROSPECT_ACTIVE_LIMIT_REACHED: "Достигнут лимит активных prospects по этому bounty.",
    };
    const safeError = Object.entries(messages).find(([code]) => error.message.includes(code))?.[1]
      ?? "Не удалось зарегистрировать prospect. Попробуйте ещё раз.";
    return { values, error: safeError };
  }

  revalidatePath("/sdr/prospects");
  revalidatePath("/sdr/workspace");
  redirect("/sdr/prospects?status=created");
}
