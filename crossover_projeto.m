%% UTFPR - CAMPUS PATO BRANCO
% Departamento Acadêmico de Engenharia da Computação
% Disciplina: Circuitos de Corrente Alternada - CC44CP
% Professor: Lucas Bernardo Zilch
%
% TRABALHO FINAL: PROJETO E ANÁLISE DE UM CROSSOVER PASSIVO DE 2 VIAS
% Aluno: Éricky Gomes Michels
%
% Descrição: O script dimensiona um crossover passivo de 2ª ordem com 
% aproximação de Butterworth para uma frequência de corte (fc) de 2 kHz e 
% carga de 8 Ohms. O algoritmo calcula os componentes ideais, mapeia-os para 
% valores comerciais disponíveis no mercado e plota as respectivas curvas 
% de magnitude (Diagramas de Bode) para os filtros Passa-Baixas e Passa-Altas.

clear; clc; close all;

%% ========================================================================
%% PARTE 1: DEFINIÇÃO DE PARÂMETROS E FILTRO PASSA-BAIXAS (WOOFER)
%% ========================================================================

% --- 1.1 Parâmetros Nominais de Entrada ---
R = 8;            % Resistência equivalente nominal dos alto-falantes (em Ohms)
fc = 2000;        % Frequência de corte do crossover (em Hertz)
wc = 2 * pi * fc; % Conversão da frequência de corte para radianos por segundo (rad/s)

fprintf('====================================================\n');
fprintf('       PROJETO DO CROSSOVER PASSIVO (2 kHz / 8 ohms) \n');
fprintf('====================================================\n\n');

% --- 1.2 Banco de Dados de Componentes Comerciais Disponíveis ---
% Vetores contendo os valores padrão de mercado para indutores (mH) e capacitores (uF)
L_comercial = [0.10, 0.12, 0.15, 0.18, 0.22, 0.27, 0.33, 0.39, 0.47, 0.56, ...
               0.68, 0.82, 1.0, 1.2, 1.5, 1.8, 2.2, 2.7, 3.3, 3.9, 4.7, 5.6, ...
               6.8, 8.2, 10, 12, 15] * 1e-3;

C_comercial = [1.0, 1.2, 1.5, 1.8, 2.2, 2.7, 3.3, 3.9, 4.7, 5.6, 6.8, 8.2, ...
               10, 12, 15, 18, 22, 27, 33, 39, 47, 56, 68, 82, 100] * 1e-6;

% --- 1.3 Dimensionamento Teórico (Filtros Butterworth de 2ª Ordem) ---
% As fórmulas utilizam o fator de amortecimento de Butterworth (zeta = 0.707)
L_ideal = R / (sqrt(2) * wc);    % Equação deduzida para o indutor ideal
C_ideal = sqrt(2) / (R * wc);    % Equação deduzida para o capacitor ideal

fprintf('--- VALORES IDEAIS CALCULADOS ---\n');
fprintf('Indutor Ideal (L): %.4f mH\n', L_ideal * 1e3);
fprintf('Capacitor Ideal (C): %.4f uF\n\n', C_ideal * 1e6);

% --- 1.4 Mapeamento Prático de Componentes (Aproximação de Mínimo Erro) ---
% O algoritmo varre os vetores comerciais e seleciona o índice de menor desvio absoluto
[~, idx_L] = min(abs(L_comercial - L_ideal));
L_real = L_comercial(idx_L);

[~, idx_C] = min(abs(C_comercial - C_ideal));
C_real = C_comercial(idx_C);

fprintf('--- COMPONENTES COMERCIAIS SELECIONADOS ---\n');
fprintf('Indutor Comercial: %.2f mH\n', L_real * 1e3);
fprintf('Capacitor Comercial: %.2f uF\n\n', C_real * 1e6);

% --- 1.5 Modelagem Matemática do Filtro Passa-Baixas (LPF) ---
% Expressão geral em (jw): H_LPF(jw) = 1 / [ (jw)^2 * LC + (jw) * (L/R) + 1 ]
% Dividindo por LC para isolar o termo quadrático:
% H_LPF(jw) = (1/LC) / [ (jw)^2 + (jw) * (R/L) + (1/LC) ]

