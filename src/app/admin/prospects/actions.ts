"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { requireRole } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";
import { reviewProspectSchema } from "@/lib/validations/prospect";

export type ReviewState = { error?: string } | undefined;

export async function reviewProspect(_: ReviewState, formData: FormData): Promise<ReviewState> {
  await requireRole("ADMIN");
  const parsed = reviewProspectSchema.safeParse({
    prospect_id: formData.get("prospect_id"),
    decision: formData.get("decision"),
    reason: formData.get("reason"),
  });
  if (!parsed.success) return { error: parsed.error.issues[0]?.message };

  const supabase = await createClient();
  const { error } = await supabase.rpc("review_prospect", {
    target_prospect_id: parsed.data.prospect_id,
    decision: parsed.data.decision,
    reason: parsed.data.reason || null,
  });
  if (error) {
    if (error.message.includes("PROSPECT_ALREADY_REVIEWED")) {
      return { error: "Prospect уже рассмотрен. Обновите страницу." };
    }
    return { error: "Не удалось сохранить решение." };
  }

  revalidatePath("/admin/prospects");
  revalidatePath(`/admin/prospects/${parsed.data.prospect_id}`);
  redirect(`/admin/prospects/${parsed.data.prospect_id}?status=reviewed`);
}
