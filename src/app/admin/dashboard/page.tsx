import { DashboardShell } from "@/components/dashboard-shell";
import { requireRole } from "@/lib/auth/session";
export default async function AdminDashboard() { return <DashboardShell profile={await requireRole("ADMIN")} />; }
