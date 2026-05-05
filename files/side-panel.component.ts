import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { MatIconButton } from '@angular/material/button';
import { MatIcon } from '@angular/material/icon';
import { NgOptimizedImage } from '@angular/common';

import { SidePanelData } from './side-panel-data.model';

@Component({
  selector: 'app-side-panel',
  templateUrl: './side-panel.component.html',
  styleUrl: './side-panel.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    NgOptimizedImage,
    MatIconButton,
    MatIcon,
    DatasourceBadgeComponent,
  ],
})
export class SidePanelComponent {
  data = input.required<SidePanelData>();

  closed = output<void>();
}
