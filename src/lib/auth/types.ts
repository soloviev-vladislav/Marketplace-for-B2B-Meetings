export const USER_ROLES = ["SDR", "BUSINESS", "ADMIN"] as const;
export type UserRole = (typeof USER_ROLES)[number];

export type Profile = {
  id: string;
  role: UserRole;
  display_name: string;
  email: string;
  status: "PENDING" | "ACTIVE" | "SUSPENDED";
};

export const roleDashboard: Record<UserRole, string> = {
  SDR: "/sdr/dashboard",
  BUSINESS: "/business/dashboard",
  ADMIN: "/admin/dashboard",
};
