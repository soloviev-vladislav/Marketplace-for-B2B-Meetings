import { AppShell } from "@/components/app-shell";
import { BusinessForm } from "@/components/admin/business-form";
import { PageHeading } from "@/components/page-heading";
import { requireRole } from "@/lib/auth/session";

export default async function NewBusinessPage() {
  const profile = await requireRole("ADMIN");
  return <AppShell profile={profile}><div className="mx-auto max-w-3xl px-5 py-10"><PageHeading eyebrow="Admin / Businesses" title="Новый бизнес" description="Создайте карточку заказчика и вручную установите verification status." /><section className="rounded-2xl border bg-white p-6 shadow-sm"><BusinessForm /></section></div></AppShell>;
}
