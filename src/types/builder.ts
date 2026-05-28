// ============================================================================
// ETAPA 2: MOTOR DE SCHEMA VISUAL (Tipagens rigorosas para o Headless Builder)
// Ficheiro: src/types/builder.ts
// ============================================================================

/**
 * 1. Tipagens do Catálogo PIM (Refletem as tabelas catalog_*)
 * Estas tipagens garantem que quando injetamos dados do catálogo numa secção,
 * o Storefront sabe exatamente o que está a receber.
 */
export interface CatalogCategory {
  id: string;
  slug: string;
  name: string;
  description: string | null;
  cover_image_url: string | null;
  is_active: boolean;
}

export interface CatalogMockup {
  id: string;
  name: string;
  base_image_url: string;
  mask_url: string | null;
  shadow_overlay_url: string | null;
  is_active: boolean;
}

export interface CatalogStamp {
  id: string;
  slug: string;
  ref_code: string;
  title: string;
  description: string | null;
  category_id: string | null;
  main_image_url: string;
  seamless_pattern_url: string | null;
  dominant_color: string | null;
  tags: string[];
  is_active: boolean;
  category?: CatalogCategory;
  mockups?: CatalogMockup[];
}

/**
 * 2. Blocos Internos (Elementos dentro de uma Secção)
 * Ex: Um botão dentro de um Banner, um Card de depoimento dentro de um Slider.
 */
export type BlockType = 'ButtonBlock' | 'ImageBlock' | 'TextBlock' | 'FeatureItemBlock';

export interface BaseBlock {
  id: string;
  type: BlockType;
}

export interface ButtonBlock extends BaseBlock {
  type: 'ButtonBlock';
  settings: {
    label: string;
    url: string;
    style: 'primary' | 'secondary' | 'outline' | 'ghost';
    open_in_new_tab: boolean;
  };
}

export interface TextBlock extends BaseBlock {
  type: 'TextBlock';
  settings: {
    content: string;
    html_tag: 'h1' | 'h2' | 'h3' | 'p' | 'span';
    alignment: 'left' | 'center' | 'right';
    color: string;
  };
}

export type BlockSchema = ButtonBlock | TextBlock; // Expansível no futuro

/**
 * 3. Secções do Motor Visual (Components raiz da página)
 * Cada secção corresponde a um Componente Vue real registado no Renderizador.
 */
export type SectionType =
  | 'HeroSection'
  | 'DynamicStampGrid'
  | 'EditorialMosaic'
  | 'CategoryShowcase'
  | 'NewsletterCapture'
  | 'RichText';

export interface BaseSection {
  id: string; // ID único gerado no Builder (ex: sec_1234abc)
  type: SectionType;
  is_hidden?: boolean; // Permite esconder a secção temporariamente
}

// Secção: Hero Banner (Pode ter vídeo, imagem e blocos de botão)
export interface HeroSection extends BaseSection {
  type: 'HeroSection';
  settings: {
    layout: 'full' | 'split' | 'boxed';
    background_image_url: string | null;
    background_video_url: string | null;
    overlay_opacity: number; // 0 a 1
    overlay_color: string;
    title: string;
    subtitle: string | null;
    text_color: string;
    height: 'small' | 'medium' | 'large' | 'viewport';
  };
  blocks: BlockSchema[];
}

// Secção: Grelha Dinâmica de Estampas (Consome o PIM)
export interface DynamicStampGrid extends BaseSection {
  type: 'DynamicStampGrid';
  settings: {
    title: string | null;
    data_source: 'latest' | 'trending' | `category:${string}`; // Query engine string
    limit: number;
    columns_desktop: number;
    columns_mobile: number;
    show_favorites_button: boolean;
    show_mockup_preview: boolean;
  };
  blocks: never[]; // Não possui blocos internos, apenas configurações
}

// Secção: Mosaico Editorial estilo Apple/Pinterest
export interface EditorialMosaic extends BaseSection {
  type: 'EditorialMosaic';
  settings: {
    title: string | null;
    gap_size: 'none' | 'small' | 'medium' | 'large';
    items: Array<{
      image_url: string;
      link_url: string | null;
      col_span: number; // 1 ou 2 para criar o efeito masonry manual
      row_span: number; // 1 ou 2
    }>;
  };
  blocks: never[];
}

export type SectionSchema = HeroSection | DynamicStampGrid | EditorialMosaic; // Expansível

/**
 * 4. Definições Globais da Página
 * Configurações que afetam a página inteira, geridas numa aba própria no Builder.
 */
export interface PageSettings {
  seo_title: string;
  seo_description: string;
  og_image: string | null;
  background_color: string;
  custom_css?: string; // Para injeção de CSS específico da página (governança avançada)
}

/**
 * 5. O SCHEMA RAIZ (O coração da tabela builder_page_versions)
 * É este objeto exato que é injetado no Vue.
 */
export interface PageSchema {
  settings: PageSettings;
  sections: SectionSchema[];
}

/**
 * 6. Entidades de Banco de Dados do Builder
 */
export interface BuilderPage {
  id: string;
  slug: string;
  title: string;
  page_type: 'standard' | 'stamp_template' | 'discover';
  created_at: string;
  updated_at: string;
}

export interface BuilderPageVersion {
  id: string;
  page_id: string;
  version_number: number;
  status: 'draft' | 'published' | 'archived';
  schema: PageSchema;
  created_at: string;
  published_at: string | null;
}
