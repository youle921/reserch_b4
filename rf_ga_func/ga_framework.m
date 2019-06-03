% function [acc, params] = ga_framework(seed, train_data, train_ans, test_data, test_ans, class, method)
function [rf_model, params] = ga_framework(seed, train_data, train_ans, test_data, test_ans, class, method)

params.tree_num = 200;
params.p_num = 50;
params.c_num = 50;
gen_num = 1000;
    
data.valid_data = [];
data.valid_ans = [];

if strcmp(method, 'validation')
    rng(seed)
%     cv = cvpartition(train_ans{:, 1}, 'KFold', 5);
%     data.valid_data = train_data(cv.test(1), :);
%     data.valid_ans = train_ans(cv.test(1), :);   
%     data.train_data = train_data(~cv.test(1), :);
%     data.train_ans = train_ans(~cv.test(1), :);
    
%     confirm program
    data.valid_data = test_data;
    data.valid_ans = test_ans;   
    data.train_data = train_data;
    data.train_ans = train_ans;
    
    evaluate_function = @validation_evaluation;
end

if strcmp(method, 'oob')
    evaluate_function = @oob_evaluation;
end

%% initialize ga

rng(seed);

rf_model = TreeBagger(params.tree_num, data.train_data, data.train_ans, 'OOBPrediction', 'on');
params.pop_list = logical(round(rand(params.p_num, params.tree_num)));
params.score = evaluate_function(rf_model, params.pop_list, data);

%% generate next gen
for gen = 1:gen_num
    [params.pop_list, params.score] = update_pop(params, rf_model, data, evaluate_function);
end

%% get return value
prd = rf_get_predict(rf_model, test_data, class, params.pop_list(1, :));
% acc = sum(prd(:, 1) == table2array(test_ans)) / height(test_ans);

end

function [pop_list, score] = update_pop(params, mdl, data, evaluate_method)

    children = get_children(params);

    c_score = evaluate_method(mdl, children, data);
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

    chosen_parent = diag(parent_id(:, winner)); %�z�񑀍삪�킩��Ȃ��̂ł����
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
function acc = validation_evaluation(mdl, id, data)

t_num = size(id, 1);
acc = zeros(t_num, 1);
[row, col] = find(id);
    
for i = 1:t_num
    acc(i) = error(mdl, data.valid_data, data.valid_ans, 'Mode', 'ensemble', 'Trees', col(row == i));
end

acc = 1 - acc;

end

function acc = oob_evaluation(mdl, id, ~)

t_num = size(id, 2);
acc = zeros(t_num, 1);
[row, col] = find(id);
    
for i = 1:t_num
    acc(i) = oobError(mdl, 'Mode', 'ensemble', 'Trees', col(row == i));
end

acc = 1 - acc;

end

