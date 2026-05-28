<template>
  <div class="cajuia-sidebar d-flex flex-column gap-2 pa-2">
    <div class="d-flex justify-center mb-4 mt-2">
      <div class="icon-box-logo bg-gradient-primary elevation-5">
        <v-icon color="white" size="24">mdi-store</v-icon>
      </div>
    </div>

    <v-tooltip text="Dashboard" location="right">
      <template v-slot:activator="{ props }">
        <v-btn
          v-bind="props"
          icon
          to="/cajuia/dashboard"
          variant="text"
          :class="{ 'active-link': isActive('/cajuia/dashboard') }"
          class="sidebar-btn"
        >
          <v-icon>mdi-view-dashboard-outline</v-icon>
        </v-btn>
      </template>
    </v-tooltip>

    <v-tooltip text="PDV (Vendas)" location="right">
      <template v-slot:activator="{ props }">
        <v-btn
          v-bind="props"
          icon
          to="/cajuia/pdv"
          variant="text"
          :class="{ 'active-link': isActive('/cajuia/pdv') }"
          class="sidebar-btn"
        >
          <v-icon>mdi-point-of-sale</v-icon>
        </v-btn>
      </template>
    </v-tooltip>

    <v-tooltip text="Pedidos" location="right">
      <template v-slot:activator="{ props }">
        <v-btn
          v-bind="props"
          icon
          to="/cajuia/orders"
          variant="text"
          :class="{ 'active-link': isActive('/cajuia/orders') }"
          class="sidebar-btn"
        >
          <v-icon>mdi-file-document-outline</v-icon>
        </v-btn>
      </template>
    </v-tooltip>

    <v-tooltip text="Financeiro" location="right">
      <template v-slot:activator="{ props }">
        <v-btn
          v-bind="props"
          icon
          to="/cajuia/financial"
          variant="text"
          :class="{ 'active-link': isActive('/cajuia/financial') }"
          class="sidebar-btn"
        >
          <v-icon>mdi-cash-register</v-icon>
        </v-btn>
      </template>
    </v-tooltip>

    <v-tooltip text="Clientes" location="right">
        <template v-slot:activator="{ props }">
          <v-btn
            v-bind="props"
            icon
            to="/cajuia/clients"
            variant="text"
            :class="{ 'active-link': isActive('/cajuia/clients') }"
            class="sidebar-btn"
          >
            <v-icon>mdi-account-group-outline</v-icon>
          </v-btn>
        </template>
      </v-tooltip>

    <v-spacer></v-spacer>

    <v-btn icon variant="text" class="sidebar-btn mb-2 opacity-50">
      <v-icon>mdi-cog-outline</v-icon>
    </v-btn>
  </div>
</template>

<script setup lang="ts">
import { useRoute } from 'vue-router'
const route = useRoute()
const isActive = (path: string) => route.path === path
</script>

<style scoped lang="scss">
.cajuia-sidebar {
  width: 64px;
  height: 100%;
  background: rgba(30, 30, 35, 0.95);
  border-right: 1px solid rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(10px);
  position: fixed;
  left: 0;
  top: 0;
  z-index: 100;
}

.sidebar-btn {
  color: rgba(255, 255, 255, 0.5);
  border-radius: 12px;
  transition: all 0.2s;

  &:hover {
    background: rgba(255, 255, 255, 0.1);
    color: white;
  }
}

.active-link {
  background: rgba(var(--v-theme-primary), 0.15) !important;
  color: rgb(var(--v-theme-primary)) !important;
  box-shadow: 0 0 15px rgba(var(--v-theme-primary), 0.3);
}

.icon-box-logo {
  width: 40px; height: 40px;
  border-radius: 12px;
  display: flex; align-items: center; justify-content: center;
}
.bg-gradient-primary { background: linear-gradient(135deg, rgb(var(--v-theme-primary)), #1565c0); }
</style>
