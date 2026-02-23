import { Component, OnInit, signal, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { CreditApplicationService, CreditApplication } from '../../core/services/credit-application.service';
import { ActionCableService } from '../../core/services/action-cable.service';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-list',
  standalone: true,
  imports: [CommonModule, RouterLink, FormsModule],
  templateUrl: './list.component.html',
  styleUrl: './list.component.css',
  schemas: [CUSTOM_ELEMENTS_SCHEMA]
})
export class ListComponent implements OnInit {
  applications = signal<CreditApplication[]>([]);
  loading = signal(true);
  filterCountry = signal('');
  filterStatus = signal('');
  countries = signal<{ code: string, name: string }[]>([]);
  statuses = signal<{ code: string, name: string }[]>([]);

  constructor(
    private api: CreditApplicationService,
    private cable: ActionCableService,
    public auth: AuthService
  ) { }

  ngOnInit() {
    this.loadApplications();
    this.loadFilterOptions();
    this.cable.connect();

    // Escuchar actualizaciones en tiempo real
    this.cable.statusChanges.subscribe(update => {
      this.applications.update(apps =>
        apps.map(app => app.id === update.id ? {
          ...app,
          status: update.status,
          status_name: (update as any).status_name || app.status_name,
          updated_at: update.updated_at
        } : app)
      );
    });
  }

  loadApplications() {
    this.loading.set(true);
    this.api.getAll({ country: this.filterCountry(), status: this.filterStatus() }).subscribe({
      next: (res) => {
        this.applications.set(res.data);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }

  loadFilterOptions() {
    this.api.getCountries().subscribe(res => this.countries.set(res.data as any));
    this.api.getStatuses().subscribe(res => this.statuses.set(res.data));
  }

  onFilterChange() {
    this.loadApplications();
  }

  getStatusClass(status: string): string {
    const map: Record<string, string> = {
      'pending': 'status-pending',
      'approved': 'status-approved',
      'rejected': 'status-rejected',
      'manual_review': 'status-review',
      'under_review': 'status-review'
    };
    return map[status] || 'status-default';
  }

  formatCurrency(amount: number, currency = 'USD'): string {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency }).format(amount);
  }

  get pendingCount(): number {
    return this.applications().filter(a => a.status === 'pending').length;
  }

  get approvedCount(): number {
    return this.applications().filter(a => a.status === 'approved').length;
  }

  logout() {
    this.auth.logout();
  }
}
