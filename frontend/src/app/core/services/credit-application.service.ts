import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { environment } from '../../../environments/environment';
import { Observable } from 'rxjs';

export interface CreditApplication {
    id: number;
    country: string;
    country_name?: string;
    full_name: string;
    identity_document: string;
    requested_amount: number;
    monthly_income: number;
    application_date: string;
    status: string;
    status_name?: string;
    banking_information: Record<string, any>;
    created_at: string;
    updated_at: string;
    audit_logs?: {
        old_status: string;
        old_status_name?: string;
        new_status: string;
        new_status_name?: string;
        changed_at: string
    }[];
}

export interface ApplicationsResponse {
    data: CreditApplication[];
    meta: { total: number; page: number; per_page: number; pages: number };
}

export interface CreateApplicationDto {
    country: string;
    full_name: string;
    identity_document: string;
    requested_amount: number;
    monthly_income: number;
    application_date?: string;
}

@Injectable({ providedIn: 'root' })
export class CreditApplicationService {
    private baseUrl = `${environment.apiUrl}/credit_applications`;

    constructor(private http: HttpClient) { }

    getAll(filters: { country?: string; status?: string; page?: number } = {}): Observable<ApplicationsResponse> {
        let params = new HttpParams();
        if (filters.country) params = params.set('country', filters.country);
        if (filters.status) params = params.set('status', filters.status);
        if (filters.page) params = params.set('page', String(filters.page));
        return this.http.get<ApplicationsResponse>(this.baseUrl, { params });
    }

    getById(id: number): Observable<{ data: CreditApplication }> {
        return this.http.get<{ data: CreditApplication }>(`${this.baseUrl}/${id}`);
    }

    create(dto: CreateApplicationDto): Observable<{ data: CreditApplication; message: string }> {
        return this.http.post<{ data: CreditApplication; message: string }>(this.baseUrl, {
            credit_application: dto
        });
    }

    updateStatus(id: number, status: string): Observable<{ data: CreditApplication }> {
        return this.http.patch<{ data: CreditApplication }>(`${this.baseUrl}/${id}/update_status`, { status });
    }

    getCountries(): Observable<{ data: string[] }> {
        return this.http.get<{ data: string[] }>(`${this.baseUrl}/countries`);
    }

    getStatuses(): Observable<{ data: { code: string; name: string }[] }> {
        return this.http.get<{ data: { code: string; name: string }[] }>(`${this.baseUrl}/statuses`);
    }
}
