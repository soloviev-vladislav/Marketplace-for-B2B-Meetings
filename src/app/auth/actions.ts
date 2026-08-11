"use server";

import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { loginSchema, signupSchema } from "@/lib/validations/auth";
import { roleDashboard, type UserRole } from "@/lib/auth/types";

export type AuthState = { error?: string } | undefined;

export async function login(_: AuthState, formData: FormData): Promise<AuthState> {
  const parsed = loginSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { error: parsed.error.issues[0]?.message };

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword(parsed.data);
  if (error) return { error: "Неверный email или пароль" };

  const { data: { user } } = await supabase.auth.getUser();
  const { data: profile } = await supabase
    .from("profiles")
    .select("role, status")
    .eq("id", user!.id)
    .single();

  if (!profile) {
    await supabase.auth.signOut();
    return { error: "Профиль не найден. Обратитесь к администратору." };
  }
  if (profile.status === "SUSPENDED") {
    await supabase.auth.signOut();
    return { error: "Аккаунт приостановлен" };
  }

  redirect(roleDashboard[profile.role as UserRole]);
}

export async function signup(_: AuthState, formData: FormData): Promise<AuthState> {
  const parsed = signupSchema.safeParse({
    email: formData.get("email"),
    password: formData.get("password"),
    displayName: formData.get("displayName"),
    role: formData.get("role"),
  });
  if (!parsed.success) return { error: parsed.error.issues[0]?.message };

  const requestHeaders = await headers();
  const origin = requestHeaders.get("origin");
  const supabase = await createClient();
  const { data, error } = await supabase.auth.signUp({
    email: parsed.data.email,
    password: parsed.data.password,
    options: {
      data: { display_name: parsed.data.displayName, role: parsed.data.role },
      ...(origin ? { emailRedirectTo: `${origin}/auth/callback` } : {}),
    },
  });

  if (error) return { error: "Не удалось создать аккаунт. Возможно, email уже используется." };

  if (data.session) {
    redirect(roleDashboard[parsed.data.role]);
  }

  redirect("/login?status=check-email");
}

export async function logout() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}
