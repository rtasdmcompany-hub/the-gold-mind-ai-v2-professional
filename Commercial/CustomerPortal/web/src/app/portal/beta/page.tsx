import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { StatusBadge } from "@/components/StatusBadge";
import {
  ENROLLMENT_STEPS,
  ENROLLMENT_STEP_LABELS,
  ensureDemoBetaParticipants,
  enrollmentCompletionPct,
  getParticipantByEmail,
} from "@/server/launch/beta-store";
import { actionAcceptBetaInvite, actionSelfEnrollmentStep } from "@/server/launch/actions";

export default async function BetaOnboardingPage() {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");
  const email = session.user.email.toLowerCase();

  ensureDemoBetaParticipants();
  const participant = getParticipantByEmail(email);

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Beta Onboarding</h1>
        <p className="page-sub">
          Invite-only enrollment for THE GOLD MIND Professional. Trading engine remains certified and frozen.
        </p>
      </header>

      {!participant && (
        <form action={actionAcceptBetaInvite} className="card">
          <h3>Accept invitation</h3>
          <p className="meta">Enter the invite code from your invitation email. It must match this account.</p>
          <div className="field">
            <label htmlFor="inviteCode">Invite code</label>
            <input id="inviteCode" name="inviteCode" required placeholder="GM-XXXXXXXX" />
          </div>
          <button type="submit" className="btn btn-primary">
            Accept invite
          </button>
        </form>
      )}

      {participant && (
        <>
          <div className="card" style={{ marginBottom: 16 }}>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 8, alignItems: "center" }}>
              <strong>{participant.name}</strong>
              <StatusBadge status={participant.status} />
              <span className="meta">
                {enrollmentCompletionPct(participant)}% complete · <code>{participant.inviteCode}</code>
              </span>
            </div>
            <p className="meta">
              Next: complete remaining steps · downloads: <Link href="/portal/downloads">Installer</Link> · licenses:{" "}
              <Link href="/portal/licenses">Activation</Link>
            </p>
          </div>

          <div className="stack">
            {ENROLLMENT_STEPS.map((step) => {
              const done = !!participant.enrollment[step];
              return (
                <div className="card" key={step}>
                  <div style={{ display: "flex", flexWrap: "wrap", gap: 8, alignItems: "center" }}>
                    <strong>{ENROLLMENT_STEP_LABELS[step]}</strong>
                    <StatusBadge status={done ? "completed" : "pending"} />
                  </div>
                  {!done && step !== "invitation" && (
                    <form action={actionSelfEnrollmentStep} style={{ marginTop: 8 }}>
                      <input type="hidden" name="step" value={step} />
                      <button type="submit" className="btn btn-primary">
                        Mark {ENROLLMENT_STEP_LABELS[step]} complete
                      </button>
                    </form>
                  )}
                  {done && <p className="meta">Completed {participant.enrollment[step]}</p>}
                </div>
              );
            })}
          </div>
        </>
      )}
    </>
  );
}
