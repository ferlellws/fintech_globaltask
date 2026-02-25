import { Component, OnInit, signal, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { CreditApplicationService, CreditApplication } from '../../core/services/credit-application.service';
import { ActionCableService } from '../../core/services/action-cable.service';

@Component({
    selector: 'app-application-detail',
    standalone: true,
    imports: [CommonModule, RouterLink],
    templateUrl: './application-detail.component.html',
    styleUrl: './application-detail.component.css',
    schemas: [CUSTOM_ELEMENTS_SCHEMA]
})
export class ApplicationDetailComponent implements OnInit {
    app = signal<CreditApplication | null>(null);
    loading = signal(true);
    error = signal('');
    updating = signal(false);

    constructor(
        private route: ActivatedRoute,
        private api: CreditApplicationService,
        private cable: ActionCableService
    ) { }

    ngOnInit() {
        const id = this.route.snapshot.paramMap.get('id');
        if (id) {
            this.loadApplication(id);

            this.cable.connect();
            this.cable.statusChanges.subscribe(update => {
                if (update.id.toString() === id) {
                    this.app.update(current => {
                        if (!current) return current;
                        return {
                            ...current,
                            status: update.status,
                            status_name: update.status_name || current.status_name,
                            updated_at: update.updated_at,
                            banking_information: update.banking_information || current.banking_information,
                            audit_logs: update.audit_logs || current.audit_logs
                        };
                    });
                }
            });
        } else {
            this.error.set('ID de aplicación no proporcionado');
            this.loading.set(false);
        }
    }

    loadApplication(id: string) {
        this.api.getById(Number(id)).subscribe({
            next: (res) => {
                this.app.set(res.data);
                this.loading.set(false);
            },
            error: (err) => {
                this.error.set('Error al cargar la solicitud');
                this.loading.set(false);
            }
        });
    }

    updateStatus(newStatus: string) {
        const id = this.app()?.id;
        if (!id) return;

        this.updating.set(true);
        this.api.updateStatus(id, newStatus).subscribe({
            next: (res) => {
                this.app.set(res.data);
                this.updating.set(false);
            },
            error: (err) => {
                console.error(err);
                this.updating.set(false);
            }
        });
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

    objectKeys(obj: any): string[] {
        return obj ? Object.keys(obj) : [];
    }
}
