export type ProspectStatus = "PENDING" | "APPROVED" | "REJECTED" | "EXPIRED";

export type SdrProspect = {
  id: string;
  bounty_id: string;
  bounty_slug: string;
  bounty_title: string;
  company_name: string;
  company_inn: string | null;
  company_domain: string | null;
  contact_name: string;
  contact_title: string;
  contact_email: string;
  contact_phone: string | null;
  contact_telegram: string | null;
  source_url: string | null;
  status: ProspectStatus;
  rejection_reason: string | null;
  created_at: string;
  reviewed_at: string | null;
  ownership_expires_at: string;
};

export type AdminProspect = {
  id: string;
  bounty_id: string;
  sdr_profile_id: string;
  company_name: string;
  company_inn: string | null;
  company_domain: string | null;
  contact_name: string;
  contact_title: string;
  contact_email: string;
  contact_phone: string | null;
  contact_telegram: string | null;
  source_url: string | null;
  status: ProspectStatus;
  rejection_reason: string | null;
  created_at: string;
  reviewed_at: string | null;
  ownership_expires_at: string;
  bounties: { title: string; slug: string } | null;
  sdr: { display_name: string; email: string } | null;
};
