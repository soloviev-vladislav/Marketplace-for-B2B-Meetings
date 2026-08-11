import { z } from "zod";
import { normalizeCompanyDomain, normalizeCompanyInn } from "@/lib/prospects/normalize";

const optionalUrl = z.union([z.literal(""), z.string().trim().url("Введите корректный URL")]);

export const prospectSchema = z.object({
  bounty_id: z.string().uuid("Некорректный bounty"),
  company_name: z.string().trim().min(2, "Укажите компанию").max(200),
  company_inn: z.string().trim().min(1, "Укажите корректный ИНН компании.").max(32),
  company_domain: z.string().trim().min(1, "Введите корректный domain").max(255),
  contact_name: z.string().trim().min(2, "Укажите имя контакта").max(160),
  contact_title: z.string().trim().min(2, "Укажите должность").max(160),
  contact_email: z.string().trim().email("Введите корректный email"),
  contact_phone: z.string().trim().max(80),
  contact_telegram: z.string().trim().max(80),
  source_url: optionalUrl,
}).superRefine((data, ctx) => {
  const inn = normalizeCompanyInn(data.company_inn);
  const domain = normalizeCompanyDomain(data.company_domain);
  if (!inn) {
    ctx.addIssue({ code: "custom", path: ["company_inn"], message: "Укажите корректный ИНН компании." });
  }
  if (!domain) {
    ctx.addIssue({ code: "custom", path: ["company_domain"], message: "Введите корректный domain" });
  }
});

export const reviewProspectSchema = z.object({
  prospect_id: z.string().uuid(),
  decision: z.enum(["APPROVED", "REJECTED"]),
  reason: z.string().trim(),
}).superRefine((data, ctx) => {
  if (data.decision === "REJECTED" && !data.reason) {
    ctx.addIssue({ code: "custom", path: ["reason"], message: "Укажите причину отклонения" });
  }
});
