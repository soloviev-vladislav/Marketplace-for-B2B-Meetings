"use client";

import { useActionState } from "react";
import { reviewProspect, type ReviewState } from "@/app/admin/prospects/actions";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";

export function ReviewForm({ prospectId }: { prospectId: string }) {
  const [state, action, pending] = useActionState(reviewProspect, undefined as ReviewState);
  return <form action={action} className="space-y-4"><input type="hidden" name="prospect_id" value={prospectId} /><div className="space-y-2"><Label htmlFor="reason">Причина отклонения</Label><Textarea id="reason" name="reason" placeholder="Обязательна только при отклонении" /></div>{state?.error && <p role="alert" className="rounded-lg bg-red-50 p-3 text-sm text-red-700">{state.error}</p>}<div className="flex flex-wrap gap-3"><Button name="decision" value="APPROVED" disabled={pending}>Approve</Button><Button name="decision" value="REJECTED" variant="outline" disabled={pending}>Reject</Button></div></form>;
}
