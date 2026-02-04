clc; clear; close all;

%% ===== 全局默认变量区（可直接改这里）=====
useChinese = false;          % 是否中文
globalFontSize = 16;        % 全局字号

fontEN = 'Times New Roman';
fontCN = 'SimHei';

p_default  = [4 20 90 150]; % 默认内压 MPa（可任意个）
Di_default = 2;            % 内径 mm
Do_default = 7;            % 外径 mm

%% ===== 展示默认参数 =====
disp('默认参数如下：');
disp(['内压 p (MPa): ', num2str(p_default)]);
disp(['内径 Di (mm): ', num2str(Di_default)]);
disp(['外径 Do (mm): ', num2str(Do_default)]);

modify = input('是否修改参数？(y/n): ','s');

if lower(modify) == 'y'
    nP = input('输入内压个数: ');
    p = zeros(1,nP);
    for i = 1:nP
        p(i) = input(['输入第 ',num2str(i),' 个内压 p (MPa): ']);
    end
    Di = input('输入内径 Di (mm): ');
    Do = input('输入外径 Do (mm): ');
else
    p  = p_default;
    Di = Di_default;
    Do = Do_default;
end

%% ===== 字体与标签 =====
if useChinese
    fontName = fontCN;
    xlabelText = '半径 r (mm)';
    ylabelText = '应力 \sigma (MPa)';
    legendStressTitle = '线型：应力类型';
    legendPressureTitle = '颜色：内压大小';
    stressNames = {'径向应力','环向应力','轴向应力'};
else
    fontName = fontEN;
    xlabelText = 'Radius r (mm)';
    ylabelText = 'Stress \sigma (MPa)';
    legendStressTitle = 'Line style: Stress type';
    legendPressureTitle = 'Color: Internal pressure';
    stressNames = {'Radial','Hoop','Axial'};
end

%% ===== 几何参数 =====
ri = Di/2;
ro = Do/2;
r = linspace(ri, ro, 500);

%% ===== 线型和颜色 =====
lineStyles = {'-','--',':'};   % 三种应力
colors = lines(length(p));     % 根据压力数量自动生成颜色

%% ===== 开始绘图 =====
figure('Color','w'); hold on;

hStress = gobjects(3,1);
hPressure = gobjects(length(p),1);

for i = 1:length(p)

    % ===== 拉梅常数 =====
    A = p(i) * ri^2 / (ro^2 - ri^2);
    B = p(i) * ri^2 * ro^2 / (ro^2 - ri^2);

    % ===== 应力计算 =====
    sigma_r     = A - B ./ (r.^2);
    sigma_theta = A + B ./ (r.^2);
    sigma_z     = A * ones(size(r));

    stressAll = {sigma_r, sigma_theta, sigma_z};

    for s = 1:3
        h = plot(r, stressAll{s}, ...
            'Color', colors(i,:), ...
            'LineStyle', lineStyles{s}, ...
            'LineWidth', 2);

        if i == 1
            hStress(s) = h;
        end
        if s == 1
            hPressure(i) = h;
        end
    end
end

%% ===== 坐标轴规范 =====
ax = gca;
ax.FontSize = globalFontSize;
ax.FontName = fontName;
ax.Box = 'on';
ax.LineWidth = 1.5;

xlabel(xlabelText);
ylabel(ylabelText);

%% ===== 双 Legend 终极稳定版 =====

pressureNames = strings(1,length(p));
for i = 1:length(p)
    pressureNames(i) = [num2str(p(i)),' MPa'];
end

ax1 = gca;

% ===== legend 1：线型（应力类型）=====
hStress(1) = plot(ax1, nan, nan, 'k-',  'LineWidth',2);
hStress(2) = plot(ax1, nan, nan, 'k--', 'LineWidth',2);
hStress(3) = plot(ax1, nan, nan, 'k:',  'LineWidth',2);

lgd1 = legend(ax1, hStress, stressNames, ...
    'Location','northeast', ...
    'FontSize',globalFontSize-1, ...
    'FontName',fontName);
title(lgd1, legendStressTitle);

% ===== 新建透明坐标轴（关键）=====
ax2 = axes('Position', ax1.Position, ...
           'Color','none', ...
           'XColor','none', ...
           'YColor','none');

% ===== legend 2：颜色（压力）=====
lgd2 = legend(ax2, hPressure, pressureNames, ...
    'Location','northeast', ...
    'FontSize',globalFontSize-1, ...
    'FontName',fontName);
title(lgd2, legendPressureTitle);

% ===== 手动上下排布 =====
lgd1.Position = [0.68 0.65 0.25 0.2];
lgd2.Position = [0.68 0.40 0.25 0.2];
