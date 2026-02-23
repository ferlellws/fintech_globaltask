import { Component, signal, inject, CUSTOM_ELEMENTS_SCHEMA, OnInit, DestroyRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { CreditApplicationService } from '../../core/services/credit-application.service';

@Component({
    selector: 'app-application-form',
    standalone: true,
    imports: [CommonModule, ReactiveFormsModule, RouterLink],
    templateUrl: './application-form.component.html',
    styleUrl: './application-form.component.css',
    schemas: [CUSTOM_ELEMENTS_SCHEMA]
})
export class ApplicationFormComponent implements OnInit {
    private fb = inject(FormBuilder);
    private api = inject(CreditApplicationService);
    private router = inject(Router);
    private destroyRef = inject(DestroyRef);

    countries = signal<{ code: string, name: string }[]>([]);

    applicationForm: FormGroup;

    loading = signal(false);
    error = signal('');
    success = signal('');

    constructor() {
        this.applicationForm = this.fb.group({
            country: ['', Validators.required],
            full_name: ['', Validators.required],
            identity_document: ['', Validators.required],
            requested_amount: ['', [Validators.required]],
            monthly_income: ['', [Validators.required]]
        });

        // Format currency fields automatically on value change
        this.applicationForm.get('requested_amount')?.valueChanges.pipe(
            takeUntilDestroyed()
        ).subscribe(val => {
            const formatted = this.formatCurrencyString(this.parseCurrencyString(String(val)));
            if (val !== formatted) {
                this.applicationForm.get('requested_amount')?.setValue(formatted, { emitEvent: false });
            }
        });

        this.applicationForm.get('monthly_income')?.valueChanges.pipe(
            takeUntilDestroyed()
        ).subscribe(val => {
            const formatted = this.formatCurrencyString(this.parseCurrencyString(String(val)));
            if (val !== formatted) {
                this.applicationForm.get('monthly_income')?.setValue(formatted, { emitEvent: false });
            }
        });
    }

    ngOnInit(): void {
        this.api.getCountries().subscribe((res: any) => {
            this.countries.set(res.data);
            if (res.data.length > 0) {
                this.applicationForm.patchValue({ country: res.data[0].code });
            }
        });
    }

    getCountryHelpText(): string {
        const countryCode = this.applicationForm.get('country')?.value;
        const map: Record<string, string> = {
            'ES': 'DNI (8 dígitos + 1 letra)',
            'PT': 'NIF (9 dígitos)',
            'IT': 'Codice Fiscale (16 alfanuméricos)',
            'MX': 'CURP (18 alfanuméricos)',
            'CO': 'Cédula de Ciudadanía (5 a 10 dígitos)',
            'BR': 'CPF (11 dígitos)'
        };
        return map[countryCode] || 'Documento Nacional de Identidad';
    }

    onSubmit() {
        if (this.applicationForm.invalid) return;

        this.loading.set(true);
        this.error.set('');
        this.success.set('');

        const rawData = this.applicationForm.getRawValue();
        const payload = {
            ...rawData,
            requested_amount: this.parseCurrencyString(String(rawData.requested_amount)),
            monthly_income: this.parseCurrencyString(String(rawData.monthly_income))
        };

        this.api.create(payload).subscribe({
            next: (res) => {
                this.success.set('Solicitud enviada correctamente. El sistema la evaluará en breve.');
                this.loading.set(false);
                setTimeout(() => this.router.navigate(['/applications']), 2000);
            },
            error: (err) => {
                this.error.set(
                    Array.isArray(err.error?.error)
                        ? err.error.error.join(', ')
                        : typeof err.error?.error === 'string'
                            ? err.error.error
                            : 'Ha ocurrido un error al procesar tu solicitud.'
                );
                this.loading.set(false);
            }
        });
    }

    // Helpers
    private formatCurrencyString(value: number): string {
        if (value === null || value === undefined || isNaN(value)) return '';
        if (value === 0) return ''; // Let 0 remain empty string for placeholder visibility
        return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }

    private parseCurrencyString(value: string): number {
        const parsed = parseInt(value.replace(/[^\d]/g, ''), 10);
        return isNaN(parsed) ? 0 : parsed;
    }
}
