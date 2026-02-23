import { Injectable, OnDestroy } from '@angular/core';
import { Subject } from 'rxjs';
import { environment } from '../../../environments/environment';
import { AuthService } from './auth.service';

export interface CableMessage {
    type: string;
    id: number;
    status: string;
    country: string;
    full_name: string;
    updated_at: string;
    audit_logs?: any[];
}

@Injectable({ providedIn: 'root' })
export class ActionCableService implements OnDestroy {
    private ws: WebSocket | null = null;
    private statusChanges$ = new Subject<CableMessage>();

    statusChanges = this.statusChanges$.asObservable();

    constructor(private auth: AuthService) { }

    connect(): void {
        if (this.ws) return;

        const token = this.auth.getToken();
        const url = `${environment.wsUrl}?token=${token}`;

        this.ws = new WebSocket(url);

        this.ws.onopen = () => {
            // Suscribirse al canal CreditApplicationChannel
            this.ws!.send(JSON.stringify({
                command: 'subscribe',
                identifier: JSON.stringify({ channel: 'CreditApplicationChannel' })
            }));
        };

        this.ws.onmessage = (event) => {
            try {
                const data = JSON.parse(event.data);
                if (data.type === 'ping' || data.type === 'welcome' || data.type === 'confirm_subscription') return;
                if (data.message?.type === 'status_changed') {
                    this.statusChanges$.next(data.message as CableMessage);
                }
            } catch { }
        };

        this.ws.onerror = (err) => console.error('ActionCable error:', err);
        this.ws.onclose = () => { this.ws = null; };
    }

    disconnect(): void {
        this.ws?.close();
        this.ws = null;
    }

    ngOnDestroy(): void {
        this.disconnect();
        this.statusChanges$.complete();
    }
}
