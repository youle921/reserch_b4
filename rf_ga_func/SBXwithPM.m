function Offspring = SBXwithPM(Parent1, Parent2, Parameter)
%copyed from https://github.com/BIMK/PlatEMO/blob/master/PlatEMO/Operators/GA.m 

%   Off = GA(P,{proC,disC,proM,disM}) specifies the parameters of
%   operators, where proC is the probabilities of doing crossover, disC is
%   the distribution index of simulated binary crossover, proM is the
%   expectation of number of bits doing mutation, and disM is the
%   distribution index of polynomial mutation.

    [proC,disC,proM,disM] = deal(1,20,1,20);

%     Parent1 = Parent(1:floor(end/2),:);
%     Parent2 = Parent(floor(end/2)+1:floor(end/2)*2,:);
    [N,D]   = size(Parent1);

    %% Simulated binary crossover
    beta = zeros(N,D);
    mu   = rand(N,D);
    beta(mu<=0.5) = (2*mu(mu<=0.5)).^(1/(disC+1));
    beta(mu>0.5)  = (2-2*mu(mu>0.5)).^(-1/(disC+1));
    beta = beta.*(-1).^randi([0,1],N,D);
    beta(rand(N,D)<0.5) = 1;
    beta(repmat(rand(N,1)>proC,1,D)) = 1;
    Offspring = [(Parent1+Parent2)/2+beta.*(Parent1-Parent2)/2
                 (Parent1+Parent2)/2-beta.*(Parent1-Parent2)/2];
             
    %% Polynomial mutation
%     Lower = repmat(Global.lower,2*N,1);
    Lower = repmat(zeros(size(Parent1, 2), 1).', 2 * N, 1);
%     Upper = repmat(Global.upper,2*N,1);
    Upper = repmat(ones(size(Parent1, 2), 1).', 2 * N, 1);
    Site  = rand(2*N,D) < proM/D;
    mu    = rand(2*N,D);
    temp  = Site & mu<=0.5;
    Offspring       = min(max(Offspring,Lower),Upper);
    Offspring(temp) = Offspring(temp)+(Upper(temp)-Lower(temp)).*((2.*mu(temp)+(1-2.*mu(temp)).*...
                      (1-(Offspring(temp)-Lower(temp))./(Upper(temp)-Lower(temp))).^(disM+1)).^(1/(disM+1))-1);
    temp = Site & mu>0.5; 
    Offspring(temp) = Offspring(temp)+(Upper(temp)-Lower(temp)).*(1-(2.*(1-mu(temp))+2.*(mu(temp)-0.5).*...
                      (1-(Upper(temp)-Offspring(temp))./(Upper(temp)-Lower(temp))).^(disM+1)).^(1/(disM+1)));
                  
    mask = rand(N, 1) <= 0.5;
    mask = [mask not(mask)];
    Offspring = Offspring(mask(:), :);
end