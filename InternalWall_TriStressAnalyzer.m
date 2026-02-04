clc; clear; close all;

%% ===== 默认参数区 =====
params.p               = 100;      % 内压 MPa
params.Di              = 2;      % 内径 mm
params.Do              = 7;      % 外径 mm
params.R_real          = 0.1;     % 希望的真实轴向应力比
params.sz_max_real     = 200;     % 希望的真实轴向最大应力 MPa

% 绘图参数
plotParams.FontName    = 'Arial';
plotParams.FontSize    = 16;
plotParams.LineWidth   = 1.5;
plotParams.Language    = 'EN'; % 'EN' 或 'CN'

%% ===== 参数显示与交互 =====
disp('====== 当前默认参数 ======');
disp(params);

modify_flag = input('是否修改参数？(y/n): ', 's');

if strcmpi(modify_flag,'y')
    temp = input(sprintf('输入内压 p (MPa) [默认 %.2f]: ', params.p));
    if ~isempty(temp), params.p = temp; end
    temp = input(sprintf('输入内径 Di (mm) [默认 %.2f]: ', params.Di));
    if ~isempty(temp), params.Di = temp; end
    temp = input(sprintf('输入外径 Do (mm) [默认 %.2f]: ', params.Do));
    if ~isempty(temp), params.Do = temp; end
    temp = input(sprintf('输入希望的真实轴向应力比 R_real [默认 %.2f]: ', params.R_real));
    if ~isempty(temp), params.R_real = temp; end
    temp = input(sprintf('输入希望的真实轴向最大应力 sigma_z_max_real (MPa) [默认 %.2f]: ', params.sz_max_real));
    if ~isempty(temp), params.sz_max_real = temp; end
end

fprintf('\n使用参数：\n');
disp(params);

%% ===== 几何参数 =====
ri = params.Di/2;
ro = params.Do/2;

%% ===== 内压产生的静态三向应力（内壁） =====
sr = -params.p;
st = params.p*(ro^2 + ri^2)/(ro^2 - ri^2);
sz_static = params.p*ri^2/(ro^2 - ri^2);

%% ===== 真实应力范围 =====
sz_min_real = params.R_real * params.sz_max_real;

%% ===== 反推出试验机应施加载荷 =====
sz_app_max = params.sz_max_real - sz_static;
sz_app_min = sz_min_real - sz_static;

sz_app_mean = (sz_app_max + sz_app_min)/2;
sz_app_amp  = (sz_app_max - sz_app_min)/2;

fprintf('\n====== 试验机应施加的轴向应力范围 ======\n');
fprintf('sigma_app_max = %.2f MPa\n', sz_app_max);
fprintf('sigma_app_min = %.2f MPa\n', sz_app_min);
fprintf('=========================================\n\n');

%% ===== 一个循环 =====
theta = linspace(0,2*pi,400);
sz_app = sz_app_mean + sz_app_amp*sin(theta);

%% ===== 内壁真实轴向应力 =====
sz = sz_static + sz_app;

%% ===== 主应力 =====
s1 = st * ones(size(theta));
s2 = sz;
s3 = sr * ones(size(theta));

%% ===== 等效应力 & 三轴度 =====
sigma_v = sqrt(0.5*((s1-s2).^2 + (s2-s3).^2 + (s3-s1).^2));
sigma_m = (s1 + s2 + s3)/3;
triax = sigma_m ./ sigma_v;

%% ===== 绘图 =====

% 根据语言设置标签
if strcmpi(plotParams.Language,'EN')
    ylabel_left   = 'Stress (MPa)';
    ylabel_right  = 'Stress triaxiality \eta';
    xlabel_str    = 'Cycle phase (rad)';
    legend_str    = {'\sigma_\theta','\sigma_z (real)','\sigma_r','\sigma_v','\eta'};
    text_max      = '\sigma_v^{max}=%.1f MPa';
    text_min      = '\sigma_v^{min}=%.1f MPa';
else
    ylabel_left   = '应力 (MPa)';
    ylabel_right  = '应力三轴度 \eta';
    xlabel_str    = '循环相位 (rad)';
    legend_str    = {'\theta向应力','z向应力(真实)','径向应力','等效应力','三轴度'};
    text_max      = '\sigma_v^{最大}=%.1f MPa';
    text_min      = '\sigma_v^{最小}=%.1f MPa';
