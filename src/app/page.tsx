import { redirect } from "next/navigation";
import { getSessionProfile } from "@/lib/auth/session";
import { roleDashboard } from "@/lib/auth/types";

export default async function Home() {
  const profile = await getSessionProfile();
  redirect(profile ? roleDashboard[profile.role] : "/login");
}
