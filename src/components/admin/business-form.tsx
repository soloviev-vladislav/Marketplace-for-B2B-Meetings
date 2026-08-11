"use client";

import { cloneElement, isValidElement, useActionState, type ReactElement } from "react";
import { saveBusiness, type FormState } from "@/app/admin/actions";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import type { Business } from "@/lib/marketplace/types";

export function BusinessForm({ business }: { business?: Business }) {
  const [state, action, pending] = useActionState(saveBusiness, undefined as FormState);
  return (
    <form action={action} className="space-y-6">
      {business && <input type="hidden" name="id" value={business.id} />}
      <div className="grid gap-5 sm:grid-cols-2">
        <Field label="Юридическое название"><Input name="legal_name" defaultValue={business?.legal_name} required /></Field>
        <Field label="Бренд"><Input name="brand_name" defaultValue={business?.brand_name} required /></Field>
        <Field label="ИНН"><Input name="inn" defaultValue={business?.inn} required /></Field>
        <Field label="Статус"><Select name="verification_status" defaultValue={business?.verification_status ?? "PENDING"}><option value="PENDING">PENDING</option><option value="VERIFIED">VERIFIED</option><option value="REJECTED">REJECTED</option><option value="SUSPENDED">SUSPENDED</option></Select></Field>
        <Field label="Website"><Input name="website" type="url" defaultValue={business?.website} placeholder="https://example.ru" required /></Field>
        <Field label="Домен"><Input name="domain" defaultValue={business?.domain} placeholder="example.ru" required /></Field>
      </div>
      <Field label="Описание"><Textarea name="description" defaultValue={business?.description} /></Field>
      {state?.error && <p role="alert" className="rounded-lg bg-red-50 p-3 text-sm text-red-700">{state.error}</p>}
      <Button disabled={pending}>{pending ? "Сохранение…" : "Сохранить бизнес"}</Button>
    </form>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  const control = isValidElement<{ id?: string; name?: string }>(children)
    ? children as ReactElement<{ id?: string; name?: string }>
    : null;
  const controlId = control?.props.id ?? control?.props.name;

  return <div className="space-y-2"><Label htmlFor={controlId}>{label}</Label>{control && controlId ? cloneElement(control, { id: controlId }) : children}</div>;
}
