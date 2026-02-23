import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';

@Component({
    selector: 'app-register',
    standalone: true,
    imports: [CommonModule, FormsModule, RouterLink],
    template: `
    <div class="auth-container">
      <div class="auth-card">
        <h1>🏦 Fintech GlobalTask</h1>
        <h2>Crear Cuenta</h2>

        <form (ngSubmit)="onSubmit()" #f="ngForm">
          <div class="field">
            <label for="email">Email</label>
            <input id="email" type="email" [(ngModel)]="email" name="email" required placeholder="usuario@email.com" />
          </div>
          <div class="field">
            <label for="password">Contraseña</label>
            <input id="password" type="password" [(ngModel)]="password" name="password" required placeholder="min. 6 caracteres" />
          </div>
          <div class="field">
            <label for="confirm">Confirmar contraseña</label>
            <input id="confirm" type="password" [(ngModel)]="passwordConfirm" name="confirm" required placeholder="••••••••" />
          </div>

          @if (error()) {
            <div class="error-msg">{{ error() }}</div>
          }

          <button type="submit" [disabled]="loading()">
            {{ loading() ? 'Registrando...' : 'Registrarse' }}
          </button>
        </form>

        <p>¿Ya tienes cuenta? <a routerLink="/login">Inicia sesión</a></p>
      </div>
    </div>
  `,
    styleUrl: './auth.component.css'
})
export class RegisterComponent {
    email = '';
    password = '';
    passwordConfirm = '';
    error = signal('');
    loading = signal(false);

    constructor(private auth: AuthService, private router: Router) { }

    onSubmit() {
        if (this.password !== this.passwordConfirm) {
            this.error.set('Las contraseñas no coinciden');
            return;
        }
        this.loading.set(true);
        this.error.set('');
        this.auth.register(this.email, this.password, this.passwordConfirm).subscribe({
            next: () => this.router.navigate(['/applications']),
            error: (err) => {
                this.error.set(err.error?.error?.join(', ') || 'Error al registrar');
                this.loading.set(false);
            }
        });
    }
}