end

figure('Color','w','Position',[300 200 1050 650]);

% ===== 左轴：应力曲线 =====
yyaxis left
plot(theta, s1, 'LineWidth',plotParams.LineWidth); hold on;
plot(theta, s2, 'LineWidth',plotParams.LineWidth*1.2);
plot(theta, s3, 'LineWidth',plotParams.LineWidth);
plot(theta, sigma_v, 'k', 'LineWidth',plotParams.LineWidth*2);
ylabel(ylabel_left, 'FontSize',plotParams.FontSize,'FontName',plotParams.FontName);
ylim([min([s1 s2 s3 sigma_v])*1.1, max([s1 s2 s3 sigma_v])*1.1]);

% ===== 右轴：三轴度 =====
yyaxis right
plot(theta, triax, '--', 'LineWidth',plotParams.LineWidth*1.2);
ylabel(ylabel_right, 'FontSize',plotParams.FontSize,'FontName',plotParams.FontName);

% ===== 坐标轴和图例 =====
xlabel(xlabel_str, 'FontSize',plotParams.FontSize,'FontName',plotParams.FontName);
legend(legend_str, 'Location','best','FontSize',plotParams.FontSize,'FontName',plotParams.FontName);
grid on;

% ===== 统一控制坐标轴刻度字体 =====
ax = gca;
ax.FontName = plotParams.FontName;
ax.FontSize = plotParams.FontSize;


%% ===== 标注等效应力峰谷 =====
[sv_max, idx_max] = max(sigma_v);
[sv_min, idx_min] = min(sigma_v);


yyaxis left
plot(theta(idx_max), sv_max, 'ro','MarkerSize',9,'LineWidth',2, 'HandleVisibility','off');

% 文字偏移：x 方向 +0.02 rad，y 方向 + 2% 的最大值高度
x_offset = 0.0;                          % 右偏移量
y_offset = 0.15 * (max(sigma_v) - min(sigma_v));  % 上偏移量

text(theta(idx_max)+x_offset, sv_max+y_offset, ...
     sprintf('  \\sigma_v^{max}=%.1f MPa', sv_max), ...
     'FontSize',plotParams.FontSize,'FontName',plotParams.FontName,'Color','r');



plot(theta(idx_min), sv_min, 'bo','MarkerSize',9,'LineWidth',2, 'HandleVisibility','off');
text(theta(idx_min)+x_offset, sv_min-y_offset, sprintf('  \\sigma_v^{min}=%.1f MPa', sv_min), ...
     'FontSize',plotParams.FontSize,'FontName',plotParams.FontName);



%% ===== 等效应力峰谷与波形偏离分析 =====
[sv_max, idx_max] = max(sigma_v);
[sv_min, idx_min] = min(sigma_v);
theta_max = theta(idx_max);
theta_min = theta(idx_min);

amp_v = (sv_max - sv_min)/2;
mean_v = (sv_max + sv_min)/2;

fprintf('====== 等效应力分析 ======\n');
fprintf('峰值 σ_v_max = %.2f MPa at θ = %.2f rad\n', sv_max, theta_max);
fprintf('谷值 σ_v_min = %.2f MPa at θ = %.2f rad\n', sv_min, theta_min);
fprintf('循环幅值 Amp_v = %.2f MPa, 平均值 = %.2f MPa\n', amp_v, mean_v);
fprintf('峰谷幅值比 Amp_v / σ_v_max = %.3f\n', amp_v/sv_max);
fprintf('应力比 σ_v_min / σ_v_max = %.3f\n', sv_min/sv_max);

% 波形畸变系数 D
sigma_v_zero_mean = sigma_v - mean(sigma_v);
ft = fit(theta.', sigma_v_zero_mean.', 'sin1');
sigma_fit = ft.a1 * sin(ft.b1*theta + ft.c1);
residual = sigma_v_zero_mean - sigma_fit;
D = rms(residual)/rms(sigma_v_zero_mean);
fprintf('波形畸变系数 D = %.3f (RMS residual / RMS sigma_v)\n', D);
fprintf('============================\n');
