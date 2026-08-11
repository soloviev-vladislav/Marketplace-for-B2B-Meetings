import { cache } from "react";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { roleDashboard, type Profile, type UserRole } from "@/lib/auth/types";

export const getSessionProfile = cache(async (): Promise<Profile | null> => {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;

  const { data, error } = await supabase
    .from("profiles")
    .select("id, role, display_name, email, status")
    .eq("id", user.id)
    .single();

  if (error || !data) return null;
  return data as Profile;
});

export async function requireRole(role: UserRole) {
  const profile = await getSessionProfile();
  if (!profile) redirect("/login");
  if (profile.status === "SUSPENDED") redirect("/login?error=Account+suspended");
  if (profile.role !== role) redirect(roleDashboard[profile.role]);
  return profile;
}
