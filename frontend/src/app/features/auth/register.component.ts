import { Component, signal, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-register',
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
            <h2>Crea tu cuenta</h2>
            <p>Únete a nuestra plataforma financiera y gestiona tus créditos globalmente.</p>
          </div>

          <form [formGroup]="registerForm" (ngSubmit)="onSubmit()" class="auth-form">
            <div class="form-field">
              <label for="email">Correo Electrónico</label>
              <div class="input-wrapper">
                <input id="email" type="email" formControlName="email" placeholder="nombre@ejemplo.com" />
                <span class="material-icons icon">mail_outline</span>
              </div>
            </div>

            <div class="form-field">
              <label for="password">Contraseña</label>
              <div class="input-wrapper">
                <input id="password" type="password" formControlName="password" placeholder="Mín. 6 caracteres" />
                <span class="material-icons icon">lock_outline</span>
              </div>
            </div>

            <div class="form-field">
              <label for="password_confirmation">Confirmar Contraseña</label>
              <div class="input-wrapper">
                <input id="password_confirmation" type="password" formControlName="password_confirmation" placeholder="••••••••" />
                <span class="material-icons icon">verified_user</span>
              </div>
            </div>

            @if (error()) {
              <div class="alert alert-error">
                <span class="material-icons alert-icon">report_problem</span>
                <span>{{ error() }}</span>
              </div>
            }

            <button type="submit" class="btn-login" [disabled]="registerForm.invalid || loading()">
              @if (loading()) {
                <span class="spinner"></span>
                <span>Creando cuenta...</span>
              } @else {
                <span>Registrarme ahora</span>
                <span class="btn-icon material-icons">auto_awesome</span>
              }
            </button>
          </form>

          <div class="auth-footer">
            <p>¿Ya tienes una cuenta? <a routerLink="/login">Inicia sesión aquí</a></p>
          </div>
        </div>
      </div>
    </div>
  `,
  styleUrl: './auth.component.css'
})
export class RegisterComponent {
  private fb = inject(FormBuilder);
  private auth = inject(AuthService);
  private router = inject(Router);

  registerForm = this.fb.nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]],
    password_confirmation: ['', [Validators.required]]
  });

  error = signal('');
  loading = signal(false);

  onSubmit() {
    if (this.registerForm.invalid) return;

    const { email, password, password_confirmation } = this.registerForm.getRawValue();

    if (password !== password_confirmation) {
      this.error.set('Las contraseñas no coinciden');
      return;
    }

    this.loading.set(true);
    this.error.set('');

    this.auth.register(email, password, password_confirmation).subscribe({
      next: () => this.router.navigate(['/applications']),
      error: (err) => {
        this.error.set(
          Array.isArray(err.error?.error)
            ? err.error.error.join(', ')
            : err.error?.error || 'Error al crear la cuenta'
        );
        this.loading.set(false);
      }
    });
  }
}
