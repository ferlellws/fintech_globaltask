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

  // Paginación
  currentPage = signal(1);
  totalPages = signal(1);
  totalItems = signal(0);

  // Estadísticas Globales
  globalStats = signal({
    total: 0,
    pending: 0,
    approved: 0,
    rejected: 0,
    manual_review: 0,
    total_amount: 0
  });

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
      // Recargar aplicaciones de forma silenciosa (sin bloquear la UI)
      this.loadApplications(true);
    });
  }

  loadApplications(silent = false) {
    if (!silent) this.loading.set(true);
    this.api.getAll({
      country: this.filterCountry(),
      status: this.filterStatus(),
      page: this.currentPage()
    }).subscribe({
      next: (res) => {
        this.applications.set(res.data);
        this.totalPages.set(res.meta.pages);
        this.totalItems.set(res.meta.total);
        this.globalStats.set(res.meta.global_stats);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }

  changePage(page: number) {
    if (page < 1 || page > this.totalPages()) return;
    this.currentPage.set(page);
    this.loadApplications();
  }

  loadFilterOptions() {
    this.api.getCountries().subscribe(res => this.countries.set(res.data as any));
    this.api.getStatuses().subscribe(res => this.statuses.set(res.data));
  }

  onFilterChange() {
    this.currentPage.set(1);
    this.loadApplications();
  }

  getStatusClass(status: string): string {
    const map: Record<string, string> = {
      'pending': 'status-pending',
      'approved': 'status-approved',
      'rejected': 'status-rejected',
      'manual_review': 'status-review'
    };
    return map[status] || 'status-default';
  }

  formatCurrency(amount: number, currency = 'USD'): string {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency }).format(amount);
  }

  get totalCount(): number {
    return this.globalStats().total;
  }

  get pendingCount(): number {
    return this.globalStats().pending;
  }

  get approvedCount(): number {
    return this.globalStats().approved;
  }

  get rejectedCount(): number {
    return this.globalStats().rejected;
  }

  get manualReviewCount(): number {
    return this.globalStats().manual_review;
  }

  get totalAmountAmount(): number {
    return this.globalStats().total_amount;
  }

  logout() {
    this.auth.logout();
  }
}
