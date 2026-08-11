import Link from "next/link";
import { BriefcaseBusiness, LogOut } from "lucide-react";
import { logout } from "@/app/auth/actions";
import { Button } from "@/components/ui/button";
import type { Profile } from "@/lib/auth/types";

const navigation = {
  SDR: [{ href: "/bounties", label: "Marketplace" }, { href: "/sdr/workspace", label: "Мои bounty" }],
  BUSINESS: [{ href: "/business/dashboard", label: "Dashboard" }],
  ADMIN: [
    { href: "/admin/dashboard", label: "Dashboard" },
    { href: "/admin/businesses", label: "Businesses" },
    { href: "/admin/bounties", label: "Bounties" },
    { href: "/bounties", label: "Marketplace" },
  ],
} as const;

export function AppShell({ profile, children }: { profile: Profile; children: React.ReactNode }) {
  return (
    <main className="min-h-screen">
      <header className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex min-h-16 max-w-6xl flex-wrap items-center justify-between gap-4 px-5 py-3">
          <div className="flex items-center gap-7">
            <Link href={profile.role === "SDR" ? "/bounties" : `/${profile.role.toLowerCase()}/dashboard`} className="flex items-center gap-2 font-semibold">
              <span className="flex size-8 items-center justify-center rounded-lg bg-slate-900 text-white"><BriefcaseBusiness size={16} /></span>MeetMarket
            </Link>
            <nav aria-label="Основная навигация" className="hidden items-center gap-1 md:flex">
              {navigation[profile.role].map((item) => <Link key={item.href} href={item.href} className="rounded-lg px-3 py-2 text-sm text-slate-600 hover:bg-slate-100 hover:text-slate-900">{item.label}</Link>)}
            </nav>
          </div>
          <div className="flex items-center gap-4">
            <div className="hidden text-right sm:block"><p className="text-sm font-medium">{profile.display_name}</p><p className="text-xs text-slate-500">{profile.email}</p></div>
            <form action={logout}><Button type="submit" size="sm" variant="outline"><LogOut size={15} /> Выйти</Button></form>
          </div>
          <nav aria-label="Мобильная навигация" className="flex w-full gap-1 overflow-x-auto md:hidden">
            {navigation[profile.role].map((item) => <Link key={item.href} href={item.href} className="whitespace-nowrap rounded-lg px-3 py-2 text-sm text-slate-600 hover:bg-slate-100">{item.label}</Link>)}
          </nav>
        </div>
      </header>
      {children}
    </main>
  );
}