% Modelagem LPF com Valores Ideais
num_LPF_ideal = [1 / (L_ideal * C_ideal)];
den_LPF_ideal = [1, (R/L_ideal), 1 / (L_ideal * C_ideal)]; 
sys_LPF_ideal = tf(num_LPF_ideal, den_LPF_ideal);

% Modelagem LPF com Valores Comerciais Reais
num_LPF_real = [1 / (L_real * C_real)];
den_LPF_real = [1, (R/L_real), 1 / (L_real * C_real)];     
sys_LPF_real = tf(num_LPF_real, den_LPF_real);

% --- 1.6 Configuração e Plotagem da Resposta do Woofer ---
figure('Name', 'Woofer - Passa-Baixas', 'NumberTitle', 'off');

w_vetor = 2 * pi * logspace(1, 5, 1000); % Vetor de frequências angulares (10 Hz a 100 kHz)
opts = bodeoptions; 
opts.FreqUnits = 'Hz';       % Altera o eixo horizontal de rad/s para Hertz (Hz)
opts.PhaseVisible = 'off';   % Oculta a curva de fase, priorizando a atenuação acústica (dB)
opts.Grid = 'on';            % Habilita as linhas de grade para facilitar a leitura de fc
opts.XLim = [10, 100000];    % Define a janela de frequências de áudio
opts.YLim = [-40, 5];        % Limita a escala vertical para focar na banda passante e rejeição

% Plotagem comparativa: Linha contínua azul (Ideal) vs Linha tracejada azul (Real)
bode(sys_LPF_ideal, 'k-', sys_LPF_real, 'b--', w_vetor, opts);
title('Resposta de Frequência - Woofer (Ideal vs. Comercial)');
legend('Woofer (LPF) - Ideal', 'Woofer (LPF) - Real', 'Location', 'SouthWest');

% Exportação da figura para documentação técnica
saveas(gcf, 'bode_crossover_real_vs_ideal.png');

%% ========================================================================
%% PARTE 2: FILTRO PASSA-ALTAS (TWEETER)
%% ========================================================================

fprintf('====================================================\n');
fprintf('       PROJETO DO FILTRO PASSA-ALTAS (TWEETER)      \n');
fprintf('====================================================\n\n');

% --- 2.1 Modelagem Matemática do Filtro Passa-Altas (HPF) ---
% Expressão geral deduzida do divisor de tensão no domínio (jw):
% H_HPF(jw) = (jw)^2 / [ (jw)^2 + (jw) * (R/L) + 1/LC ]
% No formato de polinômio para a função 'tf', os numeradores representam [1*(jw)^2 + 0*(jw)^1 + 0*(jw)^0]

% Modelagem HPF com Valores Ideais
num_HPF_ideal = [1, 0, 0];                                    
den_HPF_ideal = [1, (R / L_ideal), 1 / (L_ideal * C_ideal)]; 
sys_HPF_ideal = tf(num_HPF_ideal, den_HPF_ideal);

% Modelagem HPF com Valores Comerciais Reais
num_HPF_real = [1, 0, 0];
den_HPF_real = [1, (R / L_real), 1 / (L_real * C_real)];     
sys_HPF_real = tf(num_HPF_real, den_HPF_real);

% --- 2.2 Configuração e Plotagem da Resposta do Tweeter ---
figure('Name', 'Tweeter - Passa-Altas', 'NumberTitle', 'off');

% Plotagem comparativa usando os mesmos parâmetros de escala anteriores (opts)
% Linha contínua preta ('k-') garante excelente contraste para o filtro Ideal em fundos claros
% Linha tracejada verde ('g--') mapeia a resposta com componentes reais do mercado
bode(sys_HPF_ideal, 'k-', sys_HPF_real, 'g--', w_vetor, opts);
title('Resposta de Frequência - Tweeter (Ideal vs. Comercial)');
legend('Tweeter (HPF) - Ideal', 'Tweeter (HPF) - Real', 'Location', 'SouthWest');

% Exportação da figura final do Passa-Altas
saveas(gcf, 'bode_passa_altas_real_vs_ideal.png');
