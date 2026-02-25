import { Component, signal, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  template: `
    <div class="auth-wrapper">
      <div class="mesh-gradient"></div>
      <div class="orb orb-1"></div>
      <div class="orb orb-2"></div>
      
      <div class="auth-container">
        <div class="glass-card">
          <div class="brand">
            <span class="material-icons logo-icon">account_balance</span>
            <h1>Fintech GlobalTask</h1>
          </div>
          
          <div class="auth-header">
            <h2>¡Bienvenido de nuevo!</h2>
            <p>Ingresa tus credenciales para acceder a tu panel financiero.</p>
          </div>

          <form [formGroup]="loginForm" (ngSubmit)="onSubmit()" class="auth-form">
            <div class="form-field">
              <label for="email">Correo Electrónico</label>
              <div class="input-wrapper">
                <input id="email" type="email" formControlName="email" placeholder="nombre@ejemplo.com" autocomplete="email" />
                <span class="material-icons icon">mail_outline</span>
              </div>
            </div>

            <div class="form-field">
              <label for="password">Contraseña</label>
              <div class="input-wrapper">
                <input id="password" type="password" formControlName="password" placeholder="••••••••" autocomplete="current-password" />
                <span class="material-icons icon">lock_outline</span>
              </div>
            </div>

            @if (error()) {
              <div class="alert alert-error">
                <span class="material-icons alert-icon">report_problem</span>
                <span>{{ error() }}</span>
              </div>
            }

            <button type="submit" class="btn-login" [disabled]="loginForm.invalid || loading()">
              @if (loading()) {
                <span class="spinner"></span>
                <span>Procesando...</span>
              } @else {
                <span>Entrar a mi cuenta</span>
                <span class="btn-icon material-icons">arrow_forward</span>
              }
            </button>
          </form>

          <div class="auth-footer">
            <p>¿Aún no tienes una cuenta bancaria? <a routerLink="/register">Crea una ahora</a></p>
          </div>
        </div>
      </div>
    </div>
  `,
  styleUrl: './auth.component.css'
})
export class LoginComponent {
  private fb = inject(FormBuilder);
  private auth = inject(AuthService);
  private router = inject(Router);

  loginForm = this.fb.nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]]
  });

  error = signal('');
  loading = signal(false);

  onSubmit() {
    if (this.loginForm.invalid) return;

    this.loading.set(true);
    this.error.set('');

    const { email, password } = this.loginForm.getRawValue();

    this.auth.login(email, password).subscribe({
      next: () => this.router.navigate(['/applications']),
      error: (err) => {
        this.error.set(err.error?.error || 'Credenciales incorrectas. Por favor verifica tus datos.');
        this.loading.set(false);
      }
    });
  }
}
