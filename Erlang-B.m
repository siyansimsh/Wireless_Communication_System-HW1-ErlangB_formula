% 函數：使用遞迴算法計算 Erlang-B 阻塞概率
function B = erlangB_blocking_probability(rho, m)
    % 確保輸入有效
    if m < 0 || fix(m) ~= m
        error('信道數量 m 必須為非負整數。');
    end
    if rho < 0
        error('業務負荷 rho 必須為非負數。');
    end

    % 初始化阻塞概率
    B = 1.0;
    for k = 1:m
        B = (rho * B) / (k + rho * B);
    end
end
%--------------------------------------------------------------
% 函數：根據給定的阻塞概率計算total traffic load rho
function rho = calculate_traffic_load(m, B_target)
    % 定義目標函數：阻塞概率差值
    fun = @(rho) erlangB_blocking_probability(rho, m) - B_target;
    % 初始搜索區間
    rho_min = eps; % 避免 rho 為 0
    rho_max = m * 5; % 根據經驗調整最大值，避免過大
    % 確保函數在區間端點的值是有限的實數
    f_min = fun(rho_min);
    f_max = fun(rho_max);
    if ~isfinite(f_min) || ~isreal(f_min) || ~isfinite(f_max) || ~isreal(f_max)
        error('函數在搜索區間的端點處的值不是有限的實數，無法使用 fzero。');
    end
    % 檢查函數值是否跨越零點
    if f_min * f_max > 0
        error('在給定的搜索區間內，函數值沒有跨越零點，無法找到根。請調整搜索區間。');
    end
    % 使用 fzero 求解
    options = optimset('Display', 'off');
    [rho, fval, exitflag] = fzero(fun, [rho_min, rho_max], options);
    % 檢查求解是否成功
    if exitflag ~= 1
        error('無法找到滿足條件的 rho，對於 m = %d 和 B = %.2f%%', m, B_target*100);
    end
end
%--------------------------------------------------------------
% 主程式
% 定義通道數量和阻塞概率
channels_small = 1:20;
channels_large = 200:220;
channels = [channels_small,channels_large];
blocking_rates = [0.01, 0.03, 0.05, 0.10];

% 預分配結果矩陣
results = [];

% 遍歷阻塞概率
for B_target = blocking_rates
    fprintf('阻塞概率：%.0f%%\n', B_target * 100);
    fprintf('通道數\t total traffic load (Erlang)\n');
    % 遍歷通道數量
    for m = channels
        try
            rho = calculate_traffic_load(m, B_target);
            fprintf('%d\t\t%.4f\n', m, rho);
            % 儲存結果
            results = [results; m, B_target, rho];
        catch ME
            fprintf('%d\t\t計算失敗: %s\n', m, ME.message);
            % 對於計算失敗的情況，可以繼續下一個 m
            continue;
        end
    end
    fprintf('\n');
end
%--------------------------------------------------------------
% 繪製結果圖形
% 將結果轉換為表格方便處理
results_table = array2table(results, 'VariableNames', {'Channels', 'BlockingRate', 'TrafficLoad'});

% 繪製圖形
blocking_labels = {'1%', '3%', '5%', '10%'};
for i = 1:length(blocking_rates)
    B_target = blocking_rates(i);
    idx = results(:,2) == B_target;
    m_values = results(idx, 1);
    rho_values = results(idx, 3);
    
    figure;
    plot(m_values, rho_values, '-o', 'LineWidth', 2);
    xlabel('channel number m');
    ylabel('total traffic load \rho (Erlang)');
    title(sprintf('阻塞概率 %.0f%% 下total traffic load與通道數量的關係', B_target * 100));
    grid on;
end
