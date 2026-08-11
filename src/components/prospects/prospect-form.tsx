"use client";

import { cloneElement, useActionState } from "react";
import { registerProspect, type ProspectFormState } from "@/app/sdr/prospects/actions";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

const emptyValues = {
  bounty_id: "", company_name: "", company_inn: "", company_domain: "",
  contact_name: "", contact_title: "", contact_email: "", contact_phone: "",
  contact_telegram: "", source_url: "",
};

export function ProspectForm({ bountyId }: { bountyId: string }) {
  const [state, action, pending] = useActionState(registerProspect, {
    values: { ...emptyValues, bounty_id: bountyId },
  } satisfies ProspectFormState);
  const value = (name: string) => state.values[name] ?? "";
  const error = (name: string) => state.fieldErrors?.[name]?.[0];

  return (
    <form action={action} className="space-y-7">
      <input type="hidden" name="bounty_id" value={bountyId} />
      <fieldset className="space-y-5">
        <legend className="text-lg font-semibold">Компания</legend>
        <Field id="company_name" label="Название компании" error={error("company_name")}><Input name="company_name" defaultValue={value("company_name")} required maxLength={200} /></Field>
        <div className="grid gap-5 sm:grid-cols-2">
          <Field id="company_inn" label="ИНН" hint="Обязательный российский ИНН из 10 или 12 цифр." error={error("company_inn")}><Input name="company_inn" inputMode="numeric" defaultValue={value("company_inn")} required maxLength={32} /></Field>
          <Field id="company_domain" label="Сайт / domain" hint="Обязателен; можно вставить полный HTTP(S) URL." error={error("company_domain")}><Input name="company_domain" defaultValue={value("company_domain")} placeholder="https://example.com/about" required maxLength={255} /></Field>
        </div>
      </fieldset>
      <fieldset className="space-y-5 border-t pt-7">
        <legend className="text-lg font-semibold">Контакт</legend>
        <div className="grid gap-5 sm:grid-cols-2">
          <Field id="contact_name" label="Имя" error={error("contact_name")}><Input name="contact_name" defaultValue={value("contact_name")} required maxLength={160} /></Field>
          <Field id="contact_title" label="Должность" error={error("contact_title")}><Input name="contact_title" defaultValue={value("contact_title")} required maxLength={160} /></Field>
          <Field id="contact_email" label="Корпоративный email" error={error("contact_email")}><Input name="contact_email" type="email" defaultValue={value("contact_email")} required /></Field>
          <Field id="contact_phone" label="Телефон — необязательно" error={error("contact_phone")}><Input name="contact_phone" type="tel" defaultValue={value("contact_phone")} maxLength={80} /></Field>
          <Field id="contact_telegram" label="Telegram — необязательно" error={error("contact_telegram")}><Input name="contact_telegram" defaultValue={value("contact_telegram")} placeholder="@username" maxLength={80} /></Field>
          <Field id="source_url" label="Source URL — необязательно" error={error("source_url")}><Input name="source_url" type="url" defaultValue={value("source_url")} placeholder="https://..." /></Field>
        </div>
      </fieldset>
      {state.error && <p role="alert" className="rounded-lg bg-red-50 p-4 text-sm text-red-700">{state.error}</p>}
      <Button disabled={pending}>{pending ? "Регистрация…" : "Зарегистрировать prospect"}</Button>
    </form>
  );
}

function Field({ id, label, hint, error, children }: { id: string; label: string; hint?: string; error?: string; children: React.ReactElement<{ id?: string; "aria-invalid"?: boolean; "aria-describedby"?: string }> }) {
  const control = cloneElement(children, { id, "aria-invalid": Boolean(error), "aria-describedby": error ? `${id}-error` : hint ? `${id}-hint` : undefined });
  return <div className="space-y-2"><Label htmlFor={id}>{label}</Label>{control}{hint && !error && <p id={`${id}-hint`} className="text-xs text-slate-500">{hint}</p>}{error && <p id={`${id}-error`} className="text-xs text-red-600">{error}</p>}</div>;
}
