dirname = 'result_t250';
mkdir(dirname);

datalist = ["Vehicle" "Pima" "Vowel" "Heart" "Glass" "Satimage"];

for i = 1 : length(datalist)
    
    dataname = char(datalist(i));
    filename = ['..\dataset\' dataname '.csv']; 
    T = readtable(filename);
    data = T(:, 1:size(T, 2) - 1);
    answer = table2array(T(:, size(T, 2)));
    class = unique(answer);

    cv_num = 2;
    cv_div = 10;
    acc_list = zeros(cv_num * cv_div, 3);
    t_num_list = zeros(cv_num * cv_div, 1);
    
    method = 'oob';
    
    for cv_count = 1 : cv_num
        rng(cv_count)
        cv = cvpartition(answer, 'KFold', cv_div);
        acc_tmp = zeros(cv_div, 3);
        t_num_tmp = zeros(cv_div, 1);
        
        parfor cv_trial = 1 : cv_div

            train_data = data(~cv.test(cv_trial), :);
            test_data = data(cv.test(cv_trial), :);
            train_ans = answer(~cv.test(cv_trial), :);
            test_ans = answer(cv.test(cv_trial), :);   

            seed = (cv_count - 1) * 10 + cv_trial;

            [acc_tmp(cv_trial, :), t_num_tmp(cv_trial)] = rf_ga_framework(seed, train_data, train_ans, test_data, test_ans, class, method);

        end
        
        acc_list((cv_count - 1) * 10 + 1: cv_count * 10, :) = acc_tmp;
        t_num_list((cv_count - 1) * 10 + 1: cv_count * 10, :) = t_num_tmp;
    end
    
    csvwrite([dirname '\' method '_' dataname '.csv'], [acc_list t_num_list]);
    disp([dataname ' finished'])
end

disp(['----' method ' method result----'])
disp('first column is init')
disp('second column is best')
disp('third column is base')
disp('4th column is the num of trees')