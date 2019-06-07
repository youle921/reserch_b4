% function acc = ga_framework(seed, train_data, train_ans, test_data, test_ans, class, method)
function params = ga_framework(seed, train_data, train_ans, test_data, test_ans, class, method)

params.tree_num = 30;
params.p_num = 50;
params.c_num = 50;
gen_num = 10;

if strcmp(method, 'validation')
    rng(seed)
    cv = cvpartition(train_ans{:, 1}, 'KFold', 5);
    valid_data = train_data(cv.test(1), :);
    valid_ans = train_ans(cv.test(1), :);   
    train_data = train_data(~cv.test(1), :);
    train_ans = train_ans(~cv.test(1), :);
    
%     confirm program
%     valid_data = test_data;
%     valid_ans = test_ans;
    
end

%% initialize ga

rng(seed);

params.rf_model = TreeBagger(params.tree_num, train_data, train_ans, 'OOBPrediction', 'on');
params.pop_list = logical(round(rand(params.p_num, params.tree_num)));

% get predict array

if strcmp(method, 'validation')
    prd_array = zeros(height(valid_ans), length(class), params.tree_num);
    for t = 1 : params.tree_num
        [~, prd_array(:, :, t)] = predict(params.rf_model, valid_data);
    end
    
    score_ans = valid_ans;
end

if strcmp(method, 'oob')
    prd_array = zeros(height(train_ans), length(class), params.tree_num);
    for t = 1 : params.tree_num
        [~, prd_array(:, :, t)] = predict(params.rf_model, train_data);
        prd_array(params.rf_model.OOBIndices(:, t) , :, t) = 0;
    end
    score_ans = train_ans;
end

params.score = aggregate_function(params.pop_list, prd_array, score_ans, class);

%% generate next gen
for gen = 1:gen_num
    [params.pop_list, params.score] = update_pop(params, prd_array, score_ans, class);
end

%% get return value
% prd = rf_get_predict(params.rf_model, test_data, class, params.pop_list(1, :));
% acc = sum(prd(:, 1) == table2array(test_ans)) / height(test_ans);

end

function [pop_list, score] = update_pop(params, prd, answer, class)

    children = get_children(params);

    c_score = aggregate_function(children, prd, answer, class);
    c_score(ismember(children, params.pop_list, 'rows')) = 0;

    tmp_value = vertcat(params.score, c_score);
    tmp_pop = vertcat(params.pop_list, children);
    [~, id] = sort(tmp_value, 'descend');
    pop_list = tmp_pop(id(1 : params.p_num), :);
    score = tmp_value(id(1 : params.p_num));

end

%% GA functions
function children = get_children(params)

    crossover_rate = 0.9;
    crossover_rand = rand(params.c_num, 1);

    first_parent = get_parent(params);
    second_parent = get_parent(params);

    choose_id = logical(round(rand(params.c_num, params.tree_num)));
    children = second_parent;
    children(choose_id) = first_parent(choose_id);
    children(crossover_rand > crossover_rate) = first_parent(crossover_rand > crossover_rate);

    children = mutation(children);           

end

function parent = get_parent(params)

    parent_id = randi(params.p_num, params.c_num, 2);

    [~, winner] = max(params.score(parent_id), [], 2);
    [~, tmp] = max(fliplr(params.score(parent_id)), [], 2);
    cnt = sum(winner == tmp);
    winner(winner == tmp) = randi(2, cnt, 1);

    chosen_parent = diag(parent_id(:, winner)); %配列操作がわからないのでやっつけ
    parent = params.pop_list(chosen_parent, :);      

end

function new_population = mutation(population, mutation_ratio)

    if nargin < 2
        mutation_ratio = 2 / size(population, 2);
    end            

    new_population = population;
    mutation_index = rand(size(population)) < mutation_ratio;
    new_population(mutation_index) = ~population(mutation_index);

end   

%% evaluate functions
function acc = aggregate_function(id, prd, answer, class)

t_num = size(id, 1);
acc = zeros(t_num, 1);
    
for i = 1:t_num
    [~, prd_tmp] = max(sum(prd(:, :, id(i)), 3), [], 2);
    acc(i) = sum(class(prd_tmp, 1) == table2array(answer));
end

end




