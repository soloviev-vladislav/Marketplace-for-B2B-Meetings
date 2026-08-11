"use client";

import Link from "next/link";
import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { login, signup, type AuthState } from "@/app/auth/actions";

const initialState: AuthState = undefined;

export function AuthForm({ mode }: { mode: "login" | "signup" }) {
  const isSignup = mode === "signup";
  const [state, action, pending] = useActionState(isSignup ? signup : login, initialState);

  return (
    <form action={action} className="space-y-5">
      {isSignup && (
        <div className="space-y-2">
          <Label htmlFor="displayName">Имя</Label>
          <Input id="displayName" name="displayName" autoComplete="name" required />
        </div>
      )}
      <div className="space-y-2">
        <Label htmlFor="email">Рабочий email</Label>
        <Input id="email" name="email" type="email" autoComplete="email" required />
      </div>
      <div className="space-y-2">
        <Label htmlFor="password">Пароль</Label>
        <Input id="password" name="password" type="password" minLength={8} autoComplete={isSignup ? "new-password" : "current-password"} required />
      </div>
      {isSignup && (
        <fieldset className="space-y-2">
          <legend className="text-sm font-medium text-slate-700">Роль</legend>
          <div className="grid grid-cols-2 gap-3">
            {[["SDR", "Я привожу встречи"], ["BUSINESS", "Я представляю бизнес"]].map(([value, label]) => (
              <label key={value} className="flex cursor-pointer items-center gap-2 rounded-lg border border-slate-200 p-3 text-sm has-[:checked]:border-slate-900 has-[:checked]:bg-slate-50">
                <input type="radio" name="role" value={value} defaultChecked={value === "SDR"} />
                {label}
              </label>
            ))}
          </div>
        </fieldset>
      )}
      {state?.error && <p role="alert" className="rounded-lg bg-red-50 p-3 text-sm text-red-700">{state.error}</p>}
      <Button className="w-full" disabled={pending}>{pending ? "Подождите…" : isSignup ? "Создать аккаунт" : "Войти"}</Button>
      <p className="text-center text-sm text-slate-500">
        {isSignup ? "Уже есть аккаунт? " : "Нет аккаунта? "}
        <Link className="font-medium text-slate-900 underline-offset-4 hover:underline" href={isSignup ? "/login" : "/signup"}>
          {isSignup ? "Войти" : "Зарегистрироваться"}
        </Link>
      </p>
    </form>
  );
}
