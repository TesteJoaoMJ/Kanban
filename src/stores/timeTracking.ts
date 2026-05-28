import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { supabase } from '@/api/supabase';
import { format, lastDayOfMonth, eachDayOfInterval } from 'date-fns';
import { ptBR } from 'date-fns/locale';

export const useTimeTrackingStore = defineStore('timeTracking', () => {
  // ==========================================
  // 1. ESTADOS GLOBAIS E ENTIDADES BASE
  // ==========================================
  const isLoadingData = ref(false);
  const selectedMonth = ref(format(new Date(), 'yyyy-MM'));
  const selectedEmployeeId = ref<string | null>(null);

  const employees = ref<any[]>([]);
  const shiftTemplates = ref<any[]>([]);
  const assignments = ref<any[]>([]);
  const kiosks = ref<any[]>([]);
  const kioskUsers = ref<any[]>([]);
  const holidays = ref<any[]>([]);

  // Regras de negócio padrão carregadas do banco
  const legalRules = ref<any>({
    tolerance_minutes: 10,
    default_overtime_rate: 50,
    sunday_overtime_rate: 100,
    night_additional_rate: 20,
    reduced_night_hour: true,
    reduced_night_minutes: 52.5,
    monthly_minimum_wage_base: 1518,
    kiosk_cooldown_minutes: 5
  });

  // ==========================================
  // 2. ESTADOS DO DASHBOARD GLOBAL (VISÃO GERAL)
  // ==========================================
  const globalTodayList = ref<any[]>([]);

  // ==========================================
  // 3. ESTADOS DO COLABORADOR INDIVIDUAL
  // ==========================================
  const employeeOverrides = ref<any[]>([]);
  const overtimeRequests = ref<any[]>([]);
  const kioskReleases = ref<any[]>([]);
  const corrections = ref<any[]>([]);
  const manualPayrollEvents = ref<any[]>([]);
  const timeLogs = ref<Record<string, Record<string, any>>>({});
  const monthMirror = ref<any[]>([]); // O Espelho de Ponto Calculado

  // ==========================================
  // 4. GETTERS COMPUTADOS (DADOS DERIVADOS)
  // ==========================================

  // Retorna o funcionário atualmente selecionado com todos os dados resolvidos
  const selectedEmployeeResolved = computed(() => employees.value.find(e => e.id === selectedEmployeeId.value) || null);

  // Retorna o vínculo contratual (assignment) do funcionário selecionado
  const selectedAssignment = computed(() => assignments.value.find(a => a.employee_id === selectedEmployeeId.value) || { shift_template_id: '', manager: '', insalubrity_level: 0, hazard_pay: false });

  // Calcula a estatística de presenças e faltas do dia atual
  const globalTodayStats = computed(() => {
    let present = 0; let missing = 0;
    globalTodayList.value.forEach(e => {
      if(e.status === 'Presente') present++;
      if(e.status === 'Atrasado' || e.status === 'Falta') missing++;
    });
    return { present, missing };
  });

  // Filtra feriados para o mês atual
  const holidaysForMonth = computed(() => holidays.value.filter(h => h.date.startsWith(selectedMonth.value)));

  // ==========================================
  // 5. MÉTODOS AUXILIARES DE CÁLCULO DE TEMPO
  // ==========================================

  // Converte uma string 'HH:mm' para minutos totais desde a meia noite
  function timeToMinutes(t: string) {
    if(!t) return 0;
    const [h, m] = t.split(':').map(Number);
    return (h * 60) + m;
  }

  // Formata minutos totais para uma string 'HH:mm'
  function formatMinutes(min: number) {
    const s = Math.max(0, Math.round(min));
    return `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`;
  }

  // Adiciona sinal de positivo ou negativo na frente da formatação 'HH:mm'
  function signedMinutes(min: number) {
    if(min === 0) return '00:00';
    return `${min > 0 ? '+' : '-'}${formatMinutes(Math.abs(min))}`;
  }

  // Calcula a diferença em minutos entre duas strings de tempo, lidando com virada de noite
  function diffInMinutes(s: string, e: string) {
    let sm = timeToMinutes(s), em = timeToMinutes(e);
    if(em <= sm) em += 1440; // Soma 24 horas se o final for menor que o início (virou o dia)
    return Math.max(0, em - sm);
  }

  // Calcula o total de horas trabalhadas baseado num array de marcações (batidas ímpares = entradas, pares = saídas)
  function computeWorkedMinutes(punches: string[]) {
    let total = 0;
    for(let i = 0; i < punches.length; i += 2) {
      if(punches[i] && punches[i+1]) total += diffInMinutes(punches[i], punches[i+1]);
    }
    return total;
  }

  // Calcula especificamente quantos minutos ocorreram dentro da faixa de adicional noturno (ex: 22h às 05h)
  function computeNightMinutes(punches: string[]) {
    let total = 0;
    const ns = timeToMinutes(legalRules.value.night_start || '22:00');
    const ne = timeToMinutes(legalRules.value.night_end || '05:00') + 1440;
    for(let i = 0; i < punches.length; i += 2) {
      if(!punches[i] || !punches[i+1]) continue;
      let s = timeToMinutes(punches[i]), e = timeToMinutes(punches[i+1]);
      if(e <= s) e += 1440;
      total += Math.max(0, Math.min(e, 1440) - Math.max(s, ns));
      total += Math.max(0, Math.min(e, ne) - Math.max(s, 1440));
    }
    return total;
  }

  // Retorna a label visual de um turno (Ex: 08:00 -> 18:00)
  function scheduleLabel(day: any) {
    if(!day.active) return 'Folga';
    return `${(day.start_time || '').substring(0,5)} → ${(day.end_time || '').substring(0,5)}`;
  }

  // Calcula quantos minutos eram previstos pelo contrato naquele dia, descontando o horário de almoço
  function scheduleExpectedMinutes(day: any) {
    if(!day.active || !day.start_time || !day.end_time) return 0;
    const total = diffInMinutes(day.start_time, day.end_time);
    const inter = day.break_start && day.break_end ? diffInMinutes(day.break_start, day.break_end) : 0;
    return Math.max(0, total - inter);
  }

  // Verifica qual a regra efetiva do dia (se é o contrato padrão ou uma exceção/override)
  function getEffectiveSchedule(dateStr: string) {
    const override = employeeOverrides.value.find(o => o.date === dateStr);
    if (override) return { active: true, start_time: override.start_time, break_start: override.break_start, break_end: override.break_end, end_time: override.end_time };
    const tmplId = selectedAssignment.value?.shift_template_id;
    const template = shiftTemplates.value.find(t => t.id === tmplId) || shiftTemplates.value[0];
    if (!template || !template.days) return { active: false };
    const date = new Date(`${dateStr}T12:00:00`);
    return template.days.find((d: any) => d.weekday === date.getDay()) || { active: false };
  }

  // Retorna uma tag descrevendo a origem da regra do dia
  function resolveRuleLabel(dateStr: string, sched: any) {
    const override = employeeOverrides.value.find(o => o.date === dateStr);
    if(override) return 'Exceção Pontual';
    if(!sched.active) return 'Escala Inativa';
    return 'Regra Padrão';
  }

// ==========================================
  // 6. CÁLCULO DE FOLHA DE PAGAMENTO (COMPUTEDS)
  // ==========================================

  const payrollSummary = computed(() => {
    const emp = selectedEmployeeResolved.value;
    const ass = selectedAssignment.value;
    const salary = emp?.salary_base || 0;
    const divisor = emp?.hourly_divisor || 220;
    const hRate = divisor ? salary/divisor : 0;

    let regMin = 0, otMin = 0, nightMin = 0, missMin = 0, expectedMin = 0;
    let ot50Min = 0, ot100Min = 0; // Novos contadores separados

    monthMirror.value.forEach(r => {
      regMin += Math.min(r.workedMinutes, r.expectedMinutes);
      otMin += r.overtimeMinutes;
      ot50Min += r.overtime50 || 0;
      ot100Min += r.overtime100 || 0;
      nightMin += r.nightPaidMinutes;
      missMin += r.missingMinutes;
      expectedMin += r.expectedMinutes;
    });

    const ot50Val = (ot50Min / 60) * hRate * 1.5; // Regra 50%
    const ot100Val = (ot100Min / 60) * hRate * 2.0; // Regra 100% (Feriados/Domingos)
    const otVal = ot50Val + ot100Val; // Total financeiro das extras

    const nightVal = (nightMin / 60) * hRate * 0.2; // Regra base 20%
    const insalVal = legalRules.value.monthly_minimum_wage_base * ((ass?.insalubrity_level || 0) / 100);
    const hazVal = ass?.hazard_pay ? salary * 0.3 : 0;
    const gross = salary + otVal + nightVal + insalVal + hazVal;

    return {
      baseSalary: salary, grossValue: gross, overtimeValue: otVal,
      ot50Value: ot50Val, ot100Value: ot100Val, // Valores isolados
      nightValue: nightVal, riskValue: insalVal + hazVal,
      expectedHoursLabel: formatMinutes(expectedMin), regularHoursLabel: formatMinutes(regMin),
      overtimeHoursLabel: formatMinutes(otMin),
      overtime50Label: formatMinutes(ot50Min), overtime100Label: formatMinutes(ot100Min), // Labels isoladas
      nightHoursLabel: formatMinutes(nightMin), missingHoursLabel: formatMinutes(missMin),
      bankLabel: signedMinutes(otMin - missMin)
    };
  });

  const payrollRows = computed(() => {
    const s = payrollSummary.value;
    const autoRows = [
      { id: 'auto1', title: 'Salário Base Contratual', category: 'Provento', reference: 'Mês Completo', amount: s.baseSalary, automatic: true },
      { id: 'auto2', title: 'Horas Extras (50%)', category: 'Provento', reference: s.overtime50Label, amount: s.ot50Value, automatic: true },
      { id: 'auto2_1', title: 'Horas Extras (100%)', category: 'Provento', reference: s.overtime100Label, amount: s.ot100Value, automatic: true },
      { id: 'auto3', title: 'Adicional Noturno (20%)', category: 'Provento', reference: s.nightHoursLabel, amount: s.nightValue, automatic: true },
      { id: 'auto4', title: 'Insalubridade / Periculosidade', category: 'Provento', reference: 'Regra CLT', amount: s.riskValue, automatic: true }
    ].filter(i => i.amount > 0 || i.id === 'auto1');
    return [...autoRows, ...manualPayrollEvents.value];
  });

  // 7. AÇÕES E SINCRONIZAÇÃO COM O SUPABASE

function buildMirrorRow(dateStr: string) {
    const date = new Date(`${dateStr}T12:00:00`);
    const today = new Date();
    today.setHours(0,0,0,0);
    const isFuture = date > today;
    const holiday = holidays.value.find(h => h.date === dateStr);
    const schedule = getEffectiveSchedule(dateStr);
    const logData: any = timeLogs.value[selectedEmployeeId.value as string]?.[dateStr] || {};

    // CORREÇÃO: Força a montagem caso o array "punches" venha com tamanho zero (length === 0)
    let punches = logData.punches;
    if (!punches || !Array.isArray(punches) || punches.length === 0) {
       punches = [logData.in1, logData.out1, logData.in2, logData.out2].filter(p => !!p);
    }

    // LÓGICA DO 100%: Domingo ou Feriado
    const isSunday = date.getDay() === 0; // 0 é Domingo no JS
    const is100Percent = !!holiday || isSunday;

    // Se é domingo ou feriado, a meta de horas cravada é ZERO
    const expectedMinutes = is100Percent ? 0 : scheduleExpectedMinutes(schedule);

    // Agora o computeWorkedMinutes vai processar as horas corretamente!
    const workedMinutes = computeWorkedMinutes(punches);
    const nightMinutes = computeNightMinutes(punches);
    const nightPaidMinutes = legalRules.value.reduced_night_hour ? Math.round(nightMinutes * (60 / legalRules.value.reduced_night_minutes)) : nightMinutes;

    const tol = legalRules.value.tolerance_minutes;
    let diff = workedMinutes - expectedMinutes;
    if (Math.abs(diff) <= tol) diff = 0;

    let overtimeMinutes = isFuture ? 0 : Math.max(0, diff);
    let missingMinutes = isFuture ? 0 : Math.max(0, -diff);
    let balanceMinutes = isFuture ? 0 : diff;

    // SEPARADOR DE 50% E 100%
    let overtime50 = 0;
    let overtime100 = 0;

    if (overtimeMinutes > 0) {
      if (is100Percent) {
        overtime100 = overtimeMinutes; // Joga tudo para 100%
      } else {
        overtime50 = overtimeMinutes;  // Joga tudo para 50%
      }
    }

    let status = 'Regular';
    if (isFuture) status = 'Aguardando';
    else if (holiday) status = punches.length > 0 ? 'Feriado Trab.' : 'Feriado'; // Status correto!
    else if (!schedule.active && punches.length === 0) status = 'Folga';
    else if (punches.length === 0 && schedule.active) status = 'Falta';
    else if (punches.length % 2 !== 0) status = 'Incompleto';
    else if (overtimeMinutes > 0) status = 'Hora Extra';
    else if (missingMinutes > 0) status = 'Atraso';

    return {
      dateStr,
      label: format(date, 'dd/MM', { locale: ptBR }),
      weekday: format(date, 'EEE', { locale: ptBR }).substring(0,3),
      shiftLabel: holiday ? `Feriado: ${holiday.name}` : scheduleLabel(schedule),
      ruleLabel: resolveRuleLabel(dateStr, schedule),
      punches,
      in1: logData.in1 || punches[0] || '', out1: logData.out1 || punches[1] || '',
      in2: logData.in2 || punches[2] || '', out2: logData.out2 || punches[3] || '',
      statusTag: logData.statusTag || '',
      punch_photos: logData.punch_photos || [],
      expectedMinutes, workedMinutes, overtimeMinutes,
      overtime50, overtime100, // Variáveis vitais para o cockpit
      nightPaidMinutes, missingMinutes, balanceMinutes,
      status
    };
  }

  // Reprocessa toda a matriz do mês, acionado sempre que há mudanças na seleção de mês, folha, ou exceções
  function regenerateMonthMirror() {
    const employee = selectedEmployeeResolved.value;
    if (!employee) { monthMirror.value = []; return; }
    const [yearStr, monthStr] = selectedMonth.value.split('-');
    const startObj = new Date(Number(yearStr), Number(monthStr) - 1, 1);
    const endObj = lastDayOfMonth(startObj);
    const days = eachDayOfInterval({ start: startObj, end: endObj });
    monthMirror.value = days.map((date) => buildMirrorRow(format(date, 'yyyy-MM-dd')));
  }

  // Busca via API do Governo os feriados nacionais, e compila com os customizados do banco
  async function loadHolidaysWithBrasilApi() {
    const [year] = selectedMonth.value.split('-');
    try {
      const response = await fetch(`https://brasilapi.com.br/api/feriados/v1/${year}`);
      const national = await response.json();
      const apiHolidays = (national || []).map((h: any) => ({
        id: `nat-${h.date}`, name: h.name, date: h.date, isCustom: false, multiplier: 100
      }));

      const { data } = await supabase.from('time_tracking_holidays').select('*');
      const customHolidays = (data || []).map((h: any) => ({ ...h, isCustom: true }));

      holidays.value = [...apiHolidays, ...customHolidays].sort((a, b) => a.date.localeCompare(b.date));
    } catch (e) {
      console.error('Brasil API falhou', e);
    }
  }

  // Carrega as marcações em massa do dia de hoje para exibir no painel Global, processando quem faltou ou atrasou baseado no horário programado
  async function loadGlobalTodayData() {
    isLoadingData.value = true;
    const todayStr = format(new Date(), 'yyyy-MM-dd');
    try {
        const { data: logs } = await supabase.from('time_tracking_logs').select('employee_id, punches').eq('date', todayStr);
        const { data: overs } = await supabase.from('time_tracking_overrides').select('*').eq('date', todayStr);

        globalTodayList.value = employees.value.map(emp => {
            const empLog = logs?.find(l => l.employee_id === emp.id);
            const punches = empLog?.punches || [];
            const ass = assignments.value.find(a => a.employee_id === emp.id);
            const override = overs?.find(o => o.employee_id === emp.id);

            let schedLabel = 'Folga';
            let expectedStart = null;

            if (override) {
                schedLabel = `${override.start_time} as ${override.end_time}`;
                expectedStart = override.start_time;
            } else if (ass) {
                const tmpl = shiftTemplates.value.find(t => t.id === ass.shift_template_id);
                if (tmpl && tmpl.days) {
                    const d = new Date(`${todayStr}T12:00:00`);
                    const dayRule = tmpl.days.find((x:any) => x.weekday === d.getDay());
                    if (dayRule && dayRule.active) {
                        schedLabel = `${dayRule.start_time} as ${dayRule.end_time}`;
                        expectedStart = dayRule.start_time;
                    }
                }
            }

            let status = 'Sem Escala';

            if (expectedStart) {
                if (punches.length > 0) status = 'Presente';
                else {
                    const nowMin = new Date().getHours() * 60 + new Date().getMinutes();
                    const expMin = timeToMinutes(expectedStart) + (legalRules.value.tolerance_minutes || 10);
                    if (nowMin > expMin) status = 'Atrasado';
                    else status = 'Aguardando';
                }
            } else {
                if (punches.length > 0) status = 'Extra / Kiosk';
            }

            return {
                id: emp.id,
                nome: emp.nome,
                avatar_url: emp.avatar_url,
                role: emp.role,
                cargo: emp.cargo,
                punches,
                shiftLabel: schedLabel,
                status
            };
        });

    } catch(e:any) {
        console.error(e);
    } finally {
        isLoadingData.value = false;
    }
  }

  // Faz a raspagem granular para montar a matriz do mês individual
  async function fetchMonthDynamicData() {
    if (!selectedEmployeeId.value || !selectedMonth.value) return;
    isLoadingData.value = true;
    try {
      const [yearStr, monthStr] = selectedMonth.value.split('-');
      const startObj = new Date(Number(yearStr), Number(monthStr) - 1, 1);
      const start = format(startObj, 'yyyy-MM-dd');
      const end = format(lastDayOfMonth(startObj), 'yyyy-MM-dd');

      const { data: ov } = await supabase.from('time_tracking_overrides').select('*').eq('employee_id', selectedEmployeeId.value).gte('date', start).lte('date', end);
      employeeOverrides.value = ov || [];

      const { data: req } = await supabase.from('time_tracking_overtime_requests').select('*').eq('employee_id', selectedEmployeeId.value).gte('date', start).lte('date', end);
      overtimeRequests.value = req || [];

      const { data: kr } = await supabase.from('time_tracking_kiosk_releases').select('*').eq('employee_id', selectedEmployeeId.value).gte('date', start).lte('date', end);
      kioskReleases.value = kr || [];

      const { data: cor } = await supabase.from('time_tracking_corrections').select('*').eq('employee_id', selectedEmployeeId.value).gte('date', start).lte('date', end);
      corrections.value = cor || [];

      const { data: pe } = await supabase.from('time_tracking_payroll_events').select('*').eq('employee_id', selectedEmployeeId.value);
      manualPayrollEvents.value = pe || [];

      const { data: logs } = await supabase.from('time_tracking_logs').select('date, punches, in1, out1, in2, out2, status, punch_photos').eq('employee_id', selectedEmployeeId.value).gte('date', start).lte('date', end);
      if (!timeLogs.value[selectedEmployeeId.value]) timeLogs.value[selectedEmployeeId.value] = {};
      if (logs) {
        logs.forEach(l => {
          timeLogs.value[selectedEmployeeId.value as string][l.date] = {
             punches: l.punches || [l.in1, l.out1, l.in2, l.out2].filter(Boolean),
             in1: l.in1, out1: l.out1, in2: l.in2, out2: l.out2,
             statusTag: l.status,
             punch_photos: l.punch_photos || []
          };
        });
      }

      regenerateMonthMirror();
    } catch (e: any) {
      console.error(e);
    } finally {
      isLoadingData.value = false;
    }
  }

  // Carrega toda a base inicial
  async function loadAllData() {
    isLoadingData.value = true;
    try {
      const { data: emp } = await supabase.from('employees_mj').select('id, nome, avatar_url, role, cargo, cpf, rg, department, salary_base, hourly_divisor, face_descriptors, admission_date, status, company_id').eq('status', 'ativo').order('nome');
      if (emp) employees.value = emp;

      const { data: set } = await supabase.from('time_tracking_settings').select('*').limit(1).maybeSingle();
      if (set) legalRules.value = { ...legalRules.value, ...set };

      const { data: st } = await supabase.from('time_tracking_shift_templates').select('*');
      if (st) shiftTemplates.value = st;

      const { data: ass } = await supabase.from('time_tracking_assignments').select('*');
      if (ass) assignments.value = ass;

      try {
        const { data: kioskList, error: kError } = await supabase.from('time_tracking_kiosks').select('*, stores(name)').order('name');
        if (!kError && kioskList) kiosks.value = kioskList;

        const { data: kuList, error: kuError } = await supabase.from('time_tracking_kiosk_users').select('*');
        if (!kuError && kuList) kioskUsers.value = kuList;
      } catch(err) {
        console.warn("Tabelas de Kiosk ausentes. Pulando.");
      }

      await loadHolidaysWithBrasilApi();

      if (selectedEmployeeId.value) {
         await fetchMonthDynamicData();
      } else {
         await loadGlobalTodayData();
      }

    } catch (error: any) {
      console.error(error);
    } finally {
      isLoadingData.value = false;
    }
  }

  return {
    // States Globais
    isLoadingData, selectedMonth, selectedEmployeeId, employees, shiftTemplates, assignments,
    kiosks, kioskUsers, holidays, legalRules, globalTodayList,

    // States do Funcionário
    employeeOverrides, overtimeRequests, kioskReleases, corrections, manualPayrollEvents, timeLogs, monthMirror,

    // Getters / Computed
    selectedEmployeeResolved, selectedAssignment, globalTodayStats, holidaysForMonth, payrollSummary, payrollRows,

    // Actions Globais
    loadAllData, loadGlobalTodayData, loadHolidaysWithBrasilApi, fetchMonthDynamicData, regenerateMonthMirror
  };
});
