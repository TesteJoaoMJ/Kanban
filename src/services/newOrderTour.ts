// src/services/newOrderTour.ts

import Shepherd from 'shepherd.js';
import 'shepherd.js/dist/css/shepherd.css';
import '../styles/shepherd-theme.scss';

export function createNewOrderTour(isMobile: boolean = false) {
  const tour = new Shepherd.Tour({
    useModalOverlay: true,
    defaultStepOptions: {
      cancelIcon: {
        enabled: true,
      },
      classes: 'shepherd-mj-theme',
      scrollTo: { behavior: 'smooth', block: 'center' },
    },
  });

  const getButtons = (nextAction: () => void, backAction?: () => void) => {
    const buttons = [];
    if (backAction) {
      buttons.push({
        action: backAction,
        secondary: true,
        text: 'Voltar',
      });
    }
    buttons.push({
      action: nextAction,
      classes: 'shepherd-button-primary',
      text: 'Próximo',
    });
    return buttons;
  };

  tour.addStep({
    id: 'intro',
    title: '🚀 Tour: Criando um Novo Pedido',
    text: 'Olá! Vamos juntos aprender a criar um pedido de forma rápida e eficiente com o novo layout. Este guia mostrará as principais seções da tela.',
    buttons: getButtons(() => tour.next()),
  });

  tour.addStep({
    id: 'cliente',
    title: '1. O Cliente',
    text: 'O primeiro passo é sempre identificar o cliente. Comece a digitar para buscar na sua carteira ou clique no ícone <strong>"+"</strong> para cadastrar um novo cliente sem sair desta tela.',
    attachTo: {
      element: '#tour-client-card',
      on: isMobile ? 'top' : 'left',
    },
    buttons: getButtons(() => tour.next(), () => tour.back()),
  });

  tour.addStep({
    id: 'itens-card',
    title: '2. Itens do Pedido',
    text: 'Esta é a área principal, onde você irá montar o pedido. Ela é dividida entre a lista de itens adicionados (à esquerda) e o formulário para configurar um novo item (à direita).',
    attachTo: {
      element: '#tour-items-card',
      on: isMobile ? 'top' : 'right',
    },
    buttons: getButtons(() => tour.next(), () => tour.back()),
  });

   tour.addStep({
    id: 'item-list',
    title: 'Lista de Itens',
    text: 'Os itens que você configurar aparecerão aqui. Você pode clicar em qualquer um para editar ou remover.',
    attachTo: {
      element: '#tour-item-list-container',
      on: isMobile ? 'bottom' : 'right',
    },
    buttons: getButtons(() => tour.next(), () => tour.back()),
  });

  tour.addStep({
    id: 'item-form',
    title: 'Configurador de Itens',
    text: 'É neste formulário que a mágica acontece. Use os campos abaixo para detalhar cada produto do pedido.',
    attachTo: {
      element: '#tour-item-form-container',
      on: isMobile ? 'top' : 'left',
    },
    buttons: getButtons(() => tour.next(), () => tour.back()),
  });

  tour.addStep({
    id: 'product-stamp',
    title: 'Base e Estampa',
    text: 'Selecione o <strong>tecido (base)</strong> e a <strong>estampa</strong>. <br><br>🎨 <strong>Estampa Nova?</strong> Clique em <i>"Cadastrar Nova Estampa"</i> para fazer o upload do arquivo na hora. O sistema salva para vendas futuras!',
    attachTo: {
      element: '#tour-product-stamp-fields',
      on: 'bottom',
    },
    buttons: getButtons(() => tour.next(), () => tour.back()),
  });

  tour.addStep({
    id: 'quantity-stock',
    title: 'Quantidade e Estoque',
    text: 'Defina a quantidade desejada. A barra de progresso abaixo mostra o impacto no estoque em tempo real. <br><br>⚠️ <strong>Atenção:</strong> Se a barra ficar vermelha, o estoque ficará negativo e um alerta será gerado!',
    attachTo: {
      element: '#tour-quantity-field',
      on: 'bottom',
    },
    buttons: getButtons(() => tour.next(), () => tour.back()),
  });

  tour.addStep({
    id: 'add-to-list',
    title: 'Adicionar à Lista',
    text: 'Após preencher os detalhes, clique aqui para salvar o item. Ele aparecerá na lista à esquerda e você poderá configurar o próximo item.',
    attachTo: {
      element: '#tour-add-item-button',
      on: 'top',
    },
    buttons: getButtons(() => tour.next(), () => tour.back()),
  });

  tour.addStep({
    id: 'summary',
    title: '3. Pagamento e Resumo',
    text: 'Depois de adicionar todos os itens, use este card para definir as condições de pagamento, adicionar observações e gerar recibos.',
    attachTo: {
      element: '#tour-summary-card',
      on: isMobile ? 'top' : 'left',
    },
    buttons: getButtons(() => tour.next(), () => tour.back()),
  });

  tour.addStep({
    id: 'final-button',
    title: '🎉 Tudo Pronto!',
    text: 'Com o cliente selecionado e pelo menos um item na lista, este botão ficará ativo. Clique nele para salvar o pedido e enviá-lo para as próximas etapas. <br><br><strong>O tour termina aqui. Boas vendas!</strong>',
    attachTo: {
      element: '#tour-save-order-button',
      on: 'top',
    },
    buttons: [{
      action: () => tour.complete(),
      classes: 'shepherd-button-primary',
      text: 'Finalizar Tour',
    }],
  });

  return tour;
}
