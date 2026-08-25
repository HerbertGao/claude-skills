export type SummaryResult = {
  summary: unknown;
  confidence?: number;
  citations?: Array<{ page: number }>;
  language?: string;
  title?: string;
};

export function renderSummary(result: SummaryResult): string {
  if (
    typeof result.summary !== "string" ||
    result.summary.length === 0 ||
    result.summary.length > 100_000
  ) {
    throw new TypeError("summary is not displayable");
  }
  return result.summary;
}
