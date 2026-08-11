import { AuthForm } from "@/components/auth-form";
import { AuthShell } from "@/components/auth-shell";

export default function SignupPage() {
  return <AuthShell title="Создайте аккаунт" description="Выберите роль. Роль администратора назначается только вручную."><AuthForm mode="signup" /></AuthShell>;
}
