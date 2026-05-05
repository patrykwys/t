import { ChangeDetectionStrategy, Component, computed, inject, input, output } from '@angular/core';
import { NgOptimizedImage } from '@angular/common';
import { MatTabGroup, MatTab, MatTabContent, MatTabLabel } from '@angular/material/tabs';

import { Datasource } from '../models/datasource.model'; // adjust path
import { CatalogStore } from '../store/catalog.store'; // adjust path
import { SidePanelComponent } from '../side-panel/side-panel.component';
import { PanelHeaderComponent } from '../panel-header/panel-header.component';
import { PanelHeaderData } from '../panel-header/panel-header-data.model';
import { DatasourceBadgeComponent } from '../datasource-badge/datasource-badge.component'; // adjust path
import { OverviewComponent } from '../overview/overview.component';
import { OverviewData } from '../overview/overview-data.model';
import { ConnectedReportsComponent } from '../connected-reports/connected-reports.component';

@Component({
  selector: 'app-dspanel',
  templateUrl: './dspanel.component.html',
  styleUrl: './dspanel.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    NgOptimizedImage,
    SidePanelComponent,
    PanelHeaderComponent,
    DatasourceBadgeComponent,
    MatTabGroup,
    MatTab,
    MatTabContent,
    MatTabLabel,
    OverviewComponent,
    ConnectedReportsComponent,
  ],
})
export class DspanelComponent {
  private readonly store = inject(CatalogStore);

  datasource = input.required<Datasource>();

  closed = output<void>();

  private static readonly SOURCE_CONFIGS: Record<string, { label: string; icon: string }> = {
    TABLEAU: { label: 'Tableau Published', icon: 'assets/tableau.png' },
    POWERBI: { label: 'PowerBI Published', icon: 'assets/powerbi.png' },
  };

  private static readonly DEFAULT_SOURCE_CONFIG = { label: 'Unknown Source', icon: 'assets/unknown.png' };

  certifiedImageSrc = computed(() =>
    this.datasource().isCertified ? 'assets/certified.png' : 'assets/uncertified.png'
  );

  headerData = computed<PanelHeaderData>(() => {
    const ds = this.datasource();
    const type = ds.type?.toUpperCase() ?? '';
    const source = Object.entries(DspanelComponent.SOURCE_CONFIGS).find(([key]) => type.includes(key));
    const { label, icon } = source ? source[1] : DspanelComponent.DEFAULT_SOURCE_CONFIG;

    return {
      name: ds.name,
      ownerInitials: this.store.getOwnerInitials(ds.owner?.name),
      ownerName: ds.owner?.name ?? '',
      sourceIconSrc: icon,
      sourceLabel: label,
    };
  });

  overviewData = computed<OverviewData>(() => {
    const ds = this.datasource();

    return {
      description: ds.description,
      sensitivity: ds.sensitivity,
      source: ds.source,
      created: ds.created,
      updated: ds.updated,
      metrics: [
        { label: 'Row Count', value: ds.rowCount?.toLocaleString() ?? '—' },
        { label: 'Column Count', value: ds.columnCount?.toLocaleString() ?? '—' },
        { label: 'Refresh Rate', value: ds.refreshRate ?? '—' },
        { label: 'Size', value: ds.size ?? '—' },
      ],
    };
  });
}
