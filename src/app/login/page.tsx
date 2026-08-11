import { AuthForm } from "@/components/auth-form";
import { AuthShell } from "@/components/auth-shell";

export default async function LoginPage({ searchParams }: { searchParams: Promise<{ status?: string; error?: string }> }) {
  const params = await searchParams;
  const notice = params.status === "check-email"
    ? "Проверьте почту для подтверждения аккаунта"
    : undefined;
  const error = params.error === "invalid-callback"
    ? "Ссылка подтверждения недействительна или устарела"
    : params.error;

  return (
    <AuthShell title="Вход в аккаунт" description="Продолжите работу с B2B-встречами." notice={notice}>
      {error && <p role="alert" className="mb-5 rounded-lg bg-red-50 p-3 text-sm text-red-700">{error}</p>}
      <AuthForm mode="login" />
    </AuthShell>
  );
}
