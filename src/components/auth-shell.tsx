import { BriefcaseBusiness } from "lucide-react";

export function AuthShell({ title, description, children, notice }: { title: string; description: string; children: React.ReactNode; notice?: string }) {
  return (
    <main className="flex min-h-screen items-center justify-center px-4 py-12">
      <div className="w-full max-w-md">
        <div className="mb-8 flex items-center justify-center gap-2 text-sm font-semibold tracking-tight">
          <span className="flex size-9 items-center justify-center rounded-xl bg-slate-900 text-white"><BriefcaseBusiness size={18} /></span>
          MeetMarket
        </div>
        <section className="rounded-2xl border border-slate-200 bg-white p-7 shadow-sm sm:p-8">
          <h1 className="text-2xl font-semibold tracking-tight">{title}</h1>
          <p className="mt-2 mb-7 text-sm leading-6 text-slate-500">{description}</p>
          {notice && <p className="mb-5 rounded-lg bg-emerald-50 p-3 text-sm text-emerald-700">{notice}</p>}
          {children}
        </section>
      </div>
    </main>
  );
}
