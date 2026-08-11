export type BusinessStatus = "PENDING" | "VERIFIED" | "REJECTED" | "SUSPENDED";
export type BountyStatus =
  | "DRAFT"
  | "MODERATION"
  | "ACTIVE"
  | "PAUSED"
  | "COMPLETED"
  | "REJECTED"
  | "ARCHIVED";

export type Business = {
  id: string;
  legal_name: string;
  brand_name: string;
  inn: string;
  website: string;
  domain: string;
  description: string;
  verification_status: BusinessStatus;
  created_at: string;
};

export type MarketplaceBounty = {
  id: string;
  slug: string;
  title: string;
  summary: string;
  brand_name: string;
  reward_amount: number;
  meeting_limit: number;
  accepted_count: number;
  active_until: string;
  geography: string[];
  industries: string[];
  allowed_roles: string[];
  min_revenue: number;
  max_revenue: number | null;
  min_employees: number | null;
  max_employees: number | null;
};

export type BountyDetail = {
  bounty: {
    id: string;
    slug: string;
    title: string;
    summary: string;
    product_description: string;
    status: BountyStatus;
    is_expired: boolean;
    sales_website: string;
    reward_amount: number;
    platform_fee_amount: number;
    meeting_limit: number;
    accepted_count: number;
    active_until: string;
    minimum_duration_minutes: number;
    meeting_format: "ONLINE" | "OFFLINE" | "BOTH";
    existing_crm_rule: string;
    acceptance_notes: string;
  };
  business: {
    brand_name: string;
    website: string;
    domain: string;
    description: string;
  };
  icp: {
    geography: string[];
    industries: string[];
    excluded_industries: string[];
    min_revenue: number;
    max_revenue: number | null;
    min_employees: number | null;
    max_employees: number | null;
    allowed_roles: string[];
    hard_rules: string;
    soft_notes: string;
  };
  has_taken: boolean;
  materials: Array<{
    label: string;
    content: string | null;
    external_url: string | null;
    material_type: string;
  }>;
};

export type WorkspaceBounty = Pick<
  MarketplaceBounty,
  | "id"
  | "slug"
  | "title"
  | "brand_name"
  | "reward_amount"
  | "geography"
  | "industries"
  | "allowed_roles"
> & { status: BountyStatus; is_expired: boolean; taken_at: string };
