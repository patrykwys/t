import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { MatIconButton } from '@angular/material/button';
import { MatIcon } from '@angular/material/icon';
import { MatChipRow } from '@angular/material/chips';
import { NgOptimizedImage } from '@angular/common';

import { PanelHeaderData } from './panel-header-data.model';

@Component({
  selector: 'app-panel-header',
  templateUrl: './panel-header.component.html',
  styleUrl: './panel-header.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [NgOptimizedImage, MatIconButton, MatIcon, MatChipRow],
})
export class PanelHeaderComponent {
  data = input.required<PanelHeaderData>();

  closed = output<void>();
}
