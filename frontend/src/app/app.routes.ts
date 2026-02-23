import { Routes } from '@angular/router';
import { LoginComponent } from './features/auth/login.component';
import { RegisterComponent } from './features/auth/register.component';
import { inject } from '@angular/core';
import { AuthService } from './core/services/auth.service';
import { Router } from '@angular/router';

const authGuard = () => {
    const auth = inject(AuthService);
    const router = inject(Router);
    return auth.isAuthenticated() ? true : router.createUrlTree(['/login']);
};

export const routes: Routes = [
    { path: '', redirectTo: 'applications', pathMatch: 'full' },
    { path: 'login', component: LoginComponent },
    { path: 'register', component: RegisterComponent },
    {
        path: 'applications',
        canActivate: [authGuard],
        children: [
            { path: '', loadComponent: () => import('./features/applications/list.component').then(m => m.ListComponent) },
            { path: 'new', loadComponent: () => import('./features/applications/application-form.component').then(m => m.ApplicationFormComponent) },
            { path: ':id', loadComponent: () => import('./features/applications/application-detail.component').then(m => m.ApplicationDetailComponent) }
        ]
    }
];
