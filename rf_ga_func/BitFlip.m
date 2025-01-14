function new_population = BitFlip(population, mutation_ratio)

    if nargin < 2
        mutation_ratio = 2 / size(population, 2);
    end
    
    if size(mutation_ratio, 1) ~= 1
        mutation_ratio = 2 / size(population, 2);
    end
    
    new_population = population;
    mutation_index = rand(size(population)) < mutation_ratio;
    new_population(mutation_index) = ~population(mutation_index);

end   