clc; clear; close all;

%% ===== 默认参数区 =====
params.p       = 90;    % 内压 MPa
params.Di      = 2;     % 内径 mm
params.Do      = 7;     % 外径 mm
params.sz_max_real = 300; % 最大轴向应力 MPa
params.R_real  = 0.3;   % 轴向应力比

% 绘图参数（统一字体、字号、线宽）
plotParams.FontName    = 'Arial';
plotParams.FontSize    = 16;
plotParams.LineWidth   = 1.5;
plotParams.MarkerSize  = 8;
plotParams.Language    = 'EN'; % 'EN' 或 'CN'
plotParams.GridAlpha   = 0.3;

%% ===== 选择扫描变量 =====
fprintf('可扫描变量：\n1: 内压 p\n2: 内径 Di\n3: 外径 Do\n4: 最大轴向应力 sz_max_real\n5: 真实应力比 R_real\n');
scan_var_idx = input('选择扫描变量（输入数字 1-5, 默认 5 R_real）: ');
if isempty(scan_var_idx), scan_var_idx = 5; end

var_names = {'p','Di','Do','sz_max_real','R_real'};
scan_var_name = var_names{scan_var_idx};

% 默认扫描范围
default_ranges = {
    [4 150 4],   % p
    [1 5 0.5],     % Di
    [4 10 0.5],    % Do
    [100 500 20],  % sz_max_real
    [0.0 0.5 0.05]   % R_real
};
fprintf('默认扫描范围: [%g, %g, %g] (start, end, step)\n', default_ranges{scan_var_idx});
range_input = input('输入扫描范围 [start end step] 或回车使用默认: ');

if isempty(range_input)
    scan_vec = default_ranges{scan_var_idx}(1):default_ranges{scan_var_idx}(3):default_ranges{scan_var_idx}(2);
else
    scan_vec = range_input(1):range_input(3):range_input(2);
end

%% ===== 内壁几何参数函数 =====
compute_static_stress = @(p, ri, ro) deal(...
    -p,... % sr
    p*(ro^2 + ri^2)/(ro^2 - ri^2),... % st
    p*ri^2/(ro^2 - ri^2)... % sz_static
    );

theta = linspace(0,2*pi,400);

%% ===== 结果存储 =====
sigma_v_max_vec   = zeros(size(scan_vec));
sigma_v_min_vec   = zeros(size(scan_vec));
sigma_app_max_vec = zeros(size(scan_vec));
sigma_app_min_vec = zeros(size(scan_vec));
D_vec             = zeros(size(scan_vec));

%% ===== 扫描计算 =====
for i = 1:length(scan_vec)
    
    % 当前扫描变量
    switch scan_var_name
        case 'p', p_cur = scan_vec(i); Di_cur = params.Di; Do_cur = params.Do; sz_max_cur = params.sz_max_real; R_cur = params.R_real;
        case 'Di', Di_cur = scan_vec(i); Do_cur = params.Do; p_cur = params.p; sz_max_cur = params.sz_max_real; R_cur = params.R_real;
        case 'Do', Do_cur = scan_vec(i); Di_cur = params.Di; p_cur = params.p; sz_max_cur = params.sz_max_real; R_cur = params.R_real;
        case 'sz_max_real', sz_max_cur = scan_vec(i); p_cur = params.p; Di_cur = params.Di; Do_cur = params.Do; R_cur = params.R_real;
        case 'R_real', R_cur = scan_vec(i); p_cur = params.p; Di_cur = params.Di; Do_cur = params.Do; sz_max_cur = params.sz_max_real;
    end
    
    ri_cur = Di_cur/2; ro_cur = Do_cur/2;
    
    [sr, st, sz_static] = compute_static_stress(p_cur, ri_cur, ro_cur);
    
    sz_min_real = R_cur * sz_max_cur;
    
    % 反推试验机施加应力
    sz_app_max = sz_max_cur - sz_static;
    sz_app_min = sz_min_real - sz_static;
    
    sz_app_mean = (sz_app_max + sz_app_min)/2;
    sz_app_amp  = (sz_app_max - sz_app_min)/2;
    
    % 一个循环
    sz_app = sz_app_mean + sz_app_amp*sin(theta);
    sz = sz_static + sz_app;
    
    % 主应力
    s1 = st * ones(size(theta));
    s2 = sz;
    s3 = sr * ones(size(theta));
    
    % 等效应力
    sigma_v = sqrt(0.5*((s1-s2).^2 + (s2-s3).^2 + (s3-s1).^2));
    
    % 波形畸变系数 D
    sigma_v_zero_mean = sigma_v - mean(sigma_v);
    ft = fit(theta.', sigma_v_zero_mean.', 'sin1');
    sigma_fit = ft.a1 * sin(ft.b1*theta + ft.c1);
    residual = sigma_v_zero_mean - sigma_fit;
    D = rms(residual)/rms(sigma_v_zero_mean);
    
    % 保存结果
    sigma_v_max_vec(i)   = max(sigma_v);
    sigma_v_min_vec(i)   = min(sigma_v);
    sigma_app_max_vec(i) = sz_app_max;
    sigma_app_min_vec(i) = sz_app_min;
    D_vec(i)             = D;
end

%% ===== 绘图 =====
figure('Color','w','Position',[200 100 1200 600]);

% 统一字体设置函数
set_global_font = @(ax) set(ax,'FontName',plotParams.FontName,'FontSize',plotParams.FontSize);

% ===== 上图：峰谷应力 =====
subplot(2,1,1);
p1 = plot(scan_vec, sigma_v_max_vec,'r-o','LineWidth',plotParams.LineWidth,'MarkerSize',plotParams.MarkerSize); hold on;
p2 = plot(scan_vec, sigma_v_min_vec,'b-o','LineWidth',plotParams.LineWidth,'MarkerSize',plotParams.MarkerSize);
p3 = plot(scan_vec, sigma_app_max_vec,'r--s','LineWidth',plotParams.LineWidth,'MarkerSize',plotParams.MarkerSize);
p4 = plot(scan_vec, sigma_app_min_vec,'b--s','LineWidth',plotParams.LineWidth,'MarkerSize',plotParams.MarkerSize);

xlabel(scan_var_name,'FontName',plotParams.FontName,'FontSize',plotParams.FontSize);
ylabel('Stress (MPa)','FontName',plotParams.FontName,'FontSize',plotParams.FontSize);
legend([p1,p2,p3,p4],'\sigma_v^{max}','\sigma_v^{min}','\sigma_{app}^{max}','\sigma_{app}^{min}','Location','best','FontSize',plotParams.FontSize);
grid on; ax = gca; ax.GridAlpha = plotParams.GridAlpha; set_global_font(ax);

% ===== 下图：波形畸变 =====
subplot(2,1,2);
p5 = plot(scan_vec, D_vec,'k-o','LineWidth',plotParams.LineWidth,'MarkerSize',plotParams.MarkerSize);
xlabel(scan_var_name,'FontName',plotParams.FontName,'FontSize',plotParams.FontSize);
ylabel('Waveform distortion D','FontName',plotParams.FontName,'FontSize',plotParams.FontSize);
grid on; ax = gca; ax.GridAlpha = plotParams.GridAlpha; set_global_font(ax);

% ===== 全局美化 =====
set(findall(gcf,'Type','text'),'FontName',plotParams.FontName,'FontSize',plotParams.FontSize);
