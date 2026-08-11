import { z } from "zod";
import { splitList } from "@/lib/marketplace/format";

const requiredText = (label: string, min = 2) => z.string().trim().min(min, `Заполните поле «${label}»`);
const optionalUrl = z.string().trim().url("Введите корректный URL");

export const businessSchema = z.object({
  legal_name: requiredText("Юридическое название"),
  brand_name: requiredText("Бренд"),
  inn: requiredText("ИНН"),
  website: optionalUrl,
  domain: requiredText("Домен"),
  description: z.string().trim(),
  verification_status: z.enum(["PENDING", "VERIFIED", "REJECTED", "SUSPENDED"]),
});

function rublesToKopecks(value: string) {
  const normalized = value.trim().replace(",", ".");
  if (!/^\d+(\.\d{1,2})?$/.test(normalized)) return Number.NaN;
  return Math.round(Number(normalized) * 100);
}

const list = (label: string) => z.string().transform(splitList).pipe(z.array(z.string()).min(1, `Заполните поле «${label}»`));
const optionalList = z.string().transform(splitList);
const optionalInteger = z.union([z.literal(""), z.coerce.number().int().nonnegative()]);

export const bountySchema = z.object({
  business_id: z.string().uuid(),
  title: requiredText("Название", 3).max(160),
  slug: z.string().trim(),
  summary: requiredText("Краткое описание", 10).max(500),
  reward_rubles: z.string().transform(rublesToKopecks).pipe(z.number().int().positive("Reward должен быть больше нуля")),
  platform_fee_rubles: z.string().transform(rublesToKopecks).pipe(z.number().int().nonnegative()),
  meeting_limit: z.coerce.number().int().positive(),
  active_until: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Укажите корректную дату"),
  geography: list("География"),
  industries: list("Индустрии"),
  excluded_industries: optionalList,
  min_revenue: z.coerce.number().int().nonnegative(),
  max_revenue: optionalInteger,
  min_employees: optionalInteger,
  max_employees: optionalInteger,
  allowed_roles: list("Роли принимающих решения"),
  excluded_company_inns: optionalList,
  hard_rules: z.string().trim(),
  soft_notes: z.string().trim(),
  product_description: requiredText("Описание продукта", 10),
  pains: z.string().trim(),
  value_propositions: z.string().trim(),
  sales_website: optionalUrl,
  outreach_notes: z.string().trim(),
  material_label: z.string().trim(),
  material_url: z.union([z.literal(""), optionalUrl]),
  minimum_duration_minutes: z.coerce.number().int().positive(),
  meeting_format: z.enum(["ONLINE", "OFFLINE", "BOTH"]),
  existing_crm_rule: requiredText("Правило existing CRM", 5),
  acceptance_notes: z.string().trim(),
}).superRefine((data, ctx) => {
  if (data.max_revenue !== "" && data.max_revenue < data.min_revenue) ctx.addIssue({ code: "custom", path: ["max_revenue"], message: "Максимум не может быть меньше минимума" });
  if (data.min_employees !== "" && data.max_employees !== "" && data.max_employees < data.min_employees) ctx.addIssue({ code: "custom", path: ["max_employees"], message: "Максимум не может быть меньше минимума" });
});
