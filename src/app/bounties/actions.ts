"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";
import { requireRole } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";

const takeSchema = z.object({
  bountyId: z.string().uuid(),
  slug: z.string().regex(/^[a-z0-9-]+$/),
});

export async function takeBounty(formData: FormData) {
  await requireRole("SDR");
  const parsed = takeSchema.safeParse({ bountyId: formData.get("bountyId"), slug: formData.get("slug") });
  if (!parsed.success) redirect("/bounties?error=invalid-request");

  const supabase = await createClient();
  const { error } = await supabase.rpc("take_bounty", { target_bounty_id: parsed.data.bountyId });
  if (error) redirect("/bounties?error=not-active");

  revalidatePath(`/bounties/${parsed.data.slug}`);
  revalidatePath("/sdr/workspace");
  redirect(`/bounties/${parsed.data.slug}?status=taken`);
}
