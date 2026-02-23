import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';

@Component({
    selector: 'app-login',
    standalone: true,
    imports: [CommonModule, FormsModule, RouterLink],
    template: `
    <div class="auth-container">
      <div class="auth-card">
        <h1>🏦 Fintech GlobalTask</h1>
        <h2>Iniciar Sesión</h2>

        <form (ngSubmit)="onSubmit()" #f="ngForm">
          <div class="field">
            <label for="email">Email</label>
            <input id="email" type="email" [(ngModel)]="email" name="email" required placeholder="usuario@email.com" />
          </div>
          <div class="field">
            <label for="password">Contraseña</label>
            <input id="password" type="password" [(ngModel)]="password" name="password" required placeholder="••••••••" />
          </div>

          @if (error()) {
            <div class="error-msg">{{ error() }}</div>
          }

          <button type="submit" [disabled]="loading()">
            {{ loading() ? 'Ingresando...' : 'Ingresar' }}
          </button>
        </form>

        <p>¿No tienes cuenta? <a routerLink="/register">Regístrate</a></p>
      </div>
    </div>
  `,
    styleUrl: './auth.component.css'
})
export class LoginComponent {
    email = '';
    password = '';
    error = signal('');
    loading = signal(false);

    constructor(private auth: AuthService, private router: Router) { }

    onSubmit() {
        this.loading.set(true);
        this.error.set('');
        this.auth.login(this.email, this.password).subscribe({
            next: () => this.router.navigate(['/applications']),
            error: (err) => {
                this.error.set(err.error?.error || 'Error al iniciar sesión');
                this.loading.set(false);
            }
        });
    }
}
