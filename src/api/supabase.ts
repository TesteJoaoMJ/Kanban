// src/api/supabase.ts
import { createClient, SupabaseClient } from '@supabase/supabase-js';

// As variáveis de ambiente são strings
const supabaseUrl: string = 'https://scxlrqdsnydvlnuadeln.supabase.co';
const supabaseAnonKey: string = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNjeGxycWRzbnlkdmxudWFkZWxuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk5NjMzMTYsImV4cCI6MjA5NTUzOTMxNn0.Pj6o2bwpG9NUXAUH0cErvSRXh3yh4YuqCuNzpt9M-_A';

// Exportamos o cliente Supabase, garantindo que ele tenha o tipo SupabaseClient
export const supabase: SupabaseClient = createClient(supabaseUrl, supabaseAnonKey);
