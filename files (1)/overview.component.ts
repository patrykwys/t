import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { MatIcon } from '@angular/material/icon';
import { MatTooltip } from '@angular/material/tooltip';

import { SensitivityEditComponent } from '../sensitivity-edit/sensitivity-edit.component'; // adjust path
import { TagsComponent } from '../tags/tags.component'; // adjust path
import { OverviewData } from './overview-data.model';

@Component({
  selector: 'app-overview',
  templateUrl: './overview.component.html',
  styleUrl: './overview.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [MatIcon, MatTooltip, SensitivityEditComponent, TagsComponent],
})
export class OverviewComponent {
  data = input.required<OverviewData>();
}
