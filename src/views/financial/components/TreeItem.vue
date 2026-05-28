<template>
  <div class="tree-node-wrapper">
    <v-list-item
      :value="node.id"
      min-height="40"
      class="px-2 py-1 mb-1 tree-item rounded-lg transition-all"
      :class="itemClasses"
      @click.stop="$emit('select', node)"
      density="compact"
      :ripple="!isGlass"
    >
      <template v-slot:prepend>
         <div class="d-flex align-center" :style="{ width: (node.level * 16) + 'px' }"></div>

         <v-btn
          v-if="hasChildren"
          icon size="20"
          variant="text"
          class="mr-1 hover-scale"
          :class="isGlass ? 'text-white-70' : 'text-medium-emphasis'"
          @click.stop="isOpen = !isOpen"
        >
          <v-icon size="18">{{ isOpen ? 'mdi-chevron-down' : 'mdi-chevron-right' }}</v-icon>
        </v-btn>
        <v-icon v-else size="6" class="mr-4 ml-2" :class="isGlass ? 'text-white-30' : 'text-disabled'">mdi-circle</v-icon>
      </template>

      <v-list-item-title class="text-caption font-weight-medium d-flex align-center">
         <span
            class="font-mono font-weight-bold mr-2 text-[11px] px-2 py-0.5 rounded"
            :class="codeBadgeClass"
         >
            {{ node.code }}
         </span>
         <span class="text-truncate text-body-2" :class="textClass">{{ node.name }}</span>
      </v-list-item-title>

      <template v-slot:append>
           <v-fade-transition>
             <v-btn
                v-if="isSelected && node.is_group"
                icon size="x-small"
                variant="flat"
                color="primary"
                class="ml-2 shadow-sm"
                title="Adicionar Subconta"
                @click.stop="$emit('add-child', node)"
              >
                <v-icon size="14">mdi-plus</v-icon>
              </v-btn>
           </v-fade-transition>
      </template>
    </v-list-item>

    <v-expand-transition>
      <div v-if="isOpen && hasChildren" class="pl-0">
          <TreeItem
            v-for="child in node.children"
            :key="child.id"
            :node="child"
            :active-id="activeId"
            :is-glass="isGlass"
            @select="(n) => $emit('select', n)"
            @add-child="(n) => $emit('add-child', n)"
          />
      </div>
    </v-expand-transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';

defineOptions({
  name: 'TreeItem'
});

const props = defineProps<{
  node: any;
  activeId: string | null;
  isGlass: boolean;
}>();

const emit = defineEmits(['select', 'add-child']);

const isOpen = ref(true);
const hasChildren = computed(() => props.node.children && props.node.children.length > 0);
const isSelected = computed(() => props.node.id === props.activeId);

// Computed Classes para Adaptação de Tema
const itemClasses = computed(() => {
    const classes = [];

    if (isSelected.value) {
        if (props.isGlass) {
            classes.push('active-node-glass');
        } else {
            classes.push('bg-primary-lighten-5 text-primary border-primary-lighten-4');
        }
    } else {
        if (!props.node.active) classes.push('opacity-60 grayscale');
        if (!props.isGlass) classes.push('hover:bg-grey-lighten-5');
    }

    return classes;
});

const codeBadgeClass = computed(() => {
    if (props.isGlass) return 'bg-primary-transparent text-primary';
    return isSelected.value ? 'bg-primary text-on-primary' : 'bg-grey-lighten-3 text-grey-darken-3';
});

const textClass = computed(() => {
    if (props.isGlass) return 'text-white';
    return isSelected.value ? 'text-primary font-weight-bold' : 'text-high-emphasis';
});
</script>

<style scoped>
.tree-item {
    transition: all 0.2s ease;
    border: 1px solid transparent;
}
.tree-item:hover {
    border-color: rgba(0,0,0,0.05);
}

/* Glass Mode Specifics */
.active-node-glass {
    background: rgba(var(--v-theme-primary), 0.15) !important;
    border-color: rgba(var(--v-theme-primary), 0.3) !important;
    box-shadow: 0 0 15px rgba(var(--v-theme-primary), 0.1);
}
.bg-primary-transparent { background: rgba(var(--v-theme-primary), 0.2); }
.text-white-70 { color: rgba(255,255,255,0.7); }
.text-white-30 { color: rgba(255,255,255,0.3); }

/* Standard Mode Specifics */
.grayscale { filter: grayscale(100%); }
.hover-scale:hover { transform: scale(1.2); }
.shadow-sm { box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
</style>
