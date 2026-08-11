import { BriefcaseBusiness } from "lucide-react";
import { AppShell } from "@/components/app-shell";
import type { Profile } from "@/lib/auth/types";

const copy = {
  SDR: { eyebrow: "Рабочее пространство SDR", title: "Добро пожаловать", description: "Здесь появятся доступные задачи и ваши встречи в следующих спринтах." },
  BUSINESS: { eyebrow: "Кабинет бизнеса", title: "Добро пожаловать", description: "Здесь появятся кампании и результаты встреч в следующих спринтах." },
  ADMIN: { eyebrow: "Панель администратора", title: "Система готова к настройке", description: "Модерация и операционные инструменты будут добавлены в следующих спринтах." },
} as const;

export function DashboardShell({ profile }: { profile: Profile }) {
  const content = copy[profile.role];
  return (
    <AppShell profile={profile}>
      <div className="mx-auto max-w-6xl px-5 py-12">
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-500">{content.eyebrow}</p>
        <h1 className="mt-3 text-3xl font-semibold tracking-tight">{content.title}, {profile.display_name}</h1>
        <p className="mt-3 max-w-2xl text-slate-600">{content.description}</p>
        <section className="mt-10 rounded-2xl border border-dashed border-slate-300 bg-white p-12 text-center shadow-sm">
          <div className="mx-auto flex size-11 items-center justify-center rounded-xl bg-slate-100"><BriefcaseBusiness className="text-slate-600" size={20} /></div>
          <h2 className="mt-4 font-medium">Пока здесь пусто</h2>
          <p className="mx-auto mt-2 max-w-md text-sm leading-6 text-slate-500">Технический фундамент готов. Marketplace-функции намеренно не входят в Sprint 0.</p>
        </section>
      </div>
    </AppShell>
  );
}
