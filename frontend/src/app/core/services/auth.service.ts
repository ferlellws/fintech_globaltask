import { Injectable, signal, computed } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { tap } from 'rxjs/operators';
import { environment } from '../../../environments/environment';

export interface AuthUser {
    id: number;
    email: string;
}

export interface AuthResponse {
    auth_token: string;
    user: AuthUser;
}

@Injectable({ providedIn: 'root' })
export class AuthService {
    private readonly TOKEN_KEY = 'fintech_jwt';
    private _currentUser = signal<AuthUser | null>(null);

    currentUser = computed(() => this._currentUser());
    isAuthenticated = computed(() => !!this._currentUser());

    constructor(private http: HttpClient, private router: Router) {
        this.loadFromStorage();
    }

    login(email: string, password: string) {
        return this.http.post<AuthResponse>(`${environment.apiUrl}/auth/login`, { email, password }).pipe(
            tap(response => this.handleAuthResponse(response))
        );
    }

    register(email: string, password: string, passwordConfirmation: string) {
        return this.http.post<AuthResponse>(`${environment.apiUrl}/auth/register`, {
            email, password, password_confirmation: passwordConfirmation
        }).pipe(
            tap(response => this.handleAuthResponse(response))
        );
    }

    logout() {
        localStorage.removeItem(this.TOKEN_KEY);
        this._currentUser.set(null);
        this.router.navigate(['/login']);
    }

    getToken(): string | null {
        return localStorage.getItem(this.TOKEN_KEY);
    }

    private handleAuthResponse(response: AuthResponse) {
        localStorage.setItem(this.TOKEN_KEY, response.auth_token);
        this._currentUser.set(response.user);
    }

    private loadFromStorage() {
        const token = this.getToken();
        if (token) {
            try {
                const base64Url = token.split('.')[1];
                const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
                const jsonPayload = decodeURIComponent(window.atob(base64).split('').map(function (c) {
                    return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
                }).join(''));
                const payload = JSON.parse(jsonPayload);

                if (payload.exp * 1000 > Date.now()) {
                    this._currentUser.set({ id: payload.user_id, email: payload.email });
                } else {
                    this.logout();
                }
            } catch {
                localStorage.removeItem(this.TOKEN_KEY);
            }
        }
    }
}
