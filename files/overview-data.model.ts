export interface OverviewMetric {
  label: string;
  value: string;
}

export interface OverviewData {
  description: string;
  sensitivity: string;
  source: string;
  created: string;
  updated: string;
  metrics: OverviewMetric[];
}
