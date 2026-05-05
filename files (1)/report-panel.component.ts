import { ChangeDetectionStrategy, Component, computed, inject, input, output } from '@angular/core';
import { MatTabGroup, MatTab, MatTabContent, MatTabLabel } from '@angular/material/tabs';

import { Report } from '../models/report.model'; // adjust path
import { CatalogStore } from '../store/catalog.store'; // adjust path
import { SidePanelComponent } from '../side-panel/side-panel.component';
import { PanelHeaderComponent } from '../panel-header/panel-header.component';
import { PanelHeaderData } from '../panel-header/panel-header-data.model';
import { ReportImageDirective } from '../directives/report-image.directive'; // adjust path
import { OverviewComponent } from '../overview/overview.component';
import { OverviewData } from '../overview/overview-data.model';

@Component({
  selector: 'app-report-panel',
  templateUrl: './report-panel.component.html',
  styleUrl: './report-panel.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    SidePanelComponent,
    PanelHeaderComponent,
    ReportImageDirective,
    MatTabGroup,
    MatTab,
    MatTabContent,
    MatTabLabel,
    OverviewComponent,
  ],
})
export class ReportPanelComponent {
  private readonly store = inject(CatalogStore);

  report = input.required<Report>();

  closed = output<void>();

  private static readonly SOURCE_CONFIGS: Record<string, { label: string; icon: string }> = {
    TABLEAU: { label: 'Tableau Report', icon: 'assets/tableau.png' },
    POWERBI: { label: 'PowerBI Report', icon: 'assets/powerbi.png' },
  };

  private static readonly DEFAULT_SOURCE_CONFIG = { label: 'Unknown Report', icon: 'assets/unknown.png' };

  headerData = computed<PanelHeaderData>(() => {
    const r = this.report();
    const type = r.type?.toUpperCase() ?? '';
    const source = Object.entries(ReportPanelComponent.SOURCE_CONFIGS).find(([key]) => type.includes(key));
    const { label, icon } = source ? source[1] : ReportPanelComponent.DEFAULT_SOURCE_CONFIG;

    return {
      name: r.name,
      ownerInitials: this.store.getOwnerInitials(r.owner?.name),
      ownerName: r.owner?.name ?? '',
      sourceIconSrc: icon,
      sourceLabel: label,
    };
  });

  overviewData = computed<OverviewData>(() => {
    const r = this.report();

    return {
      description: r.reportDescription,
      sensitivity: r.dataSensitivity,
      source: r.platformSource,
      created: r.createdDate,
      updated: r.lastModifiedDate,
      metrics: [
        { label: 'Views (30d)', value: r.viewCount?.toLocaleString() ?? '—' },
        { label: 'Unique Viewers', value: r.uniqueViewers?.toLocaleString() ?? '—' },
        { label: 'Avg Load Time', value: r.avgLoadTime ?? '—' },
        { label: 'Refresh Rate', value: r.refreshRate ?? '—' },
        { label: 'Connected Datasources', value: r.datasourceCount?.toLocaleString() ?? '—' },
        { label: 'Last Accessed', value: r.lastAccessedDate ?? '—' },
      ],
    };
  });
}
