import { defineStore } from 'pinia';
import { supabase } from '@/api/supabase';

export type LowStockAlert = {
  id: number;
  fabricName: string;
  remainingStock: number;
};

export interface SnackbarState {
  show: boolean;
  text: string;
  color: 'success' | 'error' | 'info' | 'warning';
  timeout: number;
}

export interface DeliveryConfig {
  productionLeadTime: number;
  allowedDeliveryDays: number[];
}

export interface LowStockSettings {
  intervalValue: number;
  intervalUnit: 'seconds' | 'minutes' | 'hours';
  allowedCustomRoles: string[];
}

export const useAppStore = defineStore('app', {
  state: () => ({
    snackbar: {
      show: false,
      text: '',
      color: 'info',
      timeout: 4000,
    } as SnackbarState,

    deliveryConfig: {
      productionLeadTime: 4,
      allowedDeliveryDays: [2, 4, 6]
    } as DeliveryConfig,

    lowStockSettings: {
      intervalValue: 4,
      intervalUnit: 'hours',
      allowedCustomRoles: []
    } as LowStockSettings,

    consolidatedLowStockItems: [] as any[],
    showConsolidatedStockModal: false,
  }),

  actions: {
    async fetchGlobalConfigs() {
      try {
        const { data } = await supabase
          .from('app_config')
          .select('key, value')
          .in('key', ['delivery_settings', 'low_stock_settings']);

        if (data) {
          const delivery = data.find(d => d.key === 'delivery_settings');
          if (delivery?.value) {
            this.deliveryConfig = delivery.value;
          }

          const lowStock = data.find(d => d.key === 'low_stock_settings');
          if (lowStock?.value) {
              this.lowStockSettings = {
                intervalValue: 4,
                intervalUnit: 'hours',
                allowedCustomRoles: [],
                ...lowStock.value
              };
          }
        }
      } catch (err) {
        console.error("Erro configurações globais:", err);
      }
    },

    async fetchDeliveryConfig() {
      await this.fetchGlobalConfigs();
    },

    calculateForecastDate(baseDate: Date | string = new Date()): Date {
      let date = new Date(baseDate);
      const leadTime = Number(this.deliveryConfig?.productionLeadTime ?? 4);
      const allowedDays = (this.deliveryConfig?.allowedDeliveryDays?.length > 0
        ? this.deliveryConfig.allowedDeliveryDays
        : [2, 4, 6]).map(Number);

      date.setDate(date.getDate() + leadTime);

      let loopSafety = 0;
      while (!allowedDays.includes(date.getDay()) && loopSafety < 14) {
        date.setDate(date.getDate() + 1);
        loopSafety++;
      }

      return date;
    },

    isOrderDelayed(forecastDate: string | Date | null): boolean {
      if (!forecastDate) return false;
      const forecast = new Date(forecastDate);
      forecast.setHours(23, 59, 59, 999);
      return new Date() > forecast;
    },

    showConfirmationDialog(title: string, message: string, onConfirm: (confirmed: boolean) => void) {
      if (window.confirm(`${title}\n\n${message}`)) {
        onConfirm(true);
      } else {
        onConfirm(false);
      }
    },

    showSnackbar(text: string, color: SnackbarState['color'] = 'info', timeout = 4000) {
      this.snackbar.text = text;
      this.snackbar.color = color;
      this.snackbar.timeout = timeout;
      this.snackbar.show = true;
    },

    async broadcastSystemAnnouncement(message: string, minutes: number) {
      try {
        const { data: users, error: userError } = await supabase.from('profiles').select('id');
        if (userError || !users || users.length === 0) {
          return this.showSnackbar('Nenhum usuário encontrado.', 'warning');
        }

        const notifications = users.map(u => ({
          recipient_id: u.id,
          content: `📢 Aviso do Sistema::${message} (Início em ${minutes} minutos)`,
          redirect_url: null,
          is_read: false,
          created_at: new Date().toISOString()
        }));

        const { error: notifError } = await supabase.from('notifications').insert(notifications);
        if (notifError) throw notifError;

        this.showSnackbar(`Anúncio enviado para ${users.length} usuários.`, 'success');
      } catch (err: any) {
        this.showSnackbar('Falha ao enviar anúncio.', 'error');
        throw err;
      }
    },

    async checkConsolidatedLowStock(userProfile: any) {
      if (!userProfile) return;

      const isAdmin = userProfile.role === 'admin' || userProfile.role === 'super_admin';
      const hasSpecificPerm = userProfile.permissions?.includes('view_low_stock_alerts');
      const hasCustomRolePerm = this.lowStockSettings.allowedCustomRoles?.includes(userProfile.custom_role_id);

      if (!isAdmin && !hasSpecificPerm && !hasCustomRolePerm) return;

      const lastAlert = localStorage.getItem('last_consolidated_stock_alert');

      // MATEMÁTICA DE SEGUNDOS/MINUTOS/HORAS
      let multiplier = 1000; // base segundos
      if (this.lowStockSettings.intervalUnit === 'minutes') multiplier = 60 * 1000;
      if (this.lowStockSettings.intervalUnit === 'hours') multiplier = 60 * 60 * 1000;

      const intervalMs = (this.lowStockSettings.intervalValue || 4) * multiplier;

      if (lastAlert && (Date.now() - Number(lastAlert) < intervalMs)) return;

      try {
        const { data, error } = await supabase.rpc('get_low_stock_items');
        if (error) throw error;

        if (data && data.length > 0) {
            const validItems = data.filter((item: any) => Number(item.available_meters) < Number(item.low_stock_threshold));
            if (validItems.length > 0) {
                this.consolidatedLowStockItems = validItems;
                this.showConsolidatedStockModal = true;
                localStorage.setItem('last_consolidated_stock_alert', String(Date.now()));
            }
        }
      } catch (err) {
        console.error("Erro consolidado:", err);
      }
    },

    async triggerLowStockAlert(fabricName: string, remainingStock: number) {
       try {
         await supabase.from('stock').update({ last_alerted_at: new Date().toISOString() }).eq('fabric_type', fabricName);
       } catch (e) {}
    },
  },
});
