import { Injectable, OnDestroy } from '@angular/core';
import { Subject } from 'rxjs';
import { environment } from '../../../environments/environment';
import { AuthService } from './auth.service';

export interface CableMessage {
    type: string;
    id: number;
    status: string;
    status_name?: string;
    country: string;
    full_name: string;
    updated_at: string;
    banking_information?: Record<string, any>;
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
            console.log('ActionCable connection opened');
            // Suscribirse al canal CreditApplicationChannel
            this.ws!.send(JSON.stringify({
                command: 'subscribe',
                identifier: JSON.stringify({ channel: 'CreditApplicationChannel' })
            }));
            console.log('ActionCable subscription sent');
        };

        this.ws.onmessage = (event) => {
            console.log('ActionCable received raw:', event.data);
            try {
                const data = JSON.parse(event.data);
                if (data.type === 'ping' || data.type === 'welcome' || data.type === 'confirm_subscription') return;
                console.log('ActionCable message parsed:', data);
                if (data.message?.type === 'status_changed' || data.message?.type === 'application_created') {
                    console.log('ActionCable trigger:', data.message.type, data.message);
                    this.statusChanges$.next(data.message as CableMessage);
                }
            } catch (err) {
                console.error('ActionCable parse error:', err);
            }
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
