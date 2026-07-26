import { auth } from "@/auth";
import { redirect } from "next/navigation";
import {
  FEEDBACK_CATEGORY_LABELS,
  type FeedbackCategory,
} from "@/server/launch/feedback-store";
import { actionSubmitFeedback, actionSubmitStructuredFeedback } from "@/server/launch/actions";

function ScoreSelect({ id, name, label }: { id: string; name: string; label: string }) {
  return (
    <div className="field">
      <label htmlFor={id}>{label}</label>
      <select id={id} name={name} defaultValue="4">
        <option value="5">5 — Excellent</option>
        <option value="4">4 — Good</option>
        <option value="3">3 — OK</option>
        <option value="2">2 — Poor</option>
        <option value="1">1 — Very poor</option>
      </select>
    </div>
  );
}

export default async function CustomerFeedbackPage() {
  const session = await auth();
  if (!session?.user?.email) redirect("/login");

  return (
    <>
      <header style={{ marginBottom: 20 }}>
        <h1 className="page-title">Beta Feedback</h1>
        <p className="page-sub">
          Real feedback over assumptions. Bugs and feature requests are tracked separately. Core trading logic is not
          changed during beta.
        </p>
      </header>

      <form action={actionSubmitStructuredFeedback} className="card" style={{ marginBottom: 16 }}>
        <h3>Structured satisfaction survey</h3>
        <div className="stack" style={{ marginTop: 8 }}>
          <ScoreSelect id="installation" name="installation" label="Installation Experience" />
          <ScoreSelect id="uiux" name="uiux" label="UI / UX" />
          <ScoreSelect id="performance" name="performance" label="Performance" />
          <ScoreSelect id="documentation" name="documentation" label="Documentation" />
          <ScoreSelect id="supportQuality" name="supportQuality" label="Support Quality" />
          <ScoreSelect id="licenseExperience" name="licenseExperience" label="License Experience" />
          <ScoreSelect id="overallSatisfaction" name="overallSatisfaction" label="Overall Satisfaction" />
          <div className="field">
            <label htmlFor="detail">Comments</label>
            <textarea id="detail" name="detail" rows={3} />
          </div>
          <button type="submit" className="btn btn-primary">
            Submit survey
          </button>
        </div>
      </form>

      <form action={actionSubmitFeedback} className="card">
        <h3>Bug report or feature request</h3>
        <div className="stack" style={{ marginTop: 8 }}>
          <div className="field">
            <label htmlFor="category">Type</label>
            <select id="category" name="category" defaultValue="bug">
              <option value="bug">{FEEDBACK_CATEGORY_LABELS.bug}</option>
              <option value="feature">{FEEDBACK_CATEGORY_LABELS.feature}</option>
              {(Object.keys(FEEDBACK_CATEGORY_LABELS) as FeedbackCategory[])
                .filter((c) => !["bug", "feature", "structured"].includes(c))
                .map((c) => (
                  <option key={c} value={c}>
                    {FEEDBACK_CATEGORY_LABELS[c]}
                  </option>
                ))}
            </select>
          </div>
          <div className="field">
            <label htmlFor="title">Title</label>
            <input id="title" name="title" required maxLength={120} />
          </div>
          <div className="field">
            <label htmlFor="detail2">Details</label>
            <textarea id="detail2" name="detail" rows={5} required />
          </div>
          <div className="field">
            <label htmlFor="satisfactionScore">Overall satisfaction (optional)</label>
            <select id="satisfactionScore" name="satisfactionScore" defaultValue="4">
              <option value="5">5</option>
              <option value="4">4</option>
              <option value="3">3</option>
              <option value="2">2</option>
              <option value="1">1</option>
            </select>
          </div>
          <button type="submit" className="btn btn-primary">
            Submit
          </button>
        </div>
      </form>
    </>
  );
}
